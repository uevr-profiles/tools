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
                $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
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
    $archiveroots = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Write-Host "Processing $($archiveroots.Count) profiles from $SourceName... (Limit: $ProfileLimit)" -ForegroundColor Cyan

    $eCount = 0
    foreach ($archiveroot in $archiveroots) {
        if ($eCount -ge $ProfileLimit) { break }
        try {
            $eCount++
            $sidecar = $archiveroot.FullName + ".json"
            if (-not (Test-Path $sidecar)) { continue }
            $p = Get-Content $sidecar -Raw | ConvertFrom-Json

            $zipHash = Get-FileHashMD5 $archiveroot.FullName
            
            $extracted_archives = Extract-And-Discover-Profiles $archiveroot.FullName $Whitelist $Blacklist
            
            foreach ($extracted_archive in $extracted_archives) {
                $profile = $extracted_archive.Profile
                $tempDir = $extracted_archive.Path
                $uuid = $p.uuid

                $targetDir = Join-Path $ProfilesDir $uuid
                if ($profile -and $profile -ne "[Root]") {
                    $vPath = $profile -replace ' / ', '\'
                    $targetDir = Join-Path $targetDir $vPath
                }
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                
                # Move contents
                $relFiles = Get-ChildItem -Path $tempDir -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object { 
                    $_.FullName.Substring($tempDir.Length).TrimStart('\')
                }
                Update-GlobalFilesList $relFiles
                
                Move-Item-Smart $tempDir $targetDir

                # Meta creation
                $meta = [ProfileMetadata]::new()
                $meta.ID                = $uuid
                $meta.exeName           = if ($p.exeName) { $p.exeName } else { $p.archive.Replace(".zip", "") }
                $meta.gameName          = $p.gameName
                $meta.authorName        = $p.authorName
                $meta.createdDate       = Format-ISO8601Date $p.createdDate
                $meta.sourceName        = "discord.gg/flat2vr"
                $meta.sourceUrl         = $p.sourceUrl
                $meta.sourceDownloadUrl = $p.sourceDownloadUrl
                $meta.description       = $p.description
                $meta.headerPictureUrl  = $p.gameBanner
                $meta.downloadDate      = Format-ISO8601Date $p.downloadDate
                $meta.zipHash           = $zipHash.ToUpper()
                $meta.downloadUrl       = Get-ProfileDownloadUrl $uuid $meta.exeName

                # Handle Tags (Category + Heuristics)
                $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                
                $hTags = Get-HeuristicTags $targetDir $meta $profile
                if ($hTags) { foreach ($t in $hTags) { $tagSet.Add($t) | Out-Null } }

                $tagArray = [System.Collections.Generic.List[string]]::new($tagSet)
                $category = if ($p.category) { $p.category.Replace("ue-", "").Replace("nsfw", "NSFW").Trim() } else { "" }
                if ($category -and $category -ne "games") {
                   if ($category -eq "experiences") { $category = "Experiences" }
                   if ($category -and -not ($tagArray -contains $category)) {
                       $tagArray.Add($category)
                   }
                }

                if ($tagArray.Count -gt 0) {
                    $meta.tags = @($tagArray)
                }

                $meta.Save($targetDir, $archiveroot.FullName, $profile)

                if (-not $Silent) {
                    Print-ProfileInfo $meta $archiveroot.FullName $profile
                }
            }
        } catch {
            Write-Host "  [!] Extraction failed for $($archiveroot.Name): $($_.Exception.Message)" -ForegroundColor Red
            if (-not $Silent) { throw "Fatal: Profile processing error for $($archiveroot.Name). Stopping because -Silent is not set." }
        }
    }
}

# ──────── Main Logic Entry ────────────────────────────────────────────────────
if ($Fetch)    { 
    Fetch-DiscordMetadata
    if (-not $Silent -and $ProfileLimit -ne [int]::MaxValue) {
        $results = if (Test-Path $MetadataJson) { Get-Content $MetadataJson -Raw | ConvertFrom-Json } else { @() }
        if ($results.Count -lt $ProfileLimit) {
            throw "Fatal: Discord fetch count mismatch. Expected at least $ProfileLimit, got $($results.Count). Stopping because -Silent is not set."
        }
    }
}
if ($Download) { 
    Download-DiscordProfiles
    if (-not $Silent -and $ProfileLimit -ne [int]::MaxValue) {
        $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
        if ($zips.Count -lt $ProfileLimit) {
            throw "Fatal: Discord download count mismatch. Expected at least $ProfileLimit, got $($zips.Count). Stopping because -Silent is not set."
        }
    }
}
if ($Extract)  { Extract-DiscordProfiles }
