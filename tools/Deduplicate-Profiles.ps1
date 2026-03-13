param(
    [string]$Hash = "{zipHash}",
    [switch]$RawHash,
    [switch]$Delete,
    [switch]$Silent
)

if (-not $Silent) {
    Write-Host "── UEVR Profile Deduplicator ──────────────────────────────────────────" -ForegroundColor Cyan
}

. "$PSScriptRoot\common.ps1"

if (-not (Test-Path $ProfilesDir)) {
    Write-Error "Profiles directory not found at $ProfilesDir"
    exit
}

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

        $zip = [System.IO.Compression.ZipFile]::Open($tempZip, "Create")
        foreach ($file in $sourceFiles) {
            $relPath = $file.FullName.Substring($profilePath.Length).TrimStart('\')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relPath) | Out-Null
        }
        $zip.Dispose()

        $hashVal = Get-FileHashMD5 $tempZip
        if ($null -eq $hashVal) { return "HASH_FAILED" }
        return $hashVal
    } catch {
        Write-Warning "RawHash failed for folder ${profilePath}: $($_.Exception.Message)"
        return "ERROR_$($_.Exception.GetType().Name)"
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    }
}

$profileFolders = Get-ChildItem -Path $ProfilesDir -Directory
$groups = @{}
$metaCache = @{}

if (-not $Silent) {
    Write-Host "Scanning $($profileFolders.Count) profiles..." -ForegroundColor Gray
}

foreach ($folder in $profileFolders) {
    $metaFile = Join-Path $folder.FullName "ProfileMeta.json"
    if (-not (Test-Path $metaFile)) { continue }

    try {
        $metaObj = Get-Content $metaFile -Raw | ConvertFrom-Json
        $metaCache[$folder.FullName] = $metaObj

        $calculatedHash = ""
        if ($RawHash) {
            $calculatedHash = Get-RawProfileHash $folder.FullName
        } else {
            # Evaluate format string
            $calculatedHash = $Hash
            $matches = [regex]::Matches($Hash, '\{([^}]+)\}')
            foreach ($match in $matches) {
                $propName = $match.Groups[1].Value
                $val = if ($metaObj.PSObject.Properties[$propName]) { $metaObj.$propName } else { "NULL" }
                $calculatedHash = $calculatedHash.Replace("{$propName}", $val)
            }
        }

        if (-not $groups.ContainsKey($calculatedHash)) {
            $groups[$calculatedHash] = [System.Collections.Generic.List[string]]::new()
        }
        $groups[$calculatedHash].Add($folder.FullName)
    } catch {
        Write-Warning "Failed to process profile at $($folder.FullName): $($_.Exception.Message)"
    }
}

$duplicateGroups = $groups.Keys | Where-Object { $groups[$_].Count -gt 1 }

if ($duplicateGroups.Count -eq 0) {
    if (-not $Silent) {
        Write-Host "No duplicates found." -ForegroundColor Green
    }
    exit
}

Write-Host "Found $($duplicateGroups.Count) groups of duplicates!" -ForegroundColor Yellow

foreach ($hashVal in $duplicateGroups) {
    $paths = $groups[$hashVal]
    Write-Host "`nGroup: $hashVal" -ForegroundColor Cyan
    
    $keep = $paths[0]
    $toDelete = $paths | Select-Object -Skip 1

    foreach ($p in $paths) {
        if (-not $metaCache.ContainsKey($p)) { continue }
        $m = $metaCache[$p]
        $isKeep = ($p -eq $keep)
        $prefix = if ($isKeep) { "[KEEP]" } else { "[DUPE]" }
        $color = if ($isKeep) { "Green" } else { "Yellow" }
        
        Write-Host "  $prefix $($m.gameName) ($($m.ID))" -ForegroundColor $color
        Write-Host "         Author: $($m.authorName) | Source: $($m.sourceName)" -ForegroundColor Gray
        Write-Host "         Path:   $p" -ForegroundColor DarkGray
    }

    if ($Delete) {
        foreach ($p in $toDelete) {
            Write-Host "  Deleting $p..." -ForegroundColor Red
            Remove-Item $p -Recurse -Force
        }
    }
}

if (-not $Delete -and -not $Silent) {
    Write-Host "`nRun with -Delete to automatically cleanup duplicates." -ForegroundColor Gray
}
