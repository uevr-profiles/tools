param(
    [switch]$Clear
)

$ToolsDir = $PSScriptRoot
$RepoRoot = Split-Path $ToolsDir -Parent
$ProfilesDir = Join-Path $RepoRoot "profiles"
$CacheDir = Join-Path $env:TEMP "uevr_profiles"

if ($Clear) {
    Write-Host "Clearing cache: $CacheDir" -ForegroundColor Yellow
    Remove-Item $CacheDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    
    Write-Host "Clearing profiles: $ProfilesDir" -ForegroundColor Yellow
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
        # Start the process and kill it if it takes too long or we see it's failing
        $job = Start-Job -ScriptBlock {
            param($script, $pDir)
            Set-Location $pDir
            pwsh -NoProfile -File $script -Fetch -Download -Extract -ProfileLimit 1
        } -ArgumentList $s, $RepoDir

        # Wait for a reasonable amount of time for a single profile test
        if (-not (Wait-Job $job -Timeout 30)) {
            Write-Warning "Test for $s timed out or is spamming. Terminating."
            Stop-Job $job
        }
        Receive-Job $job
        Remove-Job $job
    } else {
        Write-Warning "Skipping $s (not found in this commit)"
    }
}

Write-Host "`nTest run complete." -ForegroundColor Green
exit 0
