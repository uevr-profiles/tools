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
    [switch]$UseProxies,
    [switch]$UseTailscale
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

if ($ProfileLimit -ne [int]::MaxValue) {
    $ExpectedCount = $ProfileLimit
} else {
    $ExpectedCount = [int]::MaxValue
}
#endregion

#region Functions
function Invoke-DeluxeRequest($url, $Proxies = $null) {
    $tempFile = Join-Path $env:TEMP "$([guid]::NewGuid()).json"
    try {
        Invoke-WebRequestWithRetry -url $url -targetFile $tempFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent:$Silent -Proxies:$Proxies
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

function Fetch-UEVRDeluxeMetadata {
    Write-Host "Fetching all metadata from UEVR Deluxe API..." -ForegroundColor Cyan
    try {
        $allProfiles = Invoke-DeluxeRequest $AllProfilesUrl -Proxies $Proxies
        $allProfiles | ConvertTo-Json -Depth 10 | Set-Content $MetadataJson -Encoding utf8
        Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
    } catch {
        Write-Warning "Deluxe API failed. Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }
}

function Download-UEVRDeluxeProfiles {
    $profiles = Load-ProfilesFromFile $MetadataJson
    $count = 0; $failCount = 0; $total = $profiles.Count; $index = 0
    foreach ($p in $profiles) {
        $index++
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }
        
        $uuid = Get-OrCreateUUID $p
        $uuidClean = ([guid]$uuid).ToString("n")
        $rawExe  = $p.exeName
        $safeExe = Get-SafeExeName $rawExe
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"
        
        Debug-Log "[Update-FromUEVRDeluxe.ps1] ID: $uuid, Raw: $rawExe, Safe: $safeExe"

        if (-not (Test-Path $targetFile)) {
            $url = "$ProfilesUrlBase/$([uri]::EscapeDataString($rawExe))/$uuidClean"
            Write-Host "[$index/$total] Downloading $($p.gameName) ($safeExe)..." -ForegroundColor Gray

            try {
                Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Invoke-WebRequestWithRetry: $url"
                Invoke-WebRequestWithRetry -url $url -targetFile $targetFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent $Silent -Proxies $Proxies
                
                # Use centralized date formatting
                if ($p.modifiedDate) {
                    $modDate = $p.modifiedDate
                } else {
                    if ($p.updatedAt) {
                        $modDate = $p.updatedAt
                    } else {
                        $modDate = $null
                    }
                }
                
                if ($p.createdDate) {
                    $creDate = $p.createdDate
                } else {
                    if ($p.createdAt) {
                        $creDate = $p.createdAt
                    } else {
                        $creDate = $modDate
                    }
                }

                Debug-Log "[Update-FromUEVRDeluxe.ps1] Creating sidecar with author: $($p.authorName)"
                $sidecarObj = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $safeExe
                    "gameName"          = $p.gameName
                    "authorName"        = $p.authorName
                    "modifiedDate"      = Format-DateISO8601 $modDate
                    "createdDate"       = Format-DateISO8601 $creDate
                    "sourceName"        = "uevrdeluxe.org"
                    "sourceUrl"         = $url
                    "sourceDownloadUrl" = $url
                    "description"       = $p.remarks
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
Debug-Log "[Update-FromUEVRDeluxe.ps1] Main Logic Start"
$Global:Debug = $Debug
$Global:UseProxies = $UseProxies
$Global:UseTailscale = $UseTailscale
if ($UseProxies) {
    $Proxies = $Global:ProxyPool
} else {
    $Proxies = $null
}

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
foreach ($d in @($SourceTempDir, $DownloadDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Fetch) { 
    Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Fetch-UEVRDeluxeMetadata"
    Fetch-UEVRDeluxeMetadata
    $data = Load-ProfilesFromFile $MetadataJson
    Assert-ProfileCount -count $data.Count -expected $ProfileLimit -Silent -stage "Fetch"
    $ExpectedCount = [Math]::Min($ExpectedCount, $data.Count)
}

if ($Download) { 
    Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Download-UEVRDeluxeProfiles"
    Download-UEVRDeluxeProfiles
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Assert-ProfileCount -count $zips.Count -expected $ExpectedCount -Silent -stage "Download"
    $ExpectedCount = [Math]::Min($ExpectedCount, $zips.Count)
}

if ($Extract) { 
    Debug-Log "[Update-FromUEVRDeluxe.ps1] Calling Extract-ArchivesFolder"
    $extracted = Extract-ArchivesFolder $DownloadDir -Limit $ProfileLimit -Silent:$Silent
    Assert-ProfileCount -count $extracted.Count -expected $ExpectedCount -Silent -stage "Extraction ID"
}
Finalize-GlobalTracking
Debug-Log "[Update-FromUEVRDeluxe.ps1] Main Logic End"
#endregion
