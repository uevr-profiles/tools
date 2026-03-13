param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$CleanCache,
    [switch]$CleanDownloads
)

. "$PSScriptRoot\common.ps1"

$SourceName   = "discord"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$BotDir        = Join-Path $PSScriptRoot "discord-bot"

# File paths within the metadata cache
$MetadataJson  = Join-Path $SourceTempDir "cache.json"
$ProfilesCsv   = Join-Path $SourceTempDir "discord_profiles.csv"
$BotStateJson  = Join-Path $SourceTempDir "bot_state.json"

if ($CleanCache -and (Test-Path $MetadataJson)) {
    Write-Host "Cleaning cache for $SourceName..." -ForegroundColor Yellow
    Remove-Item $MetadataJson -Force
    if (Test-Path $ProfilesCsv) { Remove-Item $ProfilesCsv -Force }
    if (Test-Path $BotStateJson) { Remove-Item $BotStateJson -Force }
}
if ($CleanDownloads -and (Test-Path $DownloadDir)) {
    Write-Host "Cleaning downloads for $SourceName..." -ForegroundColor Yellow
    Remove-Item $DownloadDir -Recurse -Force
}

foreach ($d in @($SourceTempDir, $DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Fetch-DiscordMetadata {
    Write-Host "Running Discord bot scraper to fetch profile metadata (Limit: $ProfileLimit)..." -ForegroundColor Cyan
    
    # Check for node_modules
    if (-not (Test-Path (Join-Path $BotDir "node_modules"))) {
        Write-Host "Installing bot dependencies..." -ForegroundColor Gray
        Push-Location $BotDir
        npm install
        Pop-Location
    }

    $env:PROFILES_JSON   = $MetadataJson
    $env:PROFILES_CSV    = $ProfilesCsv
    $env:BOT_STATE_JSON  = $BotStateJson

    $limitArg = if ($ProfileLimit -ne [int]::MaxValue) { "--limit=$ProfileLimit" } else { "" }
    $cmd = "node index.js $limitArg"
    
    Push-Location $BotDir
    Invoke-Expression $cmd
    Pop-Location
}

function Download-DiscordProfiles {
    if (-not (Test-Path $MetadataJson)) {
        Write-Error "Discord metadata not found at $MetadataJson. Run with -Fetch first."
        return
    }

    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    Write-Host "Downloading profiles from Discord metadata..." -ForegroundColor Cyan
    
    $count = 0
    $failCount = 0
    foreach ($p in $profiles) {
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures. Skipping remaining."; break }

        # Assign UUID based on sourceUrl + sourceDownloadUrl
        $uuid = Get-OrCreateUUID $p
        $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"

        if (-not (Test-Path $targetFile)) {
            Write-Host "[$($count+1)/$($profiles.Count)] Downloading: $($p.gameName) ($($p.zipName))..." -ForegroundColor Gray
            try {
                Invoke-WebRequestWithRetry -url $p.sourceDownloadUrl -targetFile $targetFile -Silent $Silent
                
                # Standardize Sidecar Metadata
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
                    "createdDate"       = Format-ISO8601Date $p.createdDate
                    "sourceName"        = "discord.gg/flat2vr"
                    "sourceUrl"         = $p.sourceUrl
                    "sourceDownloadUrl" = $p.sourceDownloadUrl
                    "description"       = $p.description
                    "headerPictureUrl"  = $p.gameBanner
                    "tags"              = @($tagSet)
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $p.exeName
                }
                $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8

                $count++
                $failCount = 0
                Write-Host "  [OK] Download successful." -ForegroundColor Green
            } catch {
                Write-Host "  [!] Download failed: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
            }
        }
    }
}

function Extract-DiscordProfiles {
    Write-Host "Extracting archives from $SourceName..." -ForegroundColor Cyan
    Extract-ArchivesFolder $DownloadDir -Silent:$Silent
}

# ──────── Main Logic Entry ────────────────────────────────────────────────────
$ExpectedCount = if ($ProfileLimit -ne [int]::MaxValue) { $ProfileLimit } else { [int]::MaxValue }

if ($Fetch) { 
    Fetch-DiscordMetadata
    $results = if (Test-Path $MetadataJson) { Get-Content $MetadataJson -Raw | ConvertFrom-Json } else { @() }
    $actual = $results.Count
    if ($ProfileLimit -ne [int]::MaxValue -and $actual -lt $ProfileLimit) {
        $msg = "Discord fetch count mismatch. Expected at least $ProfileLimit, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
    $ExpectedCount = [Math]::Min($ExpectedCount, $actual)
}

if ($Download) { 
    Download-DiscordProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    $actual = $zips.Count
    if ($ExpectedCount -ne [int]::MaxValue -and $actual -lt $ExpectedCount) {
        $msg = "Discord download count mismatch. Expected at least $ExpectedCount, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
    $ExpectedCount = [Math]::Min($ExpectedCount, $actual)
}

if ($Extract) { 
    Extract-DiscordProfiles 
    $processed = Get-ChildItem -Path $ProfilesDir -Directory | Where-Object { (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) }
    $profileIds = $processed | ForEach-Object { (Get-Content (Join-Path $_.FullName "ProfileMeta.json") -Raw | ConvertFrom-Json).ID } | Select-Object -Unique
    $actual = $profileIds.Count
    if ($ExpectedCount -ne [int]::MaxValue -and $actual -lt $ExpectedCount) {
        $msg = "Discord extraction ID count mismatch. Expected at least $ExpectedCount unique profile IDs, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
}
