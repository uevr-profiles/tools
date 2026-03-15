param(
    [switch]$Archive,
    [switch]$Folder,
    [switch]$Delete,
    [switch]$Debug
)

#region Dependencies
$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
. "$ScriptRoot\common.ps1"
$Global:Debug = $Debug
#endregion

#region Filtering Helpers
function Get-BlacklistPatterns {
    return @("^sdkdump/.*\.(cpp|hpp)$","^plugins/.*\.pdb$","\.bak$","\.org$","^cvardump\.json$")
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    if ($rel -match "^(_EXTRAS\.zip|_EXTRAS/.*)$") { return $false }
    foreach ($p in Get-BlacklistPatterns) { if ($rel -match $p) { return $true } }
    return $false
}
#endregion

Write-Host "Running Blacklist processing..." -ForegroundColor Cyan

$profileFolders = Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") }

foreach ($profileFolder in $profileFolders) {
    Debug-Log "Processing Blacklist for $($profileFolder.FullName)"
    $files = Get-ChildItem -Path $profileFolder.FullName -File -Recurse
    $flaggedFiles = @()

    foreach ($file in $files) {
        $relPath = [IO.Path]::GetRelativePath($profileFolder.FullName, $file.FullName)
        if (Test-Blacklisted $relPath) {
            $flaggedFiles += $file
        }
    }

    if ($flaggedFiles.Count -eq 0) { continue }

    Write-Host "  Processing $($flaggedFiles.Count) blacklisted files in $($profileFolder.Name)..." -ForegroundColor Yellow
    
    if ($Archive) {
        $archivePath = Join-Path $profileFolder.FullName "_EXTRAS.zip"
        Write-Host "    [ARCHIVE] Adding to _EXTRAS.zip..." -ForegroundColor Gray
        Compress-Files -FilePaths $flaggedFiles.FullName -TargetArchive $archivePath -CompressionLevel 9
    }

    if ($Folder) {
        $extrasDir = Join-Path $profileFolder.FullName "_EXTRAS"
        Write-Host "    [FOLDER] Moving to _EXTRAS/ folder..." -ForegroundColor Gray
        if (-not (Test-Path $extrasDir)) { New-Item -ItemType Directory -Path $extrasDir -Force | Out-Null }
        foreach ($file in $flaggedFiles) {
            $relPath = [IO.Path]::GetRelativePath($profileFolder.FullName, $file.FullName)
            $dest = Join-Path $extrasDir $relPath
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item $file.FullName -Destination $dest -Force
        }
    }

    if ($Delete) {
        Write-Host "    [DELETE] Removing original files..." -ForegroundColor Red
        foreach ($file in $flaggedFiles) {
            Remove-Item $file.FullName -Force
        }
    }

    if (-not $Archive -and -not $Folder -and -not $Delete) {
        foreach ($file in $flaggedFiles) {
            $relPath = [IO.Path]::GetRelativePath($profileFolder.FullName, $file.FullName)
            Write-Host "    [LIST] Would remove: $relPath" -ForegroundColor Gray
        }
    }
}

if (-not $Delete) {
    Write-Host "`nDry run complete. Run with -Delete to actually remove blacklisted files." -ForegroundColor Gray
} else {
    Write-Host "`nBlacklist processing complete." -ForegroundColor Green
}
