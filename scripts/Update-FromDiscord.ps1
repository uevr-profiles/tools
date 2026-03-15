#region Parameters
param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$Debug,
    [switch]$CleanCache,
    [switch]$CleanDownloads,
    [switch]$UseProxies,
    [switch]$UseTailscale
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$SourceName   = "discord"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$BotDir        = Join-Path $PSScriptRoot "discord-bot"

$MetadataJson  = Join-Path $SourceTempDir "cache.json"
$ProfilesCsv   = Join-Path $SourceTempDir "discord_profiles.csv"
$BotStateJson  = Join-Path $SourceTempDir "bot_state.json"

if ($ProfileLimit -ne [int]::MaxValue) {
    $ExpectedCount = $ProfileLimit
} else {
    $ExpectedCount = [int]::MaxValue
}
#endregion

#region Functions
function Fetch-DiscordMetadata {
    Debug-Log "[Update-FromDiscord.ps1] Entering Fetch-DiscordMetadata"
    $limitArg = ""
    if ($ProfileLimit -ne [int]::MaxValue) {
        $limitArg = "--limit=$ProfileLimit"
    }
    Debug-Log "[Update-FromDiscord.ps1] Bot limitArg: $limitArg"
    
    $env:PROFILES_JSON   = $MetadataJson
    $env:PROFILES_CSV    = $ProfilesCsv
    $env:BOT_STATE_JSON  = $BotStateJson
    if ($Proxies) {
        $proxyString = ""
        if ($Proxies -is [System.Management.Automation.PSCustomObject]) {
            foreach ($p in $Proxies.PSObject.Properties) {
                if ($p.Name -ne "DIRECT" -and $p.Name -notmatch "^DIRECT") { 
                    $proxyString = $p.Name
                    break 
                }
            }
        } else {
            $proxyList = @()
            if ($Proxies -is [array]) { $proxyList = $Proxies }
            else { $proxyList = $Proxies -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
            if ($proxyList.Count -gt 0) { $proxyString = $proxyList[0] }
        }

        if ($proxyString -and $proxyString -ne "DIRECT") {
            Debug-Log "[Update-FromDiscord.ps1] Node Bot Proxy identified as $proxyString"
        }
    }
    Debug-Log "[Update-FromDiscord.ps1] Running bot in $BotDir"
    Push-Location $BotDir
    Invoke-Expression "node index.js $limitArg"
    Pop-Location
    Debug-Log "[Update-FromDiscord.ps1] Bot execution finished"
}

function Download-DiscordProfiles {
    Debug-Log "[Update-FromDiscord.ps1] Entering Download-DiscordProfiles"
    if (-not (Test-Path $MetadataJson)) { 
        Debug-Log "[Update-FromDiscord.ps1] Metadata check failed: $MetadataJson"
        Write-Error "Metadata not found at $MetadataJson. Run with -Fetch first."
        return 
    }
    $profiles = Load-ProfilesFromFile $MetadataJson
    Write-Host "Downloading profiles from Discord metadata ($($profiles.Count))..." -ForegroundColor Cyan
    $count = 0
    $failCount = 0
    $total = $profiles.Count
    $index = 0
    Debug-Log "[Update-FromDiscord.ps1] Starting profiles loop"
    foreach ($p in $profiles) {
        $index++
        Debug-Log "[Update-FromDiscord.ps1] Loop iteration $index / $total (Count: $count)"
        if ($count -ge $ProfileLimit) { 
            Debug-Log "[Update-FromDiscord.ps1] Reached ProfileLimit ($ProfileLimit)"
            break 
        }
        if ($failCount -ge 5) { 
            Debug-Log "[Update-FromDiscord.ps1] Too many failures ($failCount)"
            Write-Error "Too many consecutive failures in $SourceName. Stopping."
            break 
        }

        Debug-Log "[Update-FromDiscord.ps1] Calling Get-OrCreateUUID"
        $uuid = Get-OrCreateUUID $p
        Debug-Log "[Update-FromDiscord.ps1] UUID: $uuid"
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"

        Debug-Log "[Update-FromDiscord.ps1] Checking targetFile: $targetFile"
        if (-not (Test-Path $targetFile)) {
            Write-Host "[$index/$total] Downloading: $($p.gameName) ($($p.zipName))..." -ForegroundColor Gray
            try {
                Debug-Log "[Update-FromDiscord.ps1] Calling Invoke-WebRequestWithRetry"
                Invoke-WebRequestWithRetry -url $p.sourceDownloadUrl -targetFile $targetFile -Silent $Silent -Proxies $Proxies -TimeoutSec 60
                
                Debug-Log "[Update-FromDiscord.ps1] Download OK, creating HashSet"
                $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                
                $category = ""
                if ($p.category) {
                    $category = $p.category.Replace("ue-", "").Replace("nsfw", "NSFW").Trim()
                }
                Debug-Log "[Update-FromDiscord.ps1] Category: $category"

                if ($category -and $category -ne "games") {
                    if ($category -eq "experiences") { $category = "Experiences" }
                    $tagSet.Add($category) | Out-Null
                }
                
                if ($p.exeName) {
                    $exeForSafeDisc = $p.exeName
                } else {
                    $exeForSafeDisc = ($p.archive -replace '\.zip$', '')
                }
                $finalExe = Get-SafeExeName $exeForSafeDisc
                Debug-Log "[Update-FromDiscord.ps1] FinalExe: $finalExe"

                Debug-Log "[Update-FromDiscord.ps1] Calling Get-ProfileDownloadUrl"
                $dlUrl = Get-ProfileDownloadUrl $uuid $finalExe
                
                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $finalExe
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "createdDate"       = Format-DateISO8601 $p.createdDate
                    "sourceName"        = "discord.gg/flat2vr"
                    "sourceUrl"         = $p.sourceUrl
                    "sourceDownloadUrl" = $p.sourceDownloadUrl
                    "description"       = $p.description
                    "headerPictureUrl"  = $p.gameBanner
                    "tags"              = @($tagSet)
                    "downloadUrl"       = $dlUrl
                }
                
                Debug-Log "[Update-FromDiscord.ps1] Saving sidecar"
                $json = $sidecarObj | ConvertTo-Json
                Set-Content -Path $sidecar -Value $json -Encoding utf8
                $count++
                $failCount = 0
                Write-Host "  [OK] Download successful." -ForegroundColor Green
            } catch {
                Write-Host "  [!] Download failed: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { 
                    throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." 
                }
            }
        } else {
            Debug-Log "[Update-FromDiscord.ps1] $targetFile already exists"
        }
    }
    Debug-Log "[Update-FromDiscord.ps1] Finished Download-DiscordProfiles loop"
}
#endregion

#region Main Logic
Debug-Log "[Update-FromDiscord.ps1] Main Logic Start"
$Global:Debug = $Debug
$Global:UseProxies = $UseProxies
$Global:UseTailscale = $UseTailscale
if ($UseProxies) {
    $Proxies = $Global:ProxyPool
} else {
    $Proxies = $null
}

# Handle cleanup logic
Debug-Log "[Update-FromDiscord.ps1] Checking cleanup flags"
if ($CleanCache) {
    Write-Host "Deleting cache for $SourceName..." -ForegroundColor Yellow
    Debug-Log "[Update-FromDiscord.ps1] Cleaning cache: $MetadataJson"
    if (Test-Path $MetadataJson) { Remove-Item $MetadataJson -Force -ErrorAction SilentlyContinue }
    if (Test-Path $ProfilesCsv)  { Remove-Item $ProfilesCsv -Force -ErrorAction SilentlyContinue }
    if (Test-Path $BotStateJson) { Remove-Item $BotStateJson -Force -ErrorAction SilentlyContinue }
}
if ($CleanDownloads) {
    Write-Host "Deleting downloads for $SourceName..." -ForegroundColor Yellow
    Debug-Log "[Update-FromDiscord.ps1] Cleaning downloads: $DownloadDir"
    if (Test-Path $DownloadDir) { Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue }
}

# Ensure directories exist
Debug-Log "[Update-FromDiscord.ps1] Ensuring directories exist"
foreach ($d in @($SourceTempDir, $DownloadDir, $ProfilesDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Fetch) { 
    Debug-Log "[Update-FromDiscord.ps1] Calling Fetch-DiscordMetadata"
    Fetch-DiscordMetadata
    $results = Load-ProfilesFromFile $MetadataJson
    # Assert-ProfileCount -count $results.Count -expected $ProfileLimit -Silent:$Silent -stage "Fetch"
    $ExpectedCount = [Math]::Min($ExpectedCount, $results.Count)
}

if ($Download) { 
    Download-DiscordProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    # Assert-ProfileCount -count $zips.Count -expected $ExpectedCount -Silent:$Silent -stage "Download"
    $ExpectedCount = [Math]::Min($ExpectedCount, $zips.Count)
}

if ($Extract) { 
    Debug-Log "[Update-FromDiscord.ps1] Calling Extract-ArchivesFolder"
    $extracted = Extract-ArchivesFolder $DownloadDir -Limit $ProfileLimit -Silent:$Silent
    # Assert-ProfileCount -count $extracted.Count -expected $ExpectedCount -Silent:$Silent -stage "Extraction ID"
}
Finalize-GlobalTracking
#endregion
