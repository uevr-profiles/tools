using module "..\common.psm1"
using module ".\UpdateSource.psm1"
using module ".\ProfileMetadata.psm1"

class DiscordSource : UpdateSource {
    [string]$BotDir
    [string]$ProfilesCsv
    [string]$BotStateJson

    DiscordSource([hashtable]$params) : base("discord", $params) {
        $this.BotDir       = Join-Path $PSScriptRoot "..\discord-bot"
        $this.ProfilesCsv  = Join-Path $Global:MetaCacheDir "discord_profiles.csv"
        $this.BotStateJson = Join-Path $Global:MetaCacheDir "bot_state.json"
    }

    [void] Fetch() {
        Write-Host "Running Discord bot scraper to fetch profile metadata (Limit: $($this.ProfileLimit))..." -ForegroundColor Cyan
        
        if (-not (Test-Path (Join-Path $this.BotDir "node_modules"))) {
            Write-Host "Installing bot dependencies..." -ForegroundColor Gray
            Push-Location $this.BotDir
            npm install
            Pop-Location
        }

        $env:PROFILES_JSON   = $this.MetadataJson
        $env:PROFILES_CSV    = $this.ProfilesCsv
        $env:BOT_STATE_JSON  = $this.BotStateJson

        $limitArg = if ($this.ProfileLimit -ne [int]::MaxValue) { "--limit=$($this.ProfileLimit)" } else { "" }
        $cmd = "node index.js $limitArg"
        
        Push-Location $this.BotDir
        Invoke-Expression $cmd
        Pop-Location
    }

    [void] Download() {
        if (-not (Test-Path $this.MetadataJson)) {
            Write-Error "Discord metadata not found at $($this.MetadataJson). Run with -Fetch first."
            return
        }

        $profiles = Get-Content $this.MetadataJson -Raw | ConvertFrom-Json
        Write-Host "Downloading profiles from Discord metadata..." -ForegroundColor Cyan
        
        $count = 0
        $failCount = 0
        foreach ($p in $profiles) {
            if ($count -ge $this.ProfileLimit) { break }
            if ($failCount -ge 5) { Write-Error "Too many consecutive failures. Skipping remaining."; break }

            $uuid = Get-OrCreateUUID $p
            $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

            $targetFile = Join-Path $this.DownloadDir "$uuid.zip"
            $sidecar    = $targetFile + ".json"

            if (-not (Test-Path $targetFile)) {
                Write-Host "[$($count+1)/$($profiles.Count)] Downloading: $($p.gameName) ($($p.zipName))..." -ForegroundColor Gray
                try {
                    Invoke-WebRequestWithRetry -url $p.sourceDownloadUrl -targetFile $targetFile -Silent $this.Silent
                    $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                    $count++
                    $failCount = 0
                    Write-Host "  [OK] Download successful." -ForegroundColor Green
                } catch {
                    Write-Host "  [!] Download failed: $($_.Exception.Message)" -ForegroundColor Red
                    $failCount++
                    if (-not $this.Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
                }
            }
        }
    }

    [void] Extract() {
        $archiveroots = Get-ChildItem -Path $this.DownloadDir -Filter "*.zip"
        Write-Host "Processing $($archiveroots.Count) profiles from $($this.SourceName)... (Limit: $($this.ProfileLimit))" -ForegroundColor Cyan

        $eCount = 0
        foreach ($archiveroot in $archiveroots) {
            if ($eCount -ge $this.ProfileLimit) { break }
            try {
                $eCount++
                $sidecar = $archiveroot.FullName + ".json"
                if (-not (Test-Path $sidecar)) { continue }
                $p = Get-Content $sidecar -Raw | ConvertFrom-Json

                $zipHash = Get-FileHashMD5 $archiveroot.FullName
                $extracted_archives = Extract-And-Discover-Profiles $archiveroot.FullName $this.Whitelist $this.Blacklist
                
                foreach ($extracted_archive in $extracted_archives) {
                    $profile = $extracted_archive.Profile
                    $tempDir = $extracted_archive.Path
                    $uuid = $p.uuid

                    $targetDir = Join-Path $Global:ProfilesDir $uuid
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

                    # Handle Tags
                    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                    $hTags = Get-HeuristicTags $targetDir $meta $profile
                    if ($hTags) { foreach ($t in $hTags) { $tagSet.Add($t) | Out-Null } }

                    $tagArray = [System.Collections.Generic.List[string]]::new($tagSet)
                    $category = if ($p.category) { $p.category.Replace("ue-", "").Replace("nsfw", "NSFW").Trim() } else { "" }
                    if ($category -and $category -ne "games") {
                       if ($category -eq "experiences") { $category = "Experiences" }
                       if ($category -and -not ($tagArray -contains $category)) { $tagArray.Add($category) }
                    }
                    if ($tagArray.Count -gt 0) { $meta.tags = @($tagArray) }

                    $meta.Save($targetDir, $archiveroot.FullName, $profile)

                    if (-not $this.Silent) {
                        Print-ProfileInfo $meta $archiveroot.FullName $profile
                    }
                }
            } catch {
                Write-Host "  [!] Extraction failed for $($archiveroot.Name): $($_.Exception.Message)" -ForegroundColor Red
                if (-not $this.Silent) { throw "Fatal: Profile processing error for $($archiveroot.Name). Stopping because -Silent is not set." }
            }
        }
    }
}
