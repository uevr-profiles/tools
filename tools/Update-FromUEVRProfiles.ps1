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

$SourceName  = "uevr-profiles.com"
$DownloadDir = Join-Path $BaseTempDir $SourceName
$MetadataJson = Join-Path $MetaCacheDir "uevrprofiles_allmetadata.json"

$FirestoreUrl = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Invoke-ProfileRequest($url) {
    # Stealthy headers mimicking modern client
    $headers = @{ "Accept" = "application/json" }
    return Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
}

# ──────── Phase 0: Metadata Fetch ───────────────────────────────────────────
if ($Fetch) {
    Write-Host "Fetching all metadata from Firestore..." -ForegroundColor Cyan
    try {
        $meta = Invoke-ProfileRequest $FirestoreUrl
        $allProfiles = @()
        foreach ($doc in $meta.documents) {
            $gameName = $doc.fields.gameName.stringValue
            $topExe   = $doc.fields.exeName.stringValue
            
            $variants = $doc.fields.profiles.arrayValue.values
            if (-not $variants) { continue }
            
            foreach ($v in $variants) {
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

                $variantExe = if ($vf.exeName.stringValue) { $vf.exeName.stringValue } else { "" }
                $encodedArchive = [uri]::EscapeDataString("profiles/$archiveFile")
                $dlUrl = "https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/$($encodedArchive)?alt=media"

                $obj = @{
                    "id"           = $profileId
                    "gameName"     = $gameName
                    "authorName"   = $vf.author.stringValue
                    "modifiedDate" = $vf.creationDate.timestampValue
                    "createdDate"  = $vf.creationDate.timestampValue
                    "exeName"      = if ($variantExe) { $variantExe } elseif ($topExe) { $topExe } else { "" }
                    "downloadUrl"  = $dlUrl
                    "archive"      = $archiveFile
                    "description"  = $vf.description.stringValue
                }
                $allProfiles += $obj
            }
        }
        $allProfiles | ConvertTo-Json | Set-Content $MetadataJson -Encoding utf8
        Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
    } catch {
        Write-Warning "Firestore API failed: $($_.Exception.Message)"
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }
}

# ──────── Phase 1: Downloads ──────────────────────────────────────────────────
if ($Download) {
    if (-not (Test-Path $MetadataJson)) {
        Write-Error "Metadata not found at $MetadataJson. Run with -Fetch first."
        return
    }

    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    $count = 0
    $failCount = 0
    $total = $profiles.Count
    $index = 0
    foreach ($p in $profiles) {
        $index++
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }

        # Assign UUID based on sourceUrl + archive
        $uuid = Get-OrCreateUUID $p
        $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"
        
        if (-not (Test-Path $targetFile)) {
            $msg = "[$index/$total] Downloading: $($p.gameName)"
            if ($p.exeName) { $msg += " ($($p.exeName))" }
            Write-Host "$msg..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $p.downloadUrl -targetFile $targetFile -Silent $Silent
                
                $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++
                $failCount = 0
                Write-Host "  [OK] Download successful." -ForegroundColor Green
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
            $sourceUrl = "https://uevr-profiles.com/game/$($p.id)"
            
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

                # Handle Tags (Heuristics only for uevr-profiles)
                $tagArray = @(Get-HeuristicTags $targetDir $meta $variant)
                if ($tagArray -and $tagArray.Count -gt 0) {
                    $meta.tags = $tagArray
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
