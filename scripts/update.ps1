param(
    [string]$Proxies = "http://121.126.185.63:25152,http://38.145.203.135:8443,http://216.180.127.45:1080,http://85.198.96.242:3128,http://38.145.218.82:8443,http://45.136.130.216:8443,http://103.30.30.226:20326,http://45.136.130.211:8447,DIRECT",
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
    .\scripts\Update-FromDiscord.ps1 -Fetch -Download -Extract -CleanCache -CleanDownloads -Debug -Proxies $Proxies
    .\scripts\Update-FromUEVRDeluxe.ps1 -Fetch -Download -Extract -CleanCache -CleanDownloads -Debug -Proxies $Proxies
    .\scripts\Update-FromUEVRProfiles.ps1 -Fetch -Download -Extract -CleanCache -CleanDownloads -Debug -Silent -Proxies $Proxies
    
    .\scripts\Find-Issues.ps1 -Fix -Debug
    .\scripts\Process-Whitelist.ps1 -Delete -Debug
    # .\scripts\Process-Blacklist.ps1 -Delete -Debug
    .\scripts\Deduplicate-Profiles.ps1 -Delete -Debug
    .\scripts\Build-UEVRRepo.ps1 -Debug
} finally {
    Stop-Transcript | Out-Null
}