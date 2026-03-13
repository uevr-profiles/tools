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

$SourceName   = "uevrdeluxe.org"
$SourceTempDir = Join-Path $BaseTempDir $SourceName
$DownloadDir   = Join-Path $SourceTempDir "downloads"
$MetadataJson  = Join-Path $SourceTempDir "cache.json"

$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"
$AllProfilesUrl  = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"

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

function Invoke-DeluxeRequest($url) {
    # Stealthy headers mimicking the official Deluxe client behavior
    $headers = @{
        "User-Agent" = "UEVRDeluxe"
        "Accept"     = "application/json"
    }
    return Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
}

function Fetch-UEVRDeluxeMetadata {
    Write-Host "Fetching all metadata from UEVR Deluxe API..." -ForegroundColor Cyan
    try {
        $allProfiles = Invoke-DeluxeRequest $AllProfilesUrl
        $allProfiles | ConvertTo-Json -Depth 10 | Set-Content $MetadataJson -Encoding utf8
        Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
    } catch {
        Write-Warning "Deluxe API failed (Internal Server Error is common). Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }
}

function Download-UEVRDeluxeProfiles {
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
        
        $uuid = Get-OrCreateUUID $p
        $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

        $actualExe = if ($p.exeName) { $p.exeName } else { $p.exename }
        if (-not $uuid -or -not $actualExe) { continue }
        
        # Deluxe zip naming: <uuid>.zip
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"
        
        if (-not (Test-Path $targetFile)) {
            $encodedExe = $actualExe -replace ' ', '%20'
            $url = "$ProfilesUrlBase/$encodedExe/$uuid"
            
            $msg = "[$index/$total] Downloading $($p.gameName)"
            if ($actualExe) { $msg += " ($actualExe)" }
            Write-Host "$msg from $url..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $url -targetFile $targetFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent $Silent
                
                # Standardize Sidecar Metadata
                $dates = Get-MetadataDates $p
                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $actualExe
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "modifiedDate"      = Format-ISO8601Date $dates.Modified
                    "createdDate"       = Format-ISO8601Date $dates.Created
                    "sourceName"        = "uevrdeluxe.org"
                    "sourceUrl"         = $url
                    "sourceDownloadUrl" = $url
                    "description"       = $p.remarks
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $actualExe
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

function Extract-UEVRDeluxeProfiles {
    Write-Host "Extracting archives from $SourceName..." -ForegroundColor Cyan
    Extract-ArchivesFolder $DownloadDir -Silent:$Silent
}

# ──────── Main Logic Entry ────────────────────────────────────────────────────
$ExpectedCount = if ($ProfileLimit -ne [int]::MaxValue) { $ProfileLimit } else { [int]::MaxValue }

if ($Fetch) { 
    Fetch-UEVRDeluxeMetadata
    $data = if (Test-Path $MetadataJson) { Get-Content $MetadataJson -Raw | ConvertFrom-Json } else { @() }
    $actual = $data.Count
    if ($ProfileLimit -ne [int]::MaxValue -and $actual -lt $ProfileLimit) {
        $msg = "UEVRDeluxe fetch count mismatch. Expected at least $ProfileLimit, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
    $ExpectedCount = [Math]::Min($ExpectedCount, $actual)
}

if ($Download) { 
    Download-UEVRDeluxeProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    $actual = $zips.Count
    if ($ExpectedCount -ne [int]::MaxValue -and $actual -lt $ExpectedCount) {
        $msg = "UEVRDeluxe download count mismatch. Expected at least $ExpectedCount, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
    $ExpectedCount = [Math]::Min($ExpectedCount, $actual)
}

if ($Extract) { 
    Extract-UEVRDeluxeProfiles 
    $processed = Get-ChildItem -Path $ProfilesDir -Directory | Where-Object { (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) }
    $profileIds = $processed | ForEach-Object { (Get-Content (Join-Path $_.FullName "ProfileMeta.json") -Raw | ConvertFrom-Json).ID } | Select-Object -Unique
    $actual = $profileIds.Count
    if ($ExpectedCount -ne [int]::MaxValue -and $actual -lt $ExpectedCount) {
        $msg = "UEVRDeluxe extraction ID count mismatch. Expected at least $ExpectedCount unique profile IDs, got $actual."
        if ($Silent) { Write-Warning $msg } else { throw "Fatal: $msg" }
    }
}
