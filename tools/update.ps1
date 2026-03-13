param(
    [string]$Proxies = "http://45.136.131.31:8443,http://45.136.131.42:8447,http://138.124.53.25:7443,http://38.145.218.10:8443"
)

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

$LogsDir  = Join-Path $RepoRoot "logs"
$UnixTime = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$LogFile  = Join-Path $LogsDir "$($UnixTime)_update.log"

if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
Write-Host "Logging to $LogFile" -ForegroundColor DarkGray
Start-Transcript -Path $LogFile -Append -Force | Out-Null

try {
    .\tools\Update-FromDiscord.ps1 -Extract -Whitelist -Debug
    .\tools\Update-FromUEVRDeluxe.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads -Debug -Proxies $Proxies
    .\tools\Update-FromUEVRProfiles.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads -Debug
    .\tools\Find-Issues.ps1 -Fix -Debug
    .\tools\Deduplicate-Profiles.ps1 -Delete -Debug
    .\tools\Build-UEVRRepo.ps1 -Debug
} finally {
    Stop-Transcript | Out-Null
}