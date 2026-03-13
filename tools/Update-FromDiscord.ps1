#region Parameters
param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [switch]$Delete,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$CleanCache,
    [switch]$CleanDownloads
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

$ExpectedCount = if ($ProfileLimit -ne [int]::MaxValue) { $ProfileLimit } else { [int]::MaxValue }
#endregion

#region Functions
function Fetch-DiscordMetadata {
    Write-Host "Running Discord bot scraper to fetch profile metadata (Limit: $ProfileLimit)..." -ForegroundColor Cyan
    if (-not (Test-Path (Join-Path $BotDir "node_modules"))) {
        Write-Host "Installing bot dependencies..." -ForegroundColor Gray
        Push-Location $BotDir; npm install; Pop-Location
    }
    $env:PROFILES_JSON   = $MetadataJson
    $env:PROFILES_CSV    = $ProfilesCsv
    $env:BOT_STATE_JSON  = $BotStateJson
    $limitArg = if ($ProfileLimit -ne [int]::MaxValue) { "--limit=$ProfileLimit" } else { "" }
    Push-Location $BotDir; Invoke-Expression "node index.js $limitArg"; Pop-Location
}

function Download-DiscordProfiles {
    if (-not (Test-Path $MetadataJson)) { Write-Error "Metadata not found at $MetadataJson. Run with -Fetch first."; return }
    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    Write-Host "Downloading profiles from Discord metadata..." -ForegroundColor Cyan
    $count = 0; $failCount = 0; $total = $profiles.Count; $index = 0
    foreach ($p in $profiles) {
        $index++
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures. Skipping remaining."; break }

        $uuid = Get-OrCreateUUID $p
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"

        if (-not (Test-Path $targetFile)) {
            Write-Host "[$index/$total] Downloading: $($p.gameName) ($($p.zipName))..." -ForegroundColor Gray
            try {
                Invoke-WebRequestWithRetry -url $p.sourceDownloadUrl -targetFile $targetFile -Silent $Silent
                $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                $category = if ($p.category) { $p.category.Replace("ue-", "").Replace("nsfw", "NSFW").Trim() } else { "" }
                if ($category -and $category -ne "games") {
                   if ($category -eq "experiences") { $category = "Experiences" }
                   $tagSet.Add($category) | Out-Null
                }
                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = if ($p.exeName) { $p.exeName } else { $p.archive.Replace(".zip", "") }
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "createdDate"       = Format-DateISO8601 $p.createdDate
                    "sourceName"        = "discord.gg/flat2vr"
                    "sourceUrl"         = $p.sourceUrl
                    "sourceDownloadUrl" = $p.sourceDownloadUrl
                    "description"       = $p.description
                    "headerPictureUrl"  = $p.gameBanner
                    "tags"              = @($tagSet)
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $p.exeName
                }
                $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++; $failCount = 0
                Write-Host "  [OK] Download successful." -ForegroundColor Green
            } catch {
                Write-Host "  [!] Download failed: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
            }
        }
    }
}
#endregion

#region Main Logic
# Handle cleanup logic
if ($Delete -or $CleanCache) {
    Write-Host "Deleting cache for $SourceName..." -ForegroundColor Yellow
    foreach ($f in @($MetadataJson, $ProfilesCsv, $BotStateJson)) {
        if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
    }
}
if ($Delete -or $CleanDownloads) {
    if (Test-Path $DownloadDir) {
        Write-Host "Deleting downloads for $SourceName..." -ForegroundColor Yellow
        Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

foreach ($d in @($SourceTempDir, $DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Fetch) { 
    Fetch-DiscordMetadata
    $results = if (Test-Path $MetadataJson) { Get-Content $MetadataJson -Raw | ConvertFrom-Json } else { @() }
    Assert-ProfileCount -count $results.Count -expected $ProfileLimit -Silent:$Silent -stage "Fetch"
    $ExpectedCount = [Math]::Min($ExpectedCount, $results.Count)
}

if ($Download) { 
    Download-DiscordProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Assert-ProfileCount -count $zips.Count -expected $ExpectedCount -Silent:$Silent -stage "Download"
    $ExpectedCount = [Math]::Min($ExpectedCount, $zips.Count)
}

if ($Extract) { 
    Extract-ArchivesFolder $DownloadDir -Silent:$Silent
    $processed = Get-ChildItem -Path $ProfilesDir -Directory | Where-Object { (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) }
    $profileIds = $processed | ForEach-Object { (Get-Content (Join-Path $_.FullName "ProfileMeta.json") -Raw | ConvertFrom-Json).ID } | Select-Object -Unique
    Assert-ProfileCount -count $profileIds.Count -expected $ExpectedCount -Silent:$Silent -stage "Extraction ID"
}
#endregion
