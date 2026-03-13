param(
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
    return @("^README\.md$","^ProfileMeta\.json$","^_interaction_profiles_oculus_touch_controller\.json$","^actions\.json$","^binding_rift\.json$","^binding_vive\.json$","^bindings_knuckles\.json$","^bindings_oculus_touch\.json$","^bindings_vive_controller\.json$","^cameras\.txt$","^config\.txt$","^cvars_data\.txt$","^cvars_standard\.txt$","^uevr_nightly_build\.txt$","^user_script\.txt$","^scripts/.*\.lua$","^plugins/.*\.(dll|so)$","^uobjecthook/.*\.json$","^(_EXTRAS|data|libs|paks)/.+")
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    foreach ($p in Get-WhitelistPatterns) { if ($rel -match $p) { return $true } }
    return $false
}
#endregion

Write-Host "Running Whitelist processing..." -ForegroundColor Cyan

$profileFolders = Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") }

foreach ($folder in $profileFolders) {
    Debug-Log "Processing Whitelist for $($folder.FullName)"
    $files = Get-ChildItem -Path $folder.FullName -File -Recurse
    foreach ($file in $files) {
        $relPath = [IO.Path]::GetRelativePath($folder.FullName, $file.FullName)
        if (-not (Test-Whitelisted $relPath)) {
            Write-Host "  [WHITELIST] Flagged for removal: $relPath (in $($folder.Name))" -ForegroundColor Gray
            if ($Delete) {
                Remove-Item $file.FullName -Force
            }
        }
    }
}

if (-not $Delete) {
    Write-Host "`nDry run complete. Run with -Delete to actually remove non-whitelisted files." -ForegroundColor Gray
} else {
    Write-Host "`nWhitelist processing complete." -ForegroundColor Green
}
