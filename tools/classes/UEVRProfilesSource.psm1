using module "..\common.psm1"
using module ".\UpdateSource.psm1"
using module ".\ProfileMetadata.psm1"

class UEVRProfilesSource : UpdateSource {
    [string]$FirestoreUrl
    [string]$DownloadFuncUrl

    UEVRProfilesSource([hashtable]$params) : base("uevr-profiles.com", $params) {
        $this.FirestoreUrl = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
        $this.DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"
    }

    [void] Fetch() {
        Write-Host "Fetching all metadata from Firestore..." -ForegroundColor Cyan
        try {
            $headers = @{ "Accept" = "application/json" }
            $meta = Invoke-RestMethod -Uri $this.FirestoreUrl -Headers $headers -ErrorAction Stop
            
            $allProfiles = @()
            foreach ($doc in $meta.documents) {
                $gameName = $doc.fields.gameName.stringValue
                $topExe   = $doc.fields.exeName.stringValue
                
                $profiles = $doc.fields.profiles.arrayValue.values
                if (-not $profiles) { continue }
                
                foreach ($v in $profiles) {
                    $vf = $v.mapValue.fields
                    $profileId = $vf.id.stringValue
                    if (-not $profileId) { continue }
                    
                    $archiveFile = "$($profileId).zip"
                    try {
                        $links = $vf.links.arrayValue.values
                        foreach ($linkObj in $links) {
                            $lFields = $linkObj.mapValue.fields
                            if ($lFields.archive.stringValue) {
                                $archiveFile = $lFields.archive.stringValue
                                break
                            }
                        }
                    } catch {}

                    $profileExe = if ($vf.exeName.stringValue) { $vf.exeName.stringValue } elseif ($topExe) { $topExe } else { "" }
                    $encodedArchive = [uri]::EscapeDataString("profiles/$archiveFile")
                    $dlUrl = "https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/$($encodedArchive)?alt=media"

                    $obj = @{
                        "id"           = $profileId
                        "gameName"     = $gameName
                        "authorName"   = $vf.author.stringValue
                        "modifiedDate" = $vf.creationDate.timestampValue
                        "createdDate"  = $vf.creationDate.timestampValue
                        "exeName"      = $(if ($profileExe) { $profileExe } else { $archiveFile.Replace(".zip", "") })
                        "downloadUrl"  = $dlUrl
                        "archive"      = $archiveFile
                        "description"  = $vf.description.stringValue
                    }
                    $allProfiles += $obj
                }
            }
            $allProfiles | ConvertTo-Json | Set-Content $this.MetadataJson -Encoding utf8
            Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
        } catch {
            Write-Warning "Firestore API failed: $($_.Exception.Message)"
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

            $targetFile = Join-Path $this.DownloadDir "$uuid.zip"
            $sidecar    = $targetFile + ".json"
            
            if (-not (Test-Path $targetFile)) {
                $msg = "[$index/$total] Downloading: $($p.gameName)"
                if ($p.exeName) { $msg += " ($($p.exeName))" }
                Write-Host "$msg..." -ForegroundColor Gray

                try {
                    Invoke-WebRequestWithRetry -url $p.downloadUrl -targetFile $targetFile -Silent $this.Silent
                    
                    $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
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
                $p = Get-Content $sidecar -Raw | ConvertFrom-Json

                $zipHash = Get-FileHashMD5 $archiveroot.FullName
                $sourceUrl = "https://uevr-profiles.com/game/$($p.id)"
                
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
                    $meta.exeName           = $p.exeName
                    $meta.gameName          = $p.gameName
                    $meta.authorName        = $p.authorName
                    $meta.modifiedDate      = Format-ISO8601Date $p.modifiedDate
                    $meta.createdDate       = Format-ISO8601Date $p.createdDate
                    $meta.sourceName        = "uevr-profiles.com"
                    $meta.sourceUrl         = $sourceUrl
                    $meta.sourceDownloadUrl = $p.downloadUrl
                    $meta.description       = $p.description
                    $meta.downloadDate      = Get-ISO8601Now
                    $meta.zipHash           = $zipHash.ToUpper()
                    $meta.downloadUrl       = Get-ProfileDownloadUrl $uuid $p.exeName

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
