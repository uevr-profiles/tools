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

# File paths within the metadata cache
$MetadataJson = Join-Path $MetaCacheDir "discord_profiles.json"
$ProfilesCsv  = Join-Path $MetaCacheDir "discord_profiles.csv"
$BotStateJson = Join-Path $MetaCacheDir "bot_state.json"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
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
                $meta.exeName           = if ($p.exeName) { $p.exeName } else { $p.zipName.Replace(".zip", "") }
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
                
                $hTags = Get-HeuristicTags $targetDir $meta $variant
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

                $meta.Save($targetDir, $z.FullName, $variant)

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

# ──────── Main Logic Entry ────────────────────────────────────────────────────
if ($Fetch)    { Fetch-DiscordMetadata }
if ($Download) { Download-DiscordProfiles }
if ($Extract)  { Extract-DiscordProfiles }
