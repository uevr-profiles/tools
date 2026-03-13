using module "..\common.psm1"
using module ".\UpdateSource.psm1"
using module ".\ProfileMetadata.psm1"

class UEVRDeluxeSource : UpdateSource {
    [string]$ProfilesUrlBase
    [string]$AllProfilesUrl

    UEVRDeluxeSource([hashtable]$params) : base("uevrdeluxe.org", $params) {
        $this.ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"
        $this.AllProfilesUrl  = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"
    }

    [void] Fetch() {
        Write-Host "Fetching all metadata from UEVR Deluxe API..." -ForegroundColor Cyan
        try {
            $headers = @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" }
            $allProfiles = Invoke-RestMethod -Uri $this.AllProfilesUrl -Headers $headers -ErrorAction Stop
            $allProfiles | ConvertTo-Json -Depth 10 | Set-Content $this.MetadataJson -Encoding utf8
            Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
        } catch {
            Write-Warning "Deluxe API failed. Falling back to cached metadata."
            if (-not (Test-Path $this.MetadataJson)) { throw "No metadata cache found. Cannot continue." }
        }
    }

    [void] Download() {
        if (-not (Test-Path $this.MetadataJson)) {
            Write-Error "Metadata not found at $($this.MetadataJson). Run with -Fetch first."
            return
        }

        $profiles = Get-Content $this.MetadataJson -Raw | ConvertFrom-Json
        $count = 0
        $failCount = 0
        $total = $profiles.Count
        $index = 0
        foreach ($p in $profiles) {
            $index++
            if ($count -ge $this.ProfileLimit) { break }
            if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $($this.SourceName). Stopping."; break }
            
            $uuid = Get-OrCreateUUID $p
            $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

            $actualExe = if ($p.exeName) { $p.exeName } else { $p.exename }
            if (-not $uuid -or -not $actualExe) { continue }
            
            $targetFile = Join-Path $this.DownloadDir "$uuid.zip"
            $sidecar    = $targetFile + ".json"
            
            if (-not (Test-Path $targetFile)) {
                $encodedExe = $actualExe -replace ' ', '%20'
                $url = "$($this.ProfilesUrlBase)/$encodedExe/$uuid"
                Write-Host "[$index/$total] Downloading $($p.gameName) ($actualExe) from $url..." -ForegroundColor Gray

                try {
                    Invoke-WebRequestWithRetry -url $url -targetFile $targetFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent $this.Silent
                    
                    $dates = Get-MetadataDates $p
                    $sidecarObj = [ordered]@{
                        "authorName"   = $p.authorName
                        "gameName"     = $p.gameName
                        "exeName"      = $p.exeName
                        "modifiedDate" = $dates.Modified
                        "createdDate"  = $dates.Created
                        "sourceUrl"    = $url
                        "sourceDownloadUrl" = $url
                        "description"  = $p.remarks
                        "uuid"         = $uuid
                    }
                    $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                    $count++
                    $failCount = 0
                    Write-Host "  [OK] Download successful." -ForegroundColor Green
                } catch {
                    Write-Host "  [!] All download attempts failed: $($_.Exception.Message)" -ForegroundColor Red
                    $failCount++
                    if (-not $this.Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
                }
            }
        }
    }

    [void] Extract() {
        $archiveroots = Get-ChildItem -Path $this.DownloadDir -Filter "*.zip"
        Write-Host "Processing $($archiveroots.Count) profiles from $($this.SourceName)..." -ForegroundColor Cyan

        foreach ($archiveroot in $archiveroots) {
            try {
                $sidecar = $archiveroot.FullName + ".json"
                if (-not (Test-Path $sidecar)) { continue }
                $extraMeta = Get-Content $sidecar -Raw | ConvertFrom-Json
                $uuid = $extraMeta.uuid

                $zipHash = Get-FileHashMD5 $archiveroot.FullName
                $extracted_archives = Extract-And-Discover-Profiles $archiveroot.FullName $this.Whitelist $this.Blacklist
                
                foreach ($extracted_archive in $extracted_archives) {
                    $profile = $extracted_archive.Profile
                    $tempDir = $extracted_archive.Path
                    
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
                    $meta.exeName           = $extraMeta.exeName
                    $meta.gameName          = $extraMeta.gameName
                    $meta.authorName        = $extraMeta.authorName
                    $meta.modifiedDate      = Format-ISO8601Date $extraMeta.modifiedDate
                    $meta.createdDate       = Format-ISO8601Date $extraMeta.createdDate
                    $meta.sourceName        = "uevrdeluxe.org"
                    $meta.sourceUrl         = $extraMeta.sourceUrl
                    $meta.sourceDownloadUrl = $extraMeta.sourceDownloadUrl
                    $meta.description       = $extraMeta.description
                    $meta.downloadDate      = Get-ISO8601Now
                    $meta.zipHash           = $zipHash.ToUpper()
                    $meta.downloadUrl       = Get-ProfileDownloadUrl $uuid $extraMeta.exeName

                    # Handle Tags
                    $tagArray = @(Get-HeuristicTags $targetDir $meta $profile)
                    if ($tagArray -and $tagArray.Count -gt 0) { $meta.tags = $tagArray }

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
