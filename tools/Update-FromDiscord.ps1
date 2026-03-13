param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

. "$PSScriptRoot\common.ps1"

$SourceName   = "discord"
$DownloadDir  = Join-Path $BaseTempDir $SourceName
$BotDir       = Join-Path $PSScriptRoot "discord-bot"
$MetadataJson = Join-Path $BotDir "discord_profiles.json"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ──────── Phase 0: Fetching Metadata (via Bot) ────────────────────────────────
if ($Fetch) {
    if (-not (Test-Path (Join-Path $BotDir "node_modules"))) {
        Write-Host "Installing Discord bot dependencies..." -ForegroundColor Cyan
        pushd $BotDir
        npm install
        popd
    }

    Write-Host "Running Discord bot scraper to fetch profile metadata (Limit: $ProfileLimit)..." -ForegroundColor Cyan
    pushd $BotDir
    node index.js "--limit=$ProfileLimit"
    $botExit = $LASTEXITCODE
    popd

    if ($botExit -ne 0) {
        throw "Discord scraper failed with exit code $botExit. Check the logs above for details."
    }

    if (-not (Test-Path $MetadataJson)) {
        throw "Discord scraper failed to produce metadata JSON at $MetadataJson"
    }
}

# ──────── Phase 1: Downloads ──────────────────────────────────────────────────
if ($Download) {
    if (-not (Test-Path $MetadataJson)) {
        Write-Warning "Metadata file not found at $MetadataJson. Run with -Fetch first."
        return
    }

    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    $count = 0
    $failCount = 0

    Write-Host "Downloading profiles from Discord metadata..." -ForegroundColor Cyan
    foreach ($p in $profiles) {
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }

        # Filename: <msgId>_<zipId>.zip to prevent collisions
        $targetFile = Join-Path $DownloadDir "$($p.id).zip"
        $sidecar    = $targetFile + ".json"

        if (-not (Test-Path $targetFile)) {
            $msg = "Downloading: $($p.gameName) ($($p.archive))"
            Write-Host "$msg..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $p.sourceDownloadUrl -targetFile $targetFile
                Write-Host "  [OK] Download successful." -ForegroundColor Green
                
                # Sidecar metadata for extraction phase
                $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++
                $failCount = 0
            } catch {
                Write-Host "  [!] All download attempts failed: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
            }
        }
    }
}

# ──────── Phase 2: Extraction & Integration ────────────────────────────────────
if ($Extract) {
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Write-Host "Processing $($zips.Count) profiles from $SourceName..." -ForegroundColor Cyan

    foreach ($z in $zips) {
        try {
            $sidecar = $z.FullName + ".json"
            if (-not (Test-Path $sidecar)) { continue }
            $p = Get-Content $sidecar -Raw | ConvertFrom-Json

            $zipHash = Get-FileHashMD5 $z.FullName
            
            # Discover profiles within archive
            $discovered = Extract-And-Discover-Profiles $z.FullName $Whitelist $Blacklist
            
            foreach ($d in $discovered) {
                $variant = $d.Variant
                $tempDir = $d.Path
                $uuid = Get-OrCreateUUID $p.id # Using Discord IDs for deterministic UUID
                
                $targetDir = Join-Path $ProfilesDir $uuid
                if ($variant -and $variant -ne "[Root]") {
                    $vPath = $variant -replace ' / ', '\'
                    $targetDir = Join-Path $targetDir $vPath
                }
                
                # Move contents
                $relFiles = Get-ChildItem -Path $tempDir -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object { 
                    $_.FullName.Substring($tempDir.Length).TrimStart('\')
                }
                Update-GlobalFilesList $relFiles
                Move-Item-Smart $tempDir $targetDir

                # Best effort for exeName: user says it's mostly the archive filename
                $finalExe = $p.archive -replace '\.(zip|7z|rar|r..|0..)$',''
                
                # Check description for a more specific -Win64-Shipping hint
                if ($p.description -match '(\w+\-Win64\-Shipping)') {
                    $finalExe = $matches[1]
                }
                
                $metaProps = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $finalExe
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "modifiedDate"      = Format-ISO8601Date $p.modifiedDate
                    "createdDate"       = Format-ISO8601Date $p.createdDate
                    "sourceName"        = "discord.gg/flat2vr"
                    "sourceUrl"         = $p.sourceUrl
                    "sourceDownloadUrl" = $p.sourceDownloadUrl
                    "description"       = $p.description
                    "gameBanner"        = $p.gameBanner
                    "downloadDate"      = Get-ISO8601Now
                    "zipHash"           = $zipHash.ToUpper()
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $finalExe
                }

                # Tags support (Heuristics + Category)
                $tagArray = @(Get-HeuristicTags $targetDir $metaProps $null)
                
                # Map sourceChannel to a clean category tag
                $category = switch -regex ($p.sourceChannel) {
                    "game" { "Game" }
                    "exp"  { "Experiences" }
                    "nsfw" { "NSFW" }
                    default { $p.sourceChannel }
                }
                if ($category -and -not ($tagArray -contains $category)) {
                    $tagArray += $category
                }

                if ($tagArray -and $tagArray.Count -gt 0) {
                    $metaProps["tags"] = $tagArray
                }

                $meta = Save-ProfileMetadata $targetDir $metaProps $z.FullName $variant

                if (-not $Silent) {
                    Print-ProfileInfo $meta $z.FullName
                }
            }
        } catch {
            Write-Host "  [!] Extraction failed for $($z.Name): $($_.Exception.Message)" -ForegroundColor Red
            if (-not $Silent) { throw "Fatal: Profile processing error for $($z.Name). Stopping because -Silent is not set." }
        }
    }
}

Finalize-GlobalTracking
