# ── Common Configuration & Functions ──────────────────────────────────────────

function Get-ProfileDownloadUrl($profileId, $exeName) {
    if ($null -eq $exeName) { $exeName = $profileId }
    $cleanName = $exeName -replace '[^a-zA-Z0-9]', '_'
    # Target URL for the folder downloader pointing to the profile folder in the repo
    $repoUrl = "https://github.com/uevr-profiles/repo/tree/main/profiles/$($profileId)"
    $encodedUrl = [uri]::EscapeDataString($repoUrl)
    return "https://gitfolderdownloader.github.io/?url=$($encodedUrl)&name=$($cleanName)"
}

$RepoRoot    = Split-Path $PSScriptRoot -Parent
$ProfilesDir = Join-Path $RepoRoot "profiles"
$SchemaFile  = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"

function Format-ISO8601Date($date) {
    if ($null -eq $date -or "$date" -eq "") { return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") }
    try {
        $dt = [DateTime]::Parse($date, [System.Globalization.CultureInfo]::InvariantCulture)
        return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } catch {
        try {
            $dt = [DateTime]::Parse($date)
            return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        } catch {
            return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
}

# Global tracking for diagnostics
$BaseTempDir     = Join-Path $env:TEMP "uevr_profiles"
$GlobalFilesList = Join-Path $BaseTempDir "files.txt"
$GlobalPropsJson = Join-Path $BaseTempDir "props.json"

# Initialize global memory storage
$Global:TrackingFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$Global:TrackingProps = [ordered]@{}

function Update-GlobalFilesList($relPaths) {
    if ($null -eq $relPaths) { return }
    foreach ($p in $relPaths) {
        $Global:TrackingFiles.Add($p) | Out-Null
    }
}

function Update-GlobalPropsJson($zipPath, $variant, $metaObj) {
    if ($null -eq $metaObj) { return }
    
    $occId = if ($variant -and $variant -ne "[Root]") { "$zipPath | $variant" } else { "$zipPath" }
    # Unique sub-key for this specific iteration
    $occKey = "$occId | $([DateTimeOffset]::Now.ToUnixTimeMilliseconds())_$(Get-Random)"

    foreach ($name in $metaObj.PSObject.Properties.Name) {
        $val = $metaObj.$name
        if (-not $Global:TrackingProps.PSObject.Properties[$name]) {
            Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $name -Value @{}
        }
        $targetBucket = $Global:TrackingProps.$name
        $targetBucket[$occKey] = $val
    }
}

function Move-Item-Smart($source, $destination) {
    if (-not (Test-Path $source)) { return }
    if (-not (Test-Path $destination)) { 
        New-Item -ItemType Directory -Path $destination -Force | Out-Null 
    }
    
    Get-ChildItem -Path $source | ForEach-Object {
        $destPath = Join-Path $destination $_.Name
        if ($_.PSIsContainer) {
            # Recurse if destination already has a directory by this name
            if (Test-Path $destPath -PathType Container) {
                Move-Item-Smart $_.FullName $destPath
            } else {
                Move-Item -Path $_.FullName -Destination $destPath -Force
            }
        } else {
            Move-Item -Path $_.FullName -Destination $destPath -Force
        }
    }
    # Cleanup empty source
    if (Test-Path $source) {
        $rem = Get-ChildItem -Path $source -Recurse -ErrorAction SilentlyContinue
        if ($null -eq $rem -or $rem.Count -eq 0) {
            Remove-Item $source -Force -ErrorAction SilentlyContinue
        }
    }
}

function Finalize-GlobalTracking {
    if (-not (Test-Path $BaseTempDir)) { New-Item -ItemType Directory -Path $BaseTempDir -Force | Out-Null }

    # 1. Write unique files list
    if ($Global:TrackingFiles.Count -gt 0) {
        Write-Host "Flushing tracked files to disk ($($Global:TrackingFiles.Count))..." -ForegroundColor Cyan
        $existing = if (Test-Path $GlobalFilesList) { Get-Content $GlobalFilesList -ErrorAction SilentlyContinue } else { @() }
        foreach ($e in $existing) { $Global:TrackingFiles.Add($e) | Out-Null }
        $sorted = $Global:TrackingFiles | Sort-Object
        $sorted | Set-Content $GlobalFilesList -Encoding utf8
    }

    # 2. Write props JSON
    if ($Global:TrackingProps.PSObject.Properties.Count -gt 0) {
        Write-Host "Flushing tracked properties to disk..." -ForegroundColor Cyan
        $existing = if (Test-Path $GlobalPropsJson) { 
            try { Get-Content $GlobalPropsJson -Raw | ConvertFrom-Json } catch { [ordered]@{} }
        } else { [ordered]@{} }
        
        # Merge existing into current
        foreach ($p in $existing.PSObject.Properties) {
            $name = $p.Name
            if (-not $Global:TrackingProps.PSObject.Properties[$name]) {
                Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $name -Value $p.Value
            } else {
                # Merge sub-properties
                foreach ($sub in $p.Value.PSObject.Properties) {
                    if (-not $Global:TrackingProps.$name.PSObject.Properties[$sub.Name]) {
                        Add-Member -InputObject $Global:TrackingProps.$name -MemberType NoteProperty -Name $sub.Name -Value $sub.Value
                    }
                }
            }
        }
        $Global:TrackingProps | ConvertTo-Json -Depth 10 | Set-Content $GlobalPropsJson -Encoding utf8
    }
}

function Get-HeuristicTags($profileDir, $meta, $variant) {
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    
    # 0. Technical Signals (Strongest)
    $hasMC = $false
    $hasUObject = $false
    if (Test-Path $profileDir) {
        $uDir = Join-Path $profileDir "uobjecthook"
        if (Test-Path $uDir) {
            $hasUObject = $true
            if (Get-ChildItem -Path $uDir -Filter "*_mc_state.json" -Recurse) { $hasMC = $true }
        }
    }

    if ($hasMC) {
        $tagSet.Add("6DOF") | Out-Null
        $tagSet.Add("Motion Controls") | Out-Null
    } elseif ($hasUObject) {
        $tagSet.Add("3DOF") | Out-Null
    }

    # 1. Textual Analysis (Metadata & Files)
    $textSources = @()
    if ($meta.remarks) { $textSources += $meta.remarks }
    if ($meta.gameName) { $textSources += $meta.gameName }
    if ($variant) { $textSources += $variant }
    
    # Gather content from top-level non-binary files
    if (Test-Path $profileDir) {
        $files = Get-ChildItem -Path $profileDir -File | Where-Object { $_.Extension -match "txt|md|json|lua" }
        foreach ($f in $files) {
            try {
                $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) { $textSources += $content }
            } catch {}
        }
    }

    $allText = $textSources -join "`n"
    
    # Keyword Detection
    $foundMotion = $allText -match "motion\s+controls"
    $found6DOF   = $allText -match "6\s*dof"
    $found3DOF   = $allText -match "3\s*dof"

    # Contextual Filtering: If variant explicitly identifies as one mode, be skeptical of the other in text
    $is3DOFVariant = $variant -match "3\s*dof"
    $is6DOFVariant = $variant -match "6\s*dof"

    if ($foundMotion) {
        if (-not $is3DOFVariant -or $variant -match "motion") { $tagSet.Add("Motion Controls") | Out-Null }
    }
    if ($found6DOF) {
        if (-not $is3DOFVariant) { $tagSet.Add("6DOF") | Out-Null }
    }
    if ($found3DOF) {
        if (-not $is6DOFVariant) { $tagSet.Add("3DOF") | Out-Null }
    }

    # Final Conflict Strip: If we are certain this is a 3DOF variant, remove any 6DOF tags that bled in
    $finalTags = [System.Collections.Generic.List[string]]::new($tagSet)
    if ($is3DOFVariant) {
        for ($i = $finalTags.Count - 1; $i -ge 0; $i--) {
            if ($finalTags[$i] -match "6\s*dof") { $finalTags.RemoveAt($i) }
        }
    }
    if ($is6DOFVariant) {
        for ($i = $finalTags.Count - 1; $i -ge 0; $i--) {
            if ($finalTags[$i] -match "3\s*dof") { $finalTags.RemoveAt($i) }
        }
    }

    return [string[]]($finalTags | Sort-Object | Select-Object -Unique)
}

# Ensure essential directories exist
if (-not (Test-Path $ProfilesDir)) { New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null }

# ── Whitelist Pattern Definitions ────────────────────────────────────────────
function Get-WhitelistPatterns {
    return @(
        "^README\.md$",
        "^ProfileMeta\.json$",
        "^_interaction_profiles_oculus_touch_controller\.json$",
        "^actions\.json$",
        "^binding_rift\.json$",
        "^binding_vive\.json$",
        "^bindings_knuckles\.json$",
        "^bindings_oculus_touch\.json$",
        "^bindings_vive_controller\.json$",
        "^cameras\.txt$",
        "^config\.txt$",
        "^cvars_data\.txt$",
        "^cvars_standard\.txt$",
        "^uevr_nightly_build\.txt$",
        "^user_script\.txt$",
        "^scripts/.*\.lua$",
        "^plugins/.*\.(dll|so)$",
        "^uobjecthook/.*\.json$",
        "^(_EXTRAS|data|libs|paks)/.+"
    )
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    $patterns = Get-WhitelistPatterns
    foreach ($p in $patterns) {
        if ($rel -match $p) { return $true }
    }
    return $false
}

function Is-ProfileFolder($path) {
    if (-not (Test-Path $path)) { return $false }
    $essentials = @("config.txt", "ProfileMeta.json")
    $files = Get-ChildItem -Path $path -File
    foreach ($f in $files) {
        if ($essentials -contains $f.Name) { return $true }
        if ($f.Name -match "^bindings?_.*\.json$") { return $true }
        if ($f.Name -match "^_interaction_profiles_.*\.json$") { return $true }
    }
    return $false
}

function Get-BlacklistPatterns {
    return @(
        "^sdkdump/.*\.(cpp|hpp)$",
        "^plugins/.*\.pdb$",
        "\.bak$",
        "\.org$",
        "^cvardump\.json$"
    )
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    $patterns = Get-BlacklistPatterns
    foreach ($p in $patterns) {
        if ($rel -match $p) { return $true }
    }
    return $false
}

function Flatten-Folder($targetDir) {
    $items = Get-ChildItem -Path $targetDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $subDir = $items[0].FullName
        Write-Host "    Found single root directory, flattening: $($items[0].Name)" -ForegroundColor Gray
        Get-ChildItem -Path $subDir | Move-Item -Destination $targetDir -Force
        Remove-Item $subDir -Force
    }
}

function Get-Archive-Entries($path) {
    # Try generic 7z listing first as it handles almost everything
    $out = & 7z l $path -y 2>$null
    if ($LASTEXITCODE -eq 0) {
        # 7zip 'l' output typical line: "2024-03-12 16:35:46 ....        11116         7407  folder/file.txt"
        # We skip lines until we see the "----" separator or match the date pattern
        $names = @()
        $capture = $false
        foreach ($line in $out) {
            if ($line -match "^-+\s+-+") { $capture = $true; continue }
            if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[D.][R.][H.][S.][A.]\s+\d+\s+\d+\s+(.*)$") {
                $names += $matches[1].Trim()
            }
        }
        if ($names.Count -gt 0) { return $names }
    }
    
    # Fallback to .NET for ZIPs if 7z fails or missing
    if ($path.EndsWith(".zip")) {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
            $names = $zip.Entries.FullName
            $zip.Dispose()
            return $names
        } catch { return @() }
    }
    return @()
}

