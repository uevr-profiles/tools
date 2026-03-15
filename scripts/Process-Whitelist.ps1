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
function Get-WhitelistPatterns {
    return @(
        "^README\.md$", "^ProfileMeta\.json$", "^_interaction_profiles_oculus_touch_controller\.json$",
        "^actions\.json$", "^binding_rift\.json$", "^binding_vive\.json$", "^bindings_knuckles\.json$",
        "^bindings_oculus_touch\.json$", "^bindings_vive_controller\.json$", "^cameras\.txt$", "^config\.txt$",
        "^cvars_data\.txt$", "^cvars_standard\.txt$", "^uevr_nightly_build\.txt$", "^user_script\.txt$",
        "^scripts/.*\.lua$", "^plugins/.*\.(dll|so)$", "^uobjecthook/.*\.json$", "^(_EXTRAS|data|libs|paks)/.+", ".*\.ini$",
        "^(_EXTRAS\.zip|_EXTRAS/.*)$"
    )
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    foreach ($p in Get-WhitelistPatterns) { if ($rel -match $p) { return $true } }
    return $false
}
#endregion

Write-Host "Running Whitelist processing..." -ForegroundColor Cyan

$profileFolders = Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") }

foreach ($profileFolder in $profileFolders) {
    Debug-Log "Processing Whitelist for $($profileFolder.FullName)"
    $files = Get-ChildItem -Path $profileFolder.FullName -File -Recurse
    $flaggedFiles = @()

    foreach ($file in $files) {
        $relPath = [IO.Path]::GetRelativePath($profileFolder.FullName, $file.FullName)
        if (-not (Test-Whitelisted $relPath)) {
            $flaggedFiles += $file
        }
    }

    if ($flaggedFiles.Count -eq 0) { continue }

    Write-Host "  Processing $($flaggedFiles.Count) non-whitelisted files in $($profileFolder.Name)..." -ForegroundColor Gray
    
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
    Write-Host "`nDry run complete. Run with -Delete to actually remove non-whitelisted files." -ForegroundColor Gray
} else {
    Write-Host "`nWhitelist processing complete." -ForegroundColor Green
}
