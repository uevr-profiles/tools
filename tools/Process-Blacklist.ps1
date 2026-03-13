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
function Get-BlacklistPatterns {
    return @("^sdkdump/.*\.(cpp|hpp)$","^plugins/.*\.pdb$","\.bak$","\.org$","^cvardump\.json$")
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    foreach ($p in Get-BlacklistPatterns) { if ($rel -match $p) { return $true } }
    return $false
}
#endregion

Write-Host "Running Blacklist processing..." -ForegroundColor Cyan

$profileFolders = Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") }

foreach ($folder in $profileFolders) {
    Debug-Log "Processing Blacklist for $($folder.FullName)"
    $files = Get-ChildItem -Path $folder.FullName -File -Recurse
    foreach ($file in $files) {
        $relPath = [IO.Path]::GetRelativePath($folder.FullName, $file.FullName)
        if (Test-Blacklisted $relPath) {
            Write-Host "  [BLACKLIST] Flagged for removal: $relPath (in $($folder.Name))" -ForegroundColor Yellow
            if ($Delete) {
                Remove-Item $file.FullName -Force
            }
        }
    }
}

if (-not $Delete) {
    Write-Host "`nDry run complete. Run with -Delete to actually remove blacklisted files." -ForegroundColor Gray
} else {
    Write-Host "`nBlacklist processing complete." -ForegroundColor Green
}