function Expand-Archive-Smart($path, $destination) {
    if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
    # Try 7z first - suppress all output to handle errors internally
    & 7z x $path "-o$destination" -y >$null 2>$null
    if ($LASTEXITCODE -ne 0 -and $path.EndsWith(".zip")) {
        try {
            Expand-Archive -Path $path -DestinationPath $destination -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "    [!] Failed to extract $path with both 7z and Expand-Archive."
        }
    }
}

function Extract-And-Discover-Profiles($sourceArchive, $whitelist, $blacklist, $maxDepth = 5) {
    if ($maxDepth -le 0) { return @() }
    
    # Create temp base and ensure we have the full, long path to avoid string mapping issues
    $tempBaseDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "uevr_extract_$(New-Guid)") -Force
    $tempBase = $tempBaseDir.FullName
    
    try {
        Expand-Archive-Smart $sourceArchive $tempBase
    } catch {
        Write-Error "    [!] Fatal error during extraction of $sourceArchive"
        Remove-Item $tempBase -Recurse -Force -ErrorAction SilentlyContinue
        return @()
    }
    
    $profilesFound = @()
    
    # 1. Look for nested archives
    $archives = Get-ChildItem -Path $tempBase -Recurse -Include "*.zip", "*.7z", "*.rar", "*.tar", "*.gz", "*.bz2", "*.xz"
    foreach ($a in $archives) {
        $subContext = $a.FullName.Substring($tempBase.Length).TrimStart('\').Replace('\', ' / ').Replace('.zip', '')
        $subProfiles = Extract-And-Discover-Profiles $a.FullName $whitelist $blacklist ($maxDepth - 1)
        foreach ($sp in $subProfiles) {
            # Update variant to include sub-archive context
            if ($sp.Variant -and $sp.Variant -ne "[Root]") {
                $sp.Variant = "$subContext / $($sp.Variant)"
            } else {
                $sp.Variant = $subContext
            }
            # Also update ProfileName if it was null/empty (meaning it was root in sub-archive)
            if (-not $sp.ProfileName) {
                $sp.ProfileName = $subContext.Split('/')[-1].Trim()
            }
            $profilesFound += $sp
        }
        Remove-Item $a.FullName -Force
    }

    # 2. Look for profile folders
    $candidateDirs = Get-ChildItem -Path $tempBase -Recurse -Directory | Where-Object { Is-ProfileFolder $_.FullName }
    if (Is-ProfileFolder $tempBase) { $candidateDirs += Get-Item $tempBase }

    $sortedCandidates = $candidateDirs | Sort-Object { $_.FullName.Length }
    Write-Host "    Found $($sortedCandidates.Count) candidate profile roots..." -ForegroundColor Gray
    
    $uniqueProfiles = @()
    foreach ($f in $sortedCandidates) {
        $alreadyFound = $false
        foreach ($found in $uniqueProfiles) {
            if ($f.FullName.StartsWith($found.FullName + "\")) { $alreadyFound = $true; break }
        }
        if (-not $alreadyFound) { $uniqueProfiles += $f }
    }

    foreach ($folderItem in $uniqueProfiles) {
        $folderPath = $folderItem.FullName
        $rel = $folderPath.Substring($tempBase.Length).TrimStart('\')
        $variant = if ($rel) { $rel.Replace('\', ' / ') } else { "[Root]" }
        
        $targetDir = Join-Path $env:TEMP "uevr_profile_tmp_$(New-Guid)"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        
        # Determine ProfileName (folder name)
        $pName = if ($rel) { $folderItem.Name } else { "" }

        # Smart Copy: Only filter if switches are active
        $allFiles = Get-ChildItem -Path $folderPath -Recurse -File
        foreach ($f in $allFiles) {
            $fRel = $f.FullName.Substring($folderPath.Length).TrimStart('\')
            
            $isWhitelisted = if ($whitelist) { Test-Whitelisted $fRel } else { $true }
            $isBlacklisted = if ($blacklist) { Test-Blacklisted $fRel } else { $false }

            if ($isWhitelisted -and -not $isBlacklisted) {
                $fTarget = Join-Path $targetDir $fRel
                $fParent = Split-Path $fTarget -Parent
                if (-not (Test-Path $fParent)) { New-Item -ItemType Directory -Path $fParent -Force | Out-Null }
                Copy-Item $f.FullName -Destination $fTarget -Force
            } else {
                Write-Host "    Filtered: $fRel (WH:$isWhitelisted, BL:$isBlacklisted)" -ForegroundColor DarkRed
            }
        }
        
        if ((Get-ChildItem $targetDir).Count -gt 0) {
            $profilesFound += [PSCustomObject]@{ Path = $targetDir; Variant = $variant; ProfileName = $pName }
        } else {
            Remove-Item $targetDir -Recurse -Force
        }
    }
    
    Remove-Item $tempBase -Recurse -Force -ErrorAction SilentlyContinue
    return $profilesFound
}

function Get-OrCreateUUID($originalId) {
    if ($originalId -and ($originalId -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$")) {
        try {
            return ([guid]$originalId).ToString()
        } catch {}
    }
    return [guid]::NewGuid().ToString()
}

function Finalize-ProfileMetadata($targetDir, $meta, $profileName) {
    $readmeFile = Join-Path $targetDir "README.md"
    $legacyDesc = Join-Path $targetDir "ProfileDescription.md"
    $readmeText = if (Test-Path $readmeFile) { Get-Content $readmeFile -Raw } else { "" }
    
    # 0. Set simple fields
    $meta["profileName"] = if ($profileName -and $profileName -ne "[Root]") { $profileName } else { $null }

    # 1. Look for description in README or sidecar
    $rawDesc = $null
    if ($readmeText) { $rawDesc = $readmeText }
    elseif (Test-Path $legacyDesc) { $rawDesc = Get-Content $legacyDesc -Raw }
    if ($rawDesc) {
        $meta["description"] = Convert-MarkdownToText $rawDesc 100
    }
    if (Test-Path $legacyDesc) { Remove-Item $legacyDesc -Force }
    return $meta
}

function Print-ProfileInfo($meta, $zipPath) {
    Write-Host "  - Profile $($meta.ID)" -ForegroundColor Cyan
    Write-Host "    - Game:       $($meta.gameName) ($($meta.exeName))" -ForegroundColor Gray
    Write-Host "    - Author:     $($meta.authorName)" -ForegroundColor Gray
    Write-Host "    - Source:     $($meta.sourceName) ($($meta.sourceUrl))" -ForegroundColor Gray
    Write-Host "    - ZIP:        $(if ($zipPath) { Split-Path $zipPath -Leaf } else { 'N/A' })" -ForegroundColor Gray
    Write-Host "    - Hash:       $($meta.zipHash)" -ForegroundColor Gray
    Write-Host "    - URL:        $($meta.sourceDownloadUrl)" -ForegroundColor Gray
    
    if ($zipPath -and (Test-Path $zipPath)) {
        Write-Host "  - ZIP Content List:" -ForegroundColor Cyan
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
            $zip.Entries | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor DarkGray }
            $zip.Dispose()
        } catch {
            Write-Host "    [!] Failed to list ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - [!] ZIP file not found at $zipPath" -ForegroundColor Red
    }
}

function Get-FileHashMD5($path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Path $path -Algorithm MD5).Hash.ToLower()
}

function Test-Metadata($json, $path) {
    if (-not (Test-Path $SchemaFile)) { return $true }
    # Silently validate, only report errors if we have them
    $res = Test-Json -Json $json -SchemaFile $SchemaFile -ErrorAction SilentlyContinue
    if (-not $res) {
        Write-Warning "    [!] Metadata validation failed for $(Split-Path $path -Parent | Split-Path -Leaf)"
    }
    return $res
}

function Remove-NullProperties($obj) {
    if ($null -eq $obj) { return $null }
    $newObj = [ordered]@{}
    
    $names = if ($obj -is [System.Collections.IDictionary]) { $obj.Keys } else { $obj.PSObject.Properties.Name }

    foreach ($name in $names) {
        $val = if ($obj -is [System.Collections.IDictionary]) { $obj[$name] } else { $obj.$name }
        if ($null -ne $val -and "$val" -ne "") {
            $newObj[$name] = $val
        }
    }
    return [PSCustomObject]$newObj
}

function Get-CleanVariantName($variant, $currentExe) {
    if (-not $variant) { return $null }
    $segments = $variant.Split(@(" / "), [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    $validSegments = @()
    foreach ($s in $segments) {
        if ($s -ieq "Root") { continue }
        $cleanS = $s.Replace("-Win64-Shipping", "").Replace("-Win64-DebugGame", "").Replace(".zip", "").Trim()
        $cleanE = if ($currentExe) { $currentExe.Replace("-Win64-Shipping", "").Replace("-Win64-DebugGame", "").Trim() } else { "" }
        if ($cleanE -and $cleanS -ieq $cleanE) { continue }
        if ($s -match "-Win64-(Shipping|DebugGame|Development|Test)$") { continue }
        $validSegments += $s
    }
    if ($validSegments.Count -eq 0) { return $null }
    return $validSegments -join " / "
}

function Convert-MarkdownToText($md, $maxLen = 100) {
    if ($null -eq $md) { return "" }
    $txt = $md -replace '(?m)^#+\s+', ''
    $txt = $txt -replace '\*\*|__', ''
    $txt = $txt -replace '\*|_', ''
    $txt = $txt -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    $txt = $txt -replace '`', ''
    $txt = $txt -replace '(?m)^\s*>\s+', ''
    $txt = $txt -replace '(?m)^\s*[-*+]\s+', ''
    $txt = $txt -replace '\r?\n', ' '
    $txt = $txt.Trim()
    if ($txt.Length -gt $maxLen) {
        return $txt.Substring(0, $maxLen - 3) + "..."
    }
    return $txt
}
