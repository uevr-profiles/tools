#region Parameters
param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$Debug,
    [switch]$CleanCache,
    [switch]$CleanDownloads,
    [string]$Proxies
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$SourceName   = "uevr-profiles.com"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$MetadataJson  = Join-Path $SourceTempDir "cache.json"

$FirestoreUrl = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"

$ExpectedCount = ($ProfileLimit -ne [int]::MaxValue) ? $ProfileLimit : [int]::MaxValue
#endregion

#region Functions
function Invoke-ProfileRequest($url, $Proxies = $null) {
    $tempFile = Join-Path $BaseTempDir "$([guid]::NewGuid()).json"
    try {
        Invoke-WebRequestWithRetry -url $url -targetFile $tempFile -Proxies $Proxies -Silent:$Silent
        if (Test-Path $tempFile) {
            $json = Get-Content $tempFile -Raw | ConvertFrom-Json
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            return $json
        }
    } catch {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        if (-not $Silent) { throw $_ }
    }
}

function Fetch-UEVRProfilesMetadata {
    Write-Host "Fetching all metadata from Firestore..." -ForegroundColor Cyan
    try {
        $meta = Invoke-ProfileRequest $FirestoreUrl -Proxies $Proxies
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
                        if ($lFields.archive.stringValue) { $archiveFile = $lFields.archive.stringValue; break }
                    }
                } catch {}

                $profileExe = $vf.exeName.stringValue ? $vf.exeName.stringValue : ""
                $encodedArchive = [uri]::EscapeDataString("profiles/$archiveFile")
                $dlUrl = "https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/$($encodedArchive)?alt=media"

                $allProfiles += @{
                    "id"           = $profileId
                    "gameName"     = $gameName
                    "authorName"   = $vf.author.stringValue
                    "modifiedDate" = $vf.creationDate.timestampValue
                    "createdDate"  = $vf.creationDate.timestampValue
                    "exeName"      = Get-SafeExeName ($profileExe ? $profileExe : ($topExe ? $topExe : ($archiveFile -replace '\.zip$', '')))
                    "downloadUrl"  = $dlUrl
                    "archive"      = $archiveFile
                    "description"  = $vf.description.stringValue
                }
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
    if (-not (Test-Path $MetadataJson)) { Write-Error "Metadata not found at $MetadataJson. Run with -Fetch first."; return }
    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    $count = 0; $failCount = 0; $total = $profiles.Count; $index = 0
    foreach ($p in $profiles) {
        $index++
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }
        $uuid = Get-OrCreateUUID $p
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"
        
        $safeExe = Get-SafeExeName ($p.exeName ? $p.exeName : $p.gameName)
        
        if (-not (Test-Path $targetFile)) {
            $msg = "[$index/$total] Downloading: $($p.gameName)"
            if ($safeExe) { $msg += " ($($safeExe))" }
            Write-Host "$msg..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $p.downloadUrl -targetFile $targetFile -Silent $Silent -Debug:$Debug -Proxies $Proxies
                
                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $safeExe
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "modifiedDate"      = Format-DateISO8601 $p.modifiedDate
                    "createdDate"       = Format-DateISO8601 $p.createdDate
                    "sourceName"        = "uevr-profiles.com"
                    "sourceUrl"         = "https://uevr-profiles.com/game/$($p.id)"
                    "sourceDownloadUrl" = $p.downloadUrl
                    "description"       = $p.description
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $safeExe
                }
                $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++; $failCount = 0
                Write-Host "  [OK] Download successful." -ForegroundColor Green
            } catch {
                Write-Host "  [!] All download attempts failed: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
            }
        }
    }
}
#endregion

#region Main Logic
Debug-Log "[Update-FromUEVRProfiles.ps1] Main Logic Start"
$Global:Debug = $Debug

# Handle cleanup logic
Debug-Log "[Update-FromUEVRProfiles.ps1] Checking cleanup flags"
if ($CleanCache) {
    if (Test-Path $MetadataJson) {
        Write-Host "Deleting cache for $SourceName..." -ForegroundColor Yellow
        Debug-Log "[Update-FromUEVRProfiles.ps1] Deleting $MetadataJson"
        Remove-Item $MetadataJson -Force -ErrorAction SilentlyContinue
    }
}
if ($CleanDownloads) {
    if (Test-Path $DownloadDir) {
        Write-Host "Deleting downloads for $SourceName..." -ForegroundColor Yellow
        Debug-Log "[Update-FromUEVRProfiles.ps1] Deleting $DownloadDir"
        Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Debug-Log "[Update-FromUEVRProfiles.ps1] Ensuring directories exist"
foreach ($d in @($SourceTempDir, $DownloadDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Fetch) { 
    Debug-Log "[Update-FromUEVRProfiles.ps1] Calling Fetch-UEVRProfilesMetadata"
    Fetch-UEVRProfilesMetadata
    if (Test-Path $MetadataJson) {
        $data = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    } else {
        $data = @()
    }
    Assert-ProfileCount -count $data.Count -expected $ProfileLimit -Silent:$Silent -stage "Fetch"
    $ExpectedCount = [Math]::Min($ExpectedCount, $data.Count)
}

if ($Download) { 
    Debug-Log "[Update-FromUEVRProfiles.ps1] Calling Download-UEVRProfiles"
    Download-UEVRProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Assert-ProfileCount -count $zips.Count -expected $ExpectedCount -Silent:$Silent -stage "Download"
    $ExpectedCount = [Math]::Min($ExpectedCount, $zips.Count)
}

if ($Extract) { 
    Debug-Log "[Update-FromUEVRProfiles.ps1] Calling Extract-ArchivesFolder"
    $extracted = Extract-ArchivesFolder $DownloadDir -Limit $ProfileLimit -Silent:$Silent
    Assert-ProfileCount -count $extracted.Count -expected $ExpectedCount -Silent:$Silent -stage "Extraction ID"
}
Finalize-GlobalTracking
Debug-Log "[Update-FromUEVRProfiles.ps1] Main Logic End"
#endregion
