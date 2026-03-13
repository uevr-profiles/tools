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

$SourceName   = "uevr-profiles.com"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$MetadataJson  = Join-Path $SourceTempDir "cache.json"

$FirestoreUrl = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"

if ($CleanCache -and (Test-Path $MetadataJson)) {
    Write-Host "Cleaning cache for $SourceName..." -ForegroundColor Yellow
    Remove-Item $MetadataJson -Force
}
if ($CleanDownloads -and (Test-Path $DownloadDir)) {
    Write-Host "Cleaning downloads for $SourceName..." -ForegroundColor Yellow
    Remove-Item $DownloadDir -Recurse -Force
}

foreach ($d in @($SourceTempDir, $DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Invoke-ProfileRequest($url) {
    # Stealthy headers mimicking modern client
    $headers = @{ "Accept" = "application/json" }
    return Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
}

function Fetch-UEVRProfilesMetadata {
    Write-Host "Fetching all metadata from Firestore..." -ForegroundColor Cyan
    try {
        $meta = Invoke-ProfileRequest $FirestoreUrl
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

                $profileExe = if ($vf.exeName.stringValue) { $vf.exeName.stringValue } else { "" }
                $encodedArchive = [uri]::EscapeDataString("profiles/$archiveFile")
                $dlUrl = "https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/$($encodedArchive)?alt=media"

                $obj = @{
                    "id"           = $profileId
                    "gameName"     = $gameName
                    "authorName"   = $vf.author.stringValue
                    "modifiedDate" = $vf.creationDate.timestampValue
                    "createdDate"  = $vf.creationDate.timestampValue
                    "exeName"      = if ($profileExe) { $profileExe } elseif ($topExe) { $topExe } else { $archiveFile.Replace(".zip", "") }
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

function Download-UEVRProfiles {
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
                
                # Standardize Sidecar Metadata
                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $p.exeName
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "modifiedDate"      = Format-ISO8601Date $p.modifiedDate
                    "createdDate"       = Format-ISO8601Date $p.createdDate
                    "sourceName"        = "uevr-profiles.com"
                    "sourceUrl"         = "https://uevr-profiles.com/game/$($p.id)"
                    "sourceDownloadUrl" = $p.downloadUrl
                    "description"       = $p.description
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $p.exeName
                }
                $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8

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

function Extract-UEVRProfiles {
    Write-Host "Extracting archives from $SourceName..." -ForegroundColor Cyan
    Extract-ArchivesFolder $DownloadDir -Silent:$Silent
}

# ──────── Main Logic Entry ────────────────────────────────────────────────────
$ExpectedCount = if ($ProfileLimit -ne [int]::MaxValue) { $ProfileLimit } else { [int]::MaxValue }

if ($Fetch) { 
    Fetch-UEVRProfilesMetadata
    $data = if (Test-Path $MetadataJson) { Get-Content $MetadataJson -Raw | ConvertFrom-Json } else { @() }
    $actual = $data.Count
    if ($ProfileLimit -ne [int]::MaxValue -and $actual -lt $ProfileLimit) {
        $msg = "Fetch count mismatch: Expected at least $ProfileLimit, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
    $ExpectedCount = [Math]::Min($ExpectedCount, $actual)
}

if ($Download) { 
    Download-UEVRProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    $actual = $zips.Count
    if ($ExpectedCount -ne [int]::MaxValue -and $actual -lt $ExpectedCount) {
        $msg = "Download count mismatch: Expected at least $ExpectedCount, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
    $ExpectedCount = [Math]::Min($ExpectedCount, $actual)
}

if ($Extract) { 
    Extract-UEVRProfiles 
    # Logic for extraction count is tricky due to variations, but we check if we processed all zips
    $processed = Get-ChildItem -Path $ProfilesDir -Directory | Where-Object { (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) }
    # This is a loose check: we expect at least as many profile IDs as we had downloads
    $profileIds = $processed | ForEach-Object { (Get-Content (Join-Path $_.FullName "ProfileMeta.json") -Raw | ConvertFrom-Json).ID } | Select-Object -Unique
    $actual = $profileIds.Count
    if ($ExpectedCount -ne [int]::MaxValue -and $actual -lt $ExpectedCount) {
        $msg = "Extraction ID count mismatch: Expected at least $ExpectedCount unique profile IDs, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
}
