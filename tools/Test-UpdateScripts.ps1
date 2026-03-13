#region Parameters
param(
    [switch]$Clean,
    [switch]$Silent
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$Scripts = @(
    "Update-FromUEVRProfiles.ps1", 
    "Update-FromUEVRDeluxe.ps1",
    "Update-FromDiscord.ps1"
)
#endregion

#region Main Logic
if ($Clean) {
    Write-Host "Cleaning cache: $BaseTempDir" -ForegroundColor Yellow
    Remove-Item $BaseTempDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    
    Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
    if (Test-Path $ProfilesDir) {
        Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    }
}

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
#endregion
