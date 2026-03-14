param(
    [string]$Proxies = "http://121.126.185.63:25152,http://38.145.203.135:8443,http://216.180.127.45:1080,http://85.198.96.242:3128,http://38.145.218.82:8443,http://45.136.130.216:8443,http://103.30.30.226:20326,http://45.136.130.211:8447,DIRECT",
    [switch]$Clean = $false
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
    if ($Clean) {
        Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
        if (Test-Path $ProfilesDir) {
            Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
        }
    }
    # .\tools\Update-FromDiscord.ps1 -Extract -Debug -CleanCache -CleanDownloads -Debug -Proxies $Proxies
    # .\tools\Update-FromUEVRDeluxe.ps1 -Extract -CleanCache -CleanDownloads -Debug -Proxies $Proxies
    .\tools\Update-FromUEVRProfiles.ps1 -Fetch -Download -Extract -CleanCache -CleanDownloads -Debug -Proxies $Proxies
    
    .\tools\Find-Issues.ps1 -Fix -Debug
    .\tools\Process-Whitelist.ps1 -Delete -Debug
    # .\tools\Process-Blacklist.ps1 -Delete -Debug
    .\tools\Deduplicate-Profiles.ps1 -Delete -Debug
    .\tools\Build-UEVRRepo.ps1 -Debug
} finally {
    Stop-Transcript | Out-Null
}