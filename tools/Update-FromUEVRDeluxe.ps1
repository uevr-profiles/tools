param(
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = 99999,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
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
        if ($downloadedCount -ge $ProfileLimit) { break }
        $zipName = "$($p.id).zip"
        $zipPath = Join-Path $DownloadDir $zipName
        if (-not (Test-Path $zipPath)) {
            $url = "$ProfilesUrlBase/$($p.exeName)/$($p.id)"
            Write-Host "Downloading $($p.gameName) ($($p.exeName)) from $url..."
            try {
                Invoke-WebRequest -Uri $url -OutFile $zipPath
                Write-Host "  Success."
                # Save metadata sidecar
                $latest  = $p.history | Sort-Object modifiedDate -Descending | Select-Object -First 1
                $oldest  = $p.history | Sort-Object modifiedDate -Ascending  | Select-Object -First 1
                $sidecar = [ordered]@{
                    "authorName"   = $p.authorName
                    "gameName"     = $p.gameName
                    "exeName"      = $p.exeName
                    "modifiedDate" = $latest.modifiedDate
                    "createdDate"  = $oldest.modifiedDate
                    "sourceUrl"    = $url
                    "sourceDownloadUrl" = $url
                }
                $sidecar | ConvertTo-Json | Set-Content "$zipPath.json" -Encoding utf8
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
    $processedCount = 0

    foreach ($p in $profiles) {
        if ($processedCount -ge $ProfileLimit) { break }
        $zipPath = Join-Path $DownloadDir "$($p.id).zip"
        if (-not (Test-Path $zipPath)) { continue }
        $zipHash = Get-FileHashMD5 $zipPath
        $processedCount++

        $discovered = Extract-And-Discover-Profiles $zipPath $Whitelist $Blacklist
        if ($discovered.Count -eq 0) {
            Write-Warning "Archive for $($p.gameName) resulted in NO valid profiles!"
            Print-ProfileInfo @{ "ID"=$p.id; "gameName"=$p.gameName; "authorName"=$p.authorName; "sourceName"=$SourceName; "sourceUrl"=$ApiUrl; "zipHash"=$zipHash } $zipPath
            continue
        }

        foreach ($item in $discovered) {
            $tempDir = $item.Path
            $variant = $item.Variant
            
            # Resolve metadata from sidecar if exists, otherwise from main JSON
            $extraMeta = $null
            if (Test-Path "$zipPath.json") { $extraMeta = Get-Content "$zipPath.json" | ConvertFrom-Json }

            # Resolve UUID: First gets original, others get new.
            $uuid = if ($discovered.Count -eq 1 -or ($item -eq $discovered[0])) { Get-OrCreateUUID $p.id } else { Get-OrCreateUUID $null }
            
            $targetDir = Join-Path $ProfilesDir $uuid
            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
            
            # Move contents
            Get-ChildItem -Path $tempDir | Move-Item -Destination $targetDir -Force
            Remove-Item $tempDir -Recurse -Force

            $sourceUrl = "$ProfilesUrlBase/$($p.exeName)/$($p.id)"
            $latest  = $p.history | Sort-Object modifiedDate -Descending | Select-Object -First 1
            $oldest  = $p.history | Sort-Object modifiedDate -Ascending  | Select-Object -First 1

            $gameName = if ($extraMeta.gameName) { $extraMeta.gameName } else { $p.gameName }
            $displayVariant = Get-CleanVariantName $variant (if ($extraMeta.exeName) { $extraMeta.exeName } else { $p.exeName })
            $finalGameName = $gameName

            $metaProps = [ordered]@{
                "ID"                = $uuid
                "exeName"           = if ($extraMeta.exeName) { $extraMeta.exeName } else { $p.exeName }
                "gameName"          = $finalGameName
                "authorName"        = if ($extraMeta.authorName) { $extraMeta.authorName } else { $p.authorName }
                "modifiedDate"      = if ($extraMeta.modifiedDate) { $extraMeta.modifiedDate } else { $latest.modifiedDate }
                "createdDate"       = if ($extraMeta.createdDate) { $extraMeta.createdDate } else { $oldest.modifiedDate }
                "sourceName"        = $SourceName
                "sourceUrl"         = if ($extraMeta.sourceUrl) { $extraMeta.sourceUrl } else { $sourceUrl }
                "sourceDownloadUrl" = if ($extraMeta.sourceDownloadUrl) { $extraMeta.sourceDownloadUrl } else { $sourceUrl }
                "downloadDate"      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                "zipHash"           = $zipHash
                "downloadUrl"       = Get-ProfileDownloadUrl $uuid $p.exeName
            }
            $meta = Finalize-ProfileMetadata $targetDir $metaProps $displayVariant
            $meta = Remove-NullProperties $meta
            $json = $meta | ConvertTo-Json
            Test-Metadata $json (Join-Path $targetDir "ProfileMeta.json")
            $json | Set-Content (Join-Path $targetDir "ProfileMeta.json") -Encoding utf8
        }
    }
}
