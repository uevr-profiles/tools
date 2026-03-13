param(
    [switch]$Clean,
    [switch]$Silent
)

. "$PSScriptRoot\common.ps1"

if ($Clean) {
    Write-Host "Cleaning cache: $BaseTempDir" -ForegroundColor Yellow
    Remove-Item $BaseTempDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    
    Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
    if (Test-Path $ProfilesDir) {
        Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    }
}

$Scripts = @(
    "Update-FromUEVRProfiles.ps1", 
    "Update-FromUEVRDeluxe.ps1",
    "Update-FromDiscord.ps1"
)

foreach ($s in $Scripts) {
    $scriptPath = Join-Path $PSScriptRoot $s
    if (Test-Path $scriptPath) {
        Write-Host "`n>>> Testing $s <<<" -ForegroundColor Cyan
        try {
            # Run with limits for fast testing
            & $scriptPath -Fetch -Download -Extract -Delete -ProfileLimit 1 -Silent:$Silent
        } catch {
            Write-Host "    [!] Test failed for ${s}: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Warning "Skipping $s (file not found: $scriptPath)"
    }
}

Write-Host "`nTest run complete." -ForegroundColor Green
exit 0
