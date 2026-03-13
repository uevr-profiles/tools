param(
    [switch]$Clean
)

$ToolsDir = $PSScriptRoot
$RepoRoot = Split-Path $ToolsDir -Parent
$ProfilesDir = Join-Path $RepoRoot "profiles"
$CacheDir = Join-Path $env:TEMP "uevr_profiles"

if ($Clean) {
    Write-Host "Cleaning cache: $CacheDir" -ForegroundColor Yellow
    Remove-Item $CacheDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    
    Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
    if (Test-Path $ProfilesDir) {
        Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    }
}

if (-not (Test-Path $RepoRoot)) {
    Write-Error "Repo directory not found at $RepoRoot"
    exit 1
}

Set-Location $RepoRoot

$Scripts = @(
    "tools/Update-FromUEVRProfiles.ps1", 
    "tools/Update-FromUEVRDeluxe.ps1",
    "tools/Update-FromDiscord.ps1"
)

foreach ($s in $Scripts) {
    if (Test-Path $s) {
        Write-Host "`n>>> Testing $s <<<" -ForegroundColor Cyan
        try {
            & $s -Fetch -Download -Extract -Whitelist -ProfileLimit 1
        } catch {
            Write-Host "    [!] Test failed for ${s}: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Warning "Skipping $s (file not found: $s)"
    }
}

Write-Host "`nTest run complete." -ForegroundColor Green
exit 0
