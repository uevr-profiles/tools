param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$Cleanse
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
    Write-Host "Running Discord bot scraper to fetch profile metadata (Limit: $ProfileLimit)..." -ForegroundColor Cyan
    
    # Check for node_modules
    if (-not (Test-Path (Join-Path $BotDir "node_modules"))) {
        Write-Host "Installing bot dependencies..." -ForegroundColor Gray
        Push-Location $BotDir
        npm install
        Pop-Location
    }

    $limitArg = if ($ProfileLimit -ne [int]::MaxValue) { "--limit $ProfileLimit" } else { "" }
    $cmd = "node index.js $limitArg"
    
    Push-Location $BotDir
    Invoke-Expression $cmd
    Pop-Location
}

# ──────── Phase 1: Downloads ──────────────────────────────────────────────────
if ($Download) {
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

# ──────── Phase 2: Extraction & Integration ────────────────────────────────────
if ($Extract) {
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

        if ($changed) {
            $p | ConvertTo-Json | Set-Content $s.FullName -Encoding utf8
            $cCount++
        }
    }
    Write-Host "Cleansed $cCount metadata sidecars." -ForegroundColor Green
}
