param(
    [switch]$Clean = $true
)

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

$LogsDir = Join-Path $RepoRoot "logs"
$UnixTime = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$LogFile = Join-Path $LogsDir "$($UnixTime)_update.log"

if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
Write-Host "Logging to $LogFile" -ForegroundColor DarkGray
Start-Transcript -Path $LogFile -Append -Force | Out-Null

try {
    if ($Clean) {
        Read-Host "Press enter to clean profiles dir"
        Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
        if (Test-Path $ProfilesDir) {
            Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
        }
    }
    .\scripts\Update-FromDiscord.ps1 -Extract -Debug
    .\scripts\Update-FromUEVRDeluxe.ps1 -Fetch -Download -Extract -CleanCache -CleanDownloads -Debug -UseProxies -UseTailscale
    .\scripts\Update-FromUEVRProfiles.ps1 -Fetch -Download -Extract -CleanCache -CleanDownloads -Debug -UseProxies -UseTailscale
    
    .\scripts\Find-Issues.ps1 -Fix -Debug
    .\scripts\Process-Whitelist.ps1 -Archive -Delete -Debug
    # .\scripts\Process-Blacklist.ps1 -Archive -Delete -Debug
    .\scripts\Deduplicate-Profiles.ps1 -Delete -Debug
    .\scripts\Build-UEVRRepo.ps1 -Debug
} finally {
    Stop-Transcript | Out-Null
}