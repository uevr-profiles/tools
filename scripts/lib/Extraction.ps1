#region Extraction & Discovery

function Extract-And-Discover-Profiles($archivePath) {
    Debug-Log "[common.ps1] Entering Extract-And-Discover-Profiles ($archivePath)"
    $discovered = @()
    $tempBase = Join-Path $BaseTempDir "discovery_$(Get-Random)"
    # Normalize tempBase to long path
    $tempBase = (New-Item -ItemType Directory -Path $tempBase -Force).FullName
    $Global:TempFolders += $tempBase
    
    try {
        $profileArchive = [ProfileArchive]::new($archivePath)
        $profileArchive.ExtractTo($tempBase)
        
        # Flatten-Folder will collapse single-folder wrappers (e.g. Zip/ExeName/config.txt -> Zip/config.txt)
        Flatten-Folder $tempBase
        # Profile discovery: any folder with ProfileMeta.json or known patterns
        # We limit depth to 3 and skip folders like "sdkdump" that can contain thousands of files.
        $searchBlacklist = @("sdkdump", "Source", "Intermediate", "Binaries", "Saved")
        $candidateDirs = Get-ChildItem -Path $tempBase -Directory -Recurse -Depth 3 | Where-Object { 
            if ($searchBlacklist -contains $_.Name) { return $false }
            Is-ProfileFolder $_.FullName
        }
        
        # If no internal folders match, check the root
        if ($candidateDirs.Count -eq 0) {
            if (Is-ProfileFolder $tempBase) {
                $candidateDirs = @(Get-Item $tempBase)
            }
        }
        
        foreach ($dir in $candidateDirs) {
            # Normalize dir path to long path
            $dirPath = (Get-Item $dir.FullName).FullName
            $rel = [IO.Path]::GetRelativePath($tempBase, $dirPath)
            if ($rel -eq ".") { $rel = "" }
            if ($rel) {
                $relName = $rel
            } else {
                $relName = "[Root]"
            }
            $discovered += [PSCustomObject]@{ Path = $dirPath; Profile = $relName; ProfileName = $dir.Name }
        }
    } catch {
        Write-Warning "Discovery failed for ${archivePath}: $($_.Exception.Message)"
    }
    
    return $discovered
}

function Extract-Archives($archivePaths, [switch]$Silent) {
    Debug-Log "[common.ps1] Entering Extract-Archives"
    if (-not $archivePaths) { 
        Debug-Log "[common.ps1] No archive paths provided"
        return 
    }
    $results = @()
    foreach ($archivePath in $archivePaths) {
        $archive = Get-Item $archivePath
        Debug-Log "[common.ps1] Processing archive $($archive.Name)"
        Write-Host "Processing archive: $($archive.Name)..." -ForegroundColor Cyan
        
        $sidecarPath = $archive.FullName + ".json"
        if (-not (Test-Path $sidecarPath)) { 
            $sidecarPath = [IO.Path]::ChangeExtension($archive.FullName, ".json") 
        }
        
        $sidecar = $null
        if (Test-Path $sidecarPath) {
            Debug-Log "[common.ps1] Found sidecar: $sidecarPath"
            $sidecar = Get-Content $sidecarPath -Raw | ConvertFrom-Json
        }
        
        Debug-Log "[common.ps1] Discovering profiles in archive"
        $discovered = Extract-And-Discover-Profiles $archive.FullName
        Write-Host "  Found $($discovered.Count) profiles within archive." -ForegroundColor Gray
        
        foreach ($p in $discovered) {
            try {
                Debug-Log "[common.ps1] Processing discovered profile: $($p.Profile)"
                $internalPath = Join-Path $p.Path "ProfileMeta.json"
                
                $internal = $null
                if (Test-Path $internalPath) {
                    $internal = Get-Content $internalPath -Raw | ConvertFrom-Json
                }
                
                $merged = [ordered]@{}
                if ($internal) { foreach ($prop in $internal.PSObject.Properties) { $merged[$prop.Name] = $prop.Value } }
                if ($sidecar) { foreach ($prop in $sidecar.PSObject.Properties) { $merged[$prop.Name] = $prop.Value } }
                
                Debug-Log "[common.ps1] Generating metadata"
                if (-not $merged.zipHash) { $merged.zipHash = Get-FileHashMD5 $archive.FullName }
                if (-not $merged.ID) { $merged.ID = Get-ExtractionUUID $merged.zipHash }
                if (-not $merged.downloadDate) { $merged.downloadDate = Get-ISO8601Now }

                $finalMeta = [ProfileMetadata]::FromObject($merged)
                $targetDir = Join-Path $ProfilesDir $finalMeta.ID
                if ($p.Profile -and $p.Profile -ne "[Root]") { 
                    $targetDir = Join-Path $targetDir ($p.Profile -replace ' / ', '\') 
                }
                
                Debug-Log "[common.ps1] Moving profile to target: $targetDir"
                Move-Item-Smart $p.Path $targetDir
                
                $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                if ($finalMeta.tags) { foreach ($t in $finalMeta.tags) { $tagSet.Add($t) | Out-Null } }
                $hTags = Get-HeuristicTags $targetDir $finalMeta $p.Profile
                if ($hTags) { foreach ($t in $hTags) { $tagSet.Add($t) | Out-Null } }
                if ($tagSet.Count -gt 0) { $finalMeta.tags = @($tagSet | Sort-Object) }
                
                Debug-Log "[common.ps1] Saving finalized metadata"
                $finalMeta.Save($targetDir, $archive.FullName, $p.Profile)
                
                if (-not $Silent) { 
                    Print-ProfileInfo $finalMeta $archive.FullName $p.Profile 
                }
                $results += $finalMeta
            } catch { Write-Host "  [!] Failed to process profile in $($archive.Name): $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
    return $results
}

function Extract-ArchivesFolder($folderPath, [int]$Limit = [int]::MaxValue, [switch]$Silent) {
    Debug-Log "[common.ps1] Entering Extract-ArchivesFolder: $folderPath (Limit: $Limit)"
    if (-not (Test-Path $folderPath)) { 
        Debug-Log "[common.ps1] Folder not found: $folderPath"
        return 
    }
    $exts = Get-SupportedArchiveExtensions
    Debug-Log "[common.ps1] Searching for archives with extensions: $($exts -join ', ')"
    $archives = Get-ChildItem -Path $folderPath -File | Where-Object { $exts -contains $_.Extension }
    
    if ($Limit -lt $archives.Count) {
        Debug-Log "[common.ps1] Limiting extraction to $Limit newest files"
        $archives = $archives | Sort-Object LastWriteTime -Descending | Select-Object -First $Limit
    }
    
    Debug-Log "[common.ps1] Found $($archives.Count) archives to extract"
    return Extract-Archives $archives.FullName -Silent:$Silent
}
#endregion
