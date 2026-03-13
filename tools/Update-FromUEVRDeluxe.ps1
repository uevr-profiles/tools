param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [switch]$Delete,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent,
    [switch]$CleanCache,
    [switch]$CleanDownloads
)

. "$PSScriptRoot\common.ps1"

$SourceName   = "uevrdeluxe.org"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$MetadataJson  = Join-Path $SourceTempDir "cache.json"

$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"
$AllProfilesUrl  = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"

# Handle cleanup logic
if ($Delete -or $CleanCache) {
    if (Test-Path $MetadataJson) {
        Write-Host "Deleting cache for $SourceName..." -ForegroundColor Yellow
        Remove-Item $MetadataJson -Force -ErrorAction SilentlyContinue
    }
}
if ($Delete -or $CleanDownloads) {
    if (Test-Path $DownloadDir) {
        Write-Host "Deleting downloads for $SourceName..." -ForegroundColor Yellow
        Remove-Item $DownloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

foreach ($d in @($SourceTempDir, $DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

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
        $actualExe = if ($p.exeName) { $p.exeName } else { $p.exename }
        if (-not $uuid -or -not $actualExe) { continue }
        
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"
        
        if (-not (Test-Path $targetFile)) {
            $url = "$ProfilesUrlBase/$(($actualExe -replace ' ', '%20'))/$uuid"
            Write-Host "[$index/$total] Downloading $($p.gameName) ($actualExe)..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $url -targetFile $targetFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent $Silent
                
                # Inline date extraction
                $modDate = if ($p.modifiedDate) { $p.modifiedDate } elseif ($p.updatedAt) { $p.updatedAt } else { $null }
                $creDate = if ($p.createdDate) { $p.createdDate } elseif ($p.createdAt) { $p.createdAt } else { $modDate }

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

# ──────── Main Logic Entry ────────────────────────────────────────────────────
$ExpectedCount = if ($ProfileLimit -ne [int]::MaxValue) { $ProfileLimit } else { [int]::MaxValue }

if ($Fetch) { 
    Fetch-UEVRDeluxeMetadata
    $data = if (Test-Path $MetadataJson) { Get-Content $MetadataJson -Raw | ConvertFrom-Json } else { @() }
    Assert-ProfileCount -count $data.Count -expected $ProfileLimit -Silent:$Silent -stage "Fetch"
    $ExpectedCount = [Math]::Min($ExpectedCount, $data.Count)
}

if ($Download) { 
    Download-UEVRDeluxeProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Assert-ProfileCount -count $zips.Count -expected $ExpectedCount -Silent:$Silent -stage "Download"
    $ExpectedCount = [Math]::Min($ExpectedCount, $zips.Count)
}

if ($Extract) { 
    Extract-ArchivesFolder $DownloadDir -Silent:$Silent
    $processed = Get-ChildItem -Path $ProfilesDir -Directory | Where-Object { (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) }
    $profileIds = $processed | ForEach-Object { (Get-Content (Join-Path $_.FullName "ProfileMeta.json") -Raw | ConvertFrom-Json).ID } | Select-Object -Unique
    Assert-ProfileCount -count $profileIds.Count -expected $ExpectedCount -Silent:$Silent -stage "Extraction ID"
}
