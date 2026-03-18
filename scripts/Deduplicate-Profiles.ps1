#region Parameters
param(
    [string]$Hash = "{zipHash}",
    [switch]$RawHash,
    [switch]$Delete,
    [switch]$Silent,
    [switch]$Debug
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$Global:Debug = $Debug
if (-not $Silent) {
    Write-Host "── UEVR Profile Deduplicator ──────────────────────────────────────────" -ForegroundColor Cyan
}

if (-not (Test-Path $ProfilesDir)) {
    Write-Error "Profiles directory not found at $ProfilesDir"
    exit
}

$profileFolders = Get-ChildItem -Path $ProfilesDir -Directory
$groups = @{}
$metaCache = @{}
#endregion

#region Functions
function Get-RawProfileHash($profilePath) {
    $tempZip = Join-Path $env:TEMP "uevr_dedupe_$([Guid]::NewGuid().Guid).zip"
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        
        $sourceFiles = Get-ChildItem -Path $profilePath -Recurse | Where-Object { 
            -not $_.PSIsContainer -and 
            $_.Name -ne "ProfileMeta.json" -and 
            $_.Name -ne "README.md"
        }

        if (-not $sourceFiles) { return "EMPTY_PROFILE" }

        Compress-Files -FilePaths $sourceFiles.FullName -TargetArchive $tempZip -CompressionLevel 1 -BaseDir $profilePath
        
        $hashVal = Get-FileHashMD5 $tempZip
        if ($null -eq $hashVal) { return "HASH_FAILED" }
        # Debug-Log "[Deduplicate-Profiles.ps1] RawHash for ${profilePath}: $hashVal"
        return $hashVal
    } catch {
        Write-Warning "RawHash failed for folder ${profilePath}: $($_.Exception.Message)"
        return "ERROR_$($_.Exception.GetType().Name)"
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    }
}
#endregion

#region Main Logic
Debug-Log "[Deduplicate-Profiles.ps1] Main Logic Start"
if (-not $Silent) {
    Write-Host "Scanning $($profileFolders.Count) profiles..." -ForegroundColor Gray
}

Debug-Log "[Deduplicate-Profiles.ps1] Profiling $($profileFolders.Count) folders"
foreach ($folder in $profileFolders) {
    Debug-Log "[Deduplicate-Profiles.ps1] Processing folder: $($folder.FullName)"
    $metaFile = Join-Path $folder.FullName "ProfileMeta.json"
    if (-not (Test-Path $metaFile)) { 
        Debug-Log "[Deduplicate-Profiles.ps1] No meta file found in $($folder.Name)"
        continue 
    }

    try {
        $metaObj = Get-Content $metaFile -Raw | ConvertFrom-Json
        $metaCache[$folder.FullName] = $metaObj

        $calculatedHash = ""
        if ($RawHash) {
            Debug-Log "[Deduplicate-Profiles.ps1] Generating RawHash"
            $calculatedHash = Get-RawProfileHash $folder.FullName
        } else {
            # Evaluate format string
            Debug-Log "[Deduplicate-Profiles.ps1] Generating Formatted Hash: $Hash"
            $calculatedHash = $Hash
            $matches = [regex]::Matches($Hash, '\{([^}]+)\}')
            foreach ($match in $matches) {
                $propName = $match.Groups[1].Value
                $val = "NULL"
                if ($metaObj.PSObject.Properties[$propName]) {
                    $val = $metaObj.$propName
                }
                $calculatedHash = $calculatedHash.Replace("{$propName}", $val)
            }
        }
        Debug-Log "[Deduplicate-Profiles.ps1] Calculated Hash: $calculatedHash"

        if (-not $groups.ContainsKey($calculatedHash)) {
            $groups[$calculatedHash] = [System.Collections.Generic.List[string]]::new()
        }
        $groups[$calculatedHash].Add($folder.FullName)
    } catch {
        Write-Warning "Failed to process profile at $($folder.FullName): $($_.Exception.Message)"
    }
}

$duplicateGroups = $groups.Keys | Where-Object { $groups[$_].Count -gt 1 }
Debug-Log "[Deduplicate-Profiles.ps1] Found $($duplicateGroups.Count) duplicate groups"

if ($duplicateGroups.Count -eq 0) {
    if (-not $Silent) {
        Write-Host "No duplicates found." -ForegroundColor Green
    }
    Debug-Log "[Deduplicate-Profiles.ps1] Main Logic End (No Duplicates)"
    exit
}

Write-Host "Found $($duplicateGroups.Count) groups of duplicates!" -ForegroundColor Yellow

foreach ($hashVal in $duplicateGroups) {
    $paths = $groups[$hashVal]
    Debug-Log "[Deduplicate-Profiles.ps1] Processing group: $hashVal ($($paths.Count) paths)"
    Write-Host "`nGroup: $hashVal" -ForegroundColor Cyan
    
    $keep = $paths[0]
    $toDelete = $paths | Select-Object -Skip 1

    foreach ($p in $paths) {
        if (-not $metaCache.ContainsKey($p)) { continue }
        $m = $metaCache[$p]
        $isKeep = ($p -eq $keep)
        $prefix = "[DUPE]"
        $color = "Yellow"
        if ($isKeep) {
            $prefix = "[KEEP]"
            $color = "Green"
        }
        
        Write-Host "  $prefix $($m.gameName) ($($m.ID))" -ForegroundColor $color
        Write-Host "         Author: $($m.authorName) | Source: $($m.sourceName)" -ForegroundColor Gray
        Write-Host "         Path:   $p" -ForegroundColor DarkGray
    }

    if ($Delete) {
        Debug-Log "[Deduplicate-Profiles.ps1] Deleting duplicates"
        foreach ($p in $toDelete) {
            Write-Host "  Deleting $p..." -ForegroundColor Red
            Remove-Item $p -Recurse -Force
        }
    }
}

if (-not $Delete -and -not $Silent) {
    Write-Host "`nRun with -Delete to automatically cleanup duplicates." -ForegroundColor Gray
}
Debug-Log "[Deduplicate-Profiles.ps1] Main Logic End"
#endregion
