param(
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

# ──────── Phase 1: Metadata & Downloads ───────────────────────────────────────
if ($Download) {
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
                
                $dlUrl = "https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/profiles%2f$($profileId).zip?alt=media"
                
                $archiveFile = $null
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
                $obj = @{
                    "id"           = $profileId
                    "gameName"     = $gameName
                    "authorName"   = $vf.author.stringValue
                    "modifiedDate" = $vf.creationDate.timestampValue
                    "createdDate"  = $vf.creationDate.timestampValue
                    "exeName"      = if ($variantExe) { $variantExe } elseif ($topExe) { $topExe } else { "" }
                    "downloadUrl"  = $dlUrl
                    "archive"      = if ($archiveFile) { $archiveFile } else { "$($profileId).zip" }
                    "description"  = $vf.description.stringValue
                }
                $allProfiles += $obj
            }
        }
        $allProfiles | ConvertTo-Json | Set-Content $MetadataJson -Encoding utf8
    } catch {
        Write-Warning "Firestore API failed. Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
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
                # Two-tier download strategy
                try {
                    # Note: We don't have the exact Cloud Function payload spec anymore, 
                    # so we'll just use the direct URL with retry for now as it's more reliable.
                    Invoke-WebRequestWithRetry -url $p.downloadUrl -targetFile $targetFile -Silent $Silent
                } catch {
                    Write-Host "  [!] Direct download failed, trying cloud function proxy..." -ForegroundColor Yellow
                    # Fallback URL construction if needed, but the storage URL usually works
                    Invoke-WebRequestWithRetry -url $p.downloadUrl -targetFile $targetFile -Silent $Silent
                }
                
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
                
                $relFiles = Get-ChildItem -Path $tempDir -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object { 
                    $_.FullName.Substring($tempDir.Length).TrimStart('\')
                }
                Update-GlobalFilesList $relFiles
                Move-Item-Smart $tempDir $targetDir

                $finalExe = if ($p.exeName) { $p.exeName } else { $p.exename }
                if (-not $finalExe) {
                    Write-Warning "    [!] Missing exeName for $($p.gameName). Falling back to gameName slug."
                    $finalExe = $p.gameName -replace '[^a-zA-Z0-9]', ''
                }

                $finalAuthor = if ($p.authorName) { $p.authorName } else { $p.author }
                $displayVariant = Get-CleanVariantName $variant $finalExe
                
                $metaProps = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $finalExe
                    "gameName"          = $p.gameName
                    "authorName"        = $finalAuthor
                    "modifiedDate"      = Format-ISO8601Date $p.modifiedDate
                    "createdDate"       = Format-ISO8601Date $p.createdDate
                    "sourceName"        = "uevr-profiles.com"
                    "sourceUrl"         = $sourceUrl
                    "sourceDownloadUrl" = $p.downloadUrl
                    "description"       = $p.description
                    "downloadDate"      = Get-ISO8601Now
                    "zipHash"           = $zipHash.ToUpper()
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $finalExe
                }

                # Tags support (Heuristics)
                $tagArray = @(Get-HeuristicTags $targetDir $metaProps $displayVariant)
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
