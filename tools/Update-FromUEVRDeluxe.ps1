param(
    [switch]$Download,
    [switch]$Extract,
    [int]$DownloadLimit = 99999,
    [switch]$Whitelist,
    [switch]$Blacklist
)

. "$PSScriptRoot\common.ps1"

$SourceName    = "uevrdeluxe.org"
$DownloadDir   = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir  = Join-Path $env:TEMP "uevr_profiles\metadata"
$ProfilesJson  = Join-Path $MetaCacheDir "uevrdeluxe_allprofiles.json"
$ApiUrl        = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"
$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Download) {
    Write-Host "Downloading $SourceName metadata..."
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            Invoke-WebRequest -Uri $ApiUrl -OutFile $ProfilesJson -ErrorAction Stop
            $success = $true
        } catch {
            $retryCount++
            Write-Host "  Attempt $retryCount failed: $($_.Exception.Message)" -ForegroundColor Yellow
            if ($retryCount -lt $maxRetries) { Start-Sleep -Seconds 2 }
        }
    }

    if (-not $success) {
        Write-Host "Failed to download metadata after $maxRetries attempts. Skipping download/extract." -ForegroundColor Red
        return
    }

    try {
        $profiles = Get-Content $ProfilesJson -Raw | ConvertFrom-Json
        Write-Host "Found $($profiles.Count) profiles."
    } catch {
        Write-Host "Failed to parse metadata JSON: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    $downloadedCount = 0
    foreach ($p in $profiles) {
        if ($downloadedCount -ge $DownloadLimit) { break }
        $zipName = "$($p.id).zip"
        $zipPath = Join-Path $DownloadDir $zipName
        if (-not (Test-Path $zipPath)) {
            $url = "$ProfilesUrlBase/$($p.exeName)/$($p.id)"
            Write-Host "Downloading $($p.gameName) ($($p.exeName)) from $url..."
            try {
                Invoke-WebRequest -Uri $url -OutFile $zipPath
                Write-Host "  Success."
                $downloadedCount++
            } catch {
                Write-Host "  Failed to download $($p.id): $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            $downloadedCount++
        }
    }
}

if ($Extract) {
    if (-not (Test-Path $ProfilesJson)) { Write-Error "Metadata file not found. Run with -Download first."; return }
    $profiles = Get-Content $ProfilesJson | ConvertFrom-Json

    foreach ($p in $profiles) {
        $zipPath = Join-Path $DownloadDir "$($p.id).zip"
        if (-not (Test-Path $zipPath)) { continue }

        $uuid      = Get-OrCreateUUID $p.id
        $targetDir = Find-ExistingProfileFolder $uuid
        if (-not $targetDir) { $targetDir = Join-Path $ProfilesDir $uuid }

        Write-Host "Extracting $($p.gameName) -> $targetDir..."
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

        try {
            $zipHash = Get-FileHashMD5 $zipPath
            $existingId = Find-ProfileByHash $zipHash
            if ($existingId) {
                Write-Host "  Found existing profile with same hash: $existingId. Skipping extraction." -ForegroundColor Gray
                $targetDir = Join-Path $ProfilesDir $existingId
                $uuid = $existingId
            } else {
                Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
                Remove-NonWhitelisted $targetDir -applyWhitelist:$Whitelist -applyBlacklist:$Blacklist
            }

            $sourceUrl = "$ProfilesUrlBase/$($p.exeName)/$($p.id)"
            $latest = $p.history | Sort-Object modifiedDate -Descending | Select-Object -First 1

            $meta = [ordered]@{
                "ID"           = $uuid
                "exeName"      = $p.exeName
                "gameName"     = $p.gameName
                "authorName"   = $p.authorName
                "modifiedDate" = $latest.modifiedDate
                "sourceName"   = $SourceName
                "sourceUrl"    = $sourceUrl
                "downloadDate" = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                "zipHash"      = $zipHash
            }
            $json = $meta | ConvertTo-Json
            Test-Metadata $json (Join-Path $targetDir "ProfileMeta.json")
            $json | Set-Content (Join-Path $targetDir "ProfileMeta.json") -Encoding utf8
        } catch {
            Write-Host "  Extraction error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
