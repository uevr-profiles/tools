param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$Cleanse,
    [switch]$Clean
)

. "$PSScriptRoot\common.ps1"

$SourceName   = "discord"
$DownloadDir  = Join-Path $BaseTempDir $SourceName
$BotDir       = Join-Path $PSScriptRoot "discord-bot"

# File paths within the metadata cache
$MetadataJson = Join-Path $MetaCacheDir "discord_profiles.json"
$ProfilesCsv  = Join-Path $MetaCacheDir "discord_profiles.csv"
$BotStateJson = Join-Path $MetaCacheDir "bot_state.json"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Migrate existing files if necessary
@(
    @{ Src = Join-Path $BotDir "discord_profiles.json"; Dest = $MetadataJson }
    @{ Src = Join-Path $BotDir "discord_profiles.csv";  Dest = $ProfilesCsv }
    @{ Src = Join-Path $BotDir "bot_state.json";       Dest = $BotStateJson }
) | ForEach-Object {
    if ((Test-Path $_.Src) -and (-not (Test-Path $_.Dest))) {
        Write-Host "Migrating $(Split-Path $_.Src -Leaf) to metadata cache..." -ForegroundColor Gray
        Move-Item $_.Src $_.Dest -Force
    }
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
    $env:PROFILES_JSON   = $MetadataJson
    $env:PROFILES_CSV    = $ProfilesCsv
    $env:BOT_STATE_JSON  = $BotStateJson
    
    pushd $BotDir
    node index.js "--limit=$ProfileLimit"
    $botExit = $LASTEXITCODE
    popd

    # Cleanup environment variables
    $env:PROFILES_JSON   = $null
    $env:PROFILES_CSV    = $null
    $env:BOT_STATE_JSON  = $null

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
    $total = $profiles.Count
    $index = 0
    foreach ($p in $profiles) {
        $index++
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }

        # Assign UUID based on message URL + archive
        $uuid = Get-OrCreateUUID $p
        $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

        # Filename: <uuid>.zip
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"

        if (-not (Test-Path $targetFile)) {
            $msg = "[$index/$total] Downloading: $($p.gameName) ($($p.archive))"
            Write-Host "$msg..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $p.sourceDownloadUrl -targetFile $targetFile -Silent $Silent
                Write-Host "  [OK] Download successful." -ForegroundColor Green
                
                # Metadata cleanups: Remove modifiedDate, Set downloadDate
                $p.PSObject.Properties.Remove("modifiedDate")
                $p | Add-Member -MemberType NoteProperty -Name "downloadDate" -Value (Get-ISO8601Now) -Force

                # Sidecar metadata for extraction phase
                $sidecarJson = ConvertTo-Json -InputObject $p
                $sidecarJson | Set-Content $sidecar -Encoding utf8
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
    if ($Clean -and (Test-Path $ProfilesDir)) {
        Write-Host "Cleaning profiles directory..." -ForegroundColor Gray
        Remove-Item -Path "$ProfilesDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Write-Host "Processing $($zips.Count) profiles from $SourceName... (Limit: $ProfileLimit)" -ForegroundColor Cyan

    $eCount = 0
    foreach ($z in $zips) {
        if ($eCount -ge $ProfileLimit) { break }
        try {
            $eCount++
            $sidecar = $z.FullName + ".json"
            if (-not (Test-Path $sidecar)) { continue }
            $p = Get-Content $sidecar -Raw | ConvertFrom-Json

            $zipHash = Get-FileHashMD5 $z.FullName
            
            # Discover profiles within archive
            $discovered = Extract-And-Discover-Profiles $z.FullName $Whitelist $Blacklist
            
            foreach ($d in $discovered) {
                $variant = $d.Variant
                $tempDir = $d.Path
                $uuid = $p.uuid
                
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
                    "createdDate"       = Format-ISO8601Date $p.createdDate
                    "sourceName"        = "discord.gg/flat2vr"
                    "sourceUrl"         = $p.sourceUrl
                    "sourceDownloadUrl" = $p.sourceDownloadUrl
                    "description"       = $p.description
                    "headerPictureUrl"  = $p.gameBanner
                    "downloadDate"      = $p.downloadDate
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

# ──────── Phase 3: Cleanse Sidecars ──────────────────────────────────────────────
if ($Cleanse) {
    Write-Host "Cleansing existing Discord metadata sidecars..." -ForegroundColor Cyan
    $sidecars = Get-ChildItem -Path $DownloadDir -Filter "*.zip.json"
    $cCount = 0
    foreach ($s in $sidecars) {
        $p = Get-Content $s.FullName -Raw | ConvertFrom-Json
        $changed = $false

        # Fix missing downloadDate
        if (-not $p.downloadDate) {
            $p | Add-Member -MemberType NoteProperty -Name "downloadDate" -Value (Get-ISO8601Now)
            $changed = $true
        }

        # Fix stale gameBanner field
        if ($p.PSObject.Properties.Name -contains "gameBanner") {
            if ($null -ne $p.gameBanner) {
                $p | Add-Member -MemberType NoteProperty -Name "headerPictureUrl" -Value $p.gameBanner -Force
            }
            $p.PSObject.Properties.Remove("gameBanner")
            $changed = $true
        }

        # Fix modifiedDate existence
        if ($p.PSObject.Properties.Name -contains "modifiedDate") {
            $p.PSObject.Properties.Remove("modifiedDate")
            $changed = $true
        }

        if ($changed) {
            $cleanedJson = ConvertTo-Json -InputObject $p
            $cleanedJson | Set-Content $s.FullName -Encoding utf8
            $cCount++
        }
    }
    Write-Host "  [OK] Cleansed $cCount sidecars." -ForegroundColor Green
}

Finalize-GlobalTracking
