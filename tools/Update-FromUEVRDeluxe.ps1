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
    [switch]$CleanDownloads
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$SourceName   = "uevrdeluxe.org"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$MetadataJson  = Join-Path $SourceTempDir "cache.json"

$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"
$AllProfilesUrl  = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"

$ExpectedCount = ($ProfileLimit -ne [int]::MaxValue) ? $ProfileLimit : [int]::MaxValue
#endregion

#region Functions
function Invoke-DeluxeRequest($url) {
    $headers = @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" }
    return Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
}

function Fetch-UEVRDeluxeMetadata {
    Write-Host "Fetching all metadata from UEVR Deluxe API..." -ForegroundColor Cyan
    try {
        $allProfiles = Invoke-DeluxeRequest $AllProfilesUrl
        $allProfiles | ConvertTo-Json -Depth 10 | Set-Content $MetadataJson -Encoding utf8
        Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
    } catch {
        Write-Warning "Deluxe API failed. Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }
}

function Download-UEVRDeluxeProfiles {
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
        
        $exeName = ""
        if ($p.exeName) {
            $exeName = $p.exeName
        } else {
            $exeName = $p.zipName.Replace(".zip", "")
        }
        
        if (-not (Test-Path $targetFile)) {
            $url = "$ProfilesUrlBase/$(($exeName -replace ' ', '%20'))/$uuid"
            Write-Host "[$index/$total] Downloading $($p.gameName) ($exeName)..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $url -targetFile $targetFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent $Silent
                
                # Inline date extraction
                $modDate = $p.modifiedDate ? $p.modifiedDate : ($p.updatedAt ? $p.updatedAt : $null)
                $creDate = $p.createdDate ? $p.createdDate : ($p.createdAt ? $p.createdAt : $modDate)

                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $actualExe
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "modifiedDate"      = Format-DateISO8601 $modDate
                    "createdDate"       = Format-DateISO8601 $creDate
                    "sourceName"        = "uevrdeluxe.org"
                    "sourceUrl"         = $url
                    "sourceDownloadUrl" = $url
                    "description"       = $p.remarks
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $actualExe
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
Debug-Log "[Update-FromUEVRDeluxe.ps1] Main Logic Start"
$Global:Debug = $Debug

# Handle cleanup logic
Debug-Log "[Update-FromUEVRDeluxe.ps1] Checking cleanup flags"
if ($CleanCache) {
    if (Test-Path $MetadataJson) {
        Write-Host "Deleting cache for $SourceName..." -ForegroundColor Yellow
        Debug-Log "[Update-FromUEVRDeluxe.ps1] Deleting $MetadataJson"
        Remove-Item $MetadataJson -Force -ErrorAction SilentlyContinue
    }
}
if ($CleanDownloads) {
    if (Test-Path $DownloadDir) {
        Write-Host "Deleting downloads for $SourceName..." -ForegroundColor Yellow
        Debug-Log "[Update-FromUEVRDeluxe.ps1] Deleting $DownloadDir"
        Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Debug-Log "[Update-FromUEVRDeluxe.ps1] Ensuring directories exist"
foreach ($d in @($SourceTempDir, $DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Fetch) { 
    Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Fetch-UEVRDeluxeMetadata"
    Fetch-UEVRDeluxeMetadata
    if (Test-Path $MetadataJson) {
        $data = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    } else {
        $data = @()
    }
    Assert-ProfileCount -count $data.Count -expected $ProfileLimit -Silent:$Silent -stage "Fetch"
    $ExpectedCount = [Math]::Min($ExpectedCount, $data.Count)
}

if ($Download) { 
    Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Download-UEVRDeluxeProfiles"
    Download-UEVRDeluxeProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Assert-ProfileCount -count $zips.Count -expected $ExpectedCount -Silent:$Silent -stage "Download"
    $ExpectedCount = [Math]::Min($ExpectedCount, $zips.Count)
}

if ($Extract) { 
    Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Extract-ArchivesFolder"
    Extract-ArchivesFolder $DownloadDir -Silent:$Silent
    $processed = Get-ChildItem -Path $ProfilesDir -Directory | Where-Object { (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) }
    $profileIds = $processed | ForEach-Object { (Get-Content (Join-Path $_.FullName "ProfileMeta.json") -Raw | ConvertFrom-Json).ID } | Select-Object -Unique
    Assert-ProfileCount -count $profileIds.Count -expected $ExpectedCount -Silent:$Silent -stage "Extraction ID"
}
Debug-Log "[Update-FromUEVRDeluxe.ps1] Main Logic End"
#endregion
