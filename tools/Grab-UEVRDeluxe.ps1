param(
    [switch]$Download,
    [switch]$Extract,
    [int]$DownloadLimit = 99999
)

$SourceName    = "UEVRDeluxe"
$RepoRoot      = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # repo root
$ProfilesDir   = Join-Path $RepoRoot "profiles"
$DownloadDir   = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir  = Join-Path $env:TEMP "uevr_profiles\meta_cache"
$ProfilesJson  = Join-Path $MetaCacheDir "uevrdeluxe_allprofiles.json"
$ApiUrl        = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"
$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"

foreach ($d in @($DownloadDir, $MetaCacheDir, $ProfilesDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ── Whitelist ────────────────────────────────────────────────────────────────
$WhitelistFile = Join-Path $RepoRoot ".gitkeep"
$WhitelistPatterns = Get-Content $WhitelistFile |
    Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } |
    ForEach-Object { $_.Trim() }

function Test-Whitelisted($relPath) {
    # Normalise to forward slashes for matching
    $rel = $relPath.Replace("\\", "/")
    foreach ($pattern in $WhitelistPatterns) {
        # Exact match (file or folder entry like "paks/" -> "paks")
        $p = $pattern.TrimEnd("/")
        if ($rel -eq $p -or $rel -eq ($p + "/")) { return $true }
        # Glob match via PowerShell -like operator
        if ($rel -like $pattern) { return $true }
    }
    return $false
}

function Remove-NonWhitelisted($targetDir) {
    # Walk all items; delete anything not covered by the whitelist
    Get-ChildItem -Path $targetDir -Recurse | Sort-Object FullName -Descending | ForEach-Object {
        $rel = $_.FullName.Substring($targetDir.Length).TrimStart("\\","/")
        if ($_ -is [System.IO.DirectoryInfo]) { $rel += "/" }
        if (-not (Test-Whitelisted $rel)) {
            # If it's a dir, only remove if now empty (children already deleted above)
            if ($_ -is [System.IO.DirectoryInfo]) {
                if ((Get-ChildItem $_.FullName).Count -eq 0) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    Write-Host "  Removed unlisted dir:  $rel" -ForegroundColor DarkGray
                }
            } else {
                Remove-Item $_.FullName -Force
                Write-Host "  Removed unlisted file: $rel" -ForegroundColor DarkGray
            }
        }
    }
}
# ─────────────────────────────────────────────────────────────────────────────

function Get-FileHashMD5($Path) {
    if (Test-Path $Path) { return (Get-FileHash -Path $Path -Algorithm MD5).Hash }
    return $null
}

function Get-OrCreateUUID($existingId) {
    $null_uuid = "00000000-0000-0000-0000-000000000000"
    if ($existingId -and $existingId -ne $null_uuid) { return $existingId.ToLower() }
    return [System.Guid]::NewGuid().ToString().ToLower()
}

function Find-ExistingProfileFolder($uuid) {
    # Look for an existing folder named by this UUID
    $candidate = Join-Path $ProfilesDir $uuid
    if (Test-Path $candidate) { return $candidate }
    return $null
}

if ($Download) {
    Write-Host "Downloading $SourceName metadata..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $ApiUrl -OutFile $ProfilesJson -UserAgent "UEVRDeluxe"
    } catch {
        Write-Host "  Warning: Could not refresh metadata ($($_.Exception.Message)). Using cached version if available." -ForegroundColor Yellow
    }

    if (-not (Test-Path $ProfilesJson)) { Write-Error "No metadata available."; return }

    $jsonContent = Get-Content $ProfilesJson -Raw -Encoding utf8
    $jsonContent = $jsonContent.Trim().Replace("`u{FEFF}", "").Replace("`u{200B}", "")
    $jsonContent | Set-Content $ProfilesJson -Encoding utf8

    $profiles = Get-Content $ProfilesJson | ConvertFrom-Json
    Write-Host "Found $($profiles.Count) profiles."

    $downloadedCount = 0
    foreach ($p in $profiles) {
        if ($downloadedCount -ge $DownloadLimit) { break }

        $cleanId = $p.ID.Replace("-", "")
        $exeName = $p.exeName
        $zipName = "$($p.ID).zip"
        $zipPath = Join-Path $DownloadDir $zipName

        if (-not (Test-Path $zipPath)) {
            $url = "$ProfilesUrlBase/$exeName/$cleanId"
            Write-Host "Downloading $($p.gameName) ($exeName) from $url..."
            try {
                Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent "UEVRDeluxe"
                Write-Host "  Success." -ForegroundColor Green
                $downloadedCount++
            } catch {
                Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
                if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
            }
        } else {
            Write-Host "  $zipName already cached, skipping."
            $downloadedCount++
        }
    }
}

if ($Extract) {
    if (-not (Test-Path $ProfilesJson)) { Write-Error "Metadata file not found. Run with -Download first."; return }
    $profiles = Get-Content $ProfilesJson | ConvertFrom-Json

    $grouped = $profiles | Group-Object exeName

    foreach ($group in $grouped) {
        $latest  = $group.Group | Sort-Object modifiedDate -Descending | Select-Object -First 1
        $zipPath = Join-Path $DownloadDir "$($latest.ID).zip"
        if (-not (Test-Path $zipPath)) { continue }

        # Determine UUID folder name
        $uuid      = Get-OrCreateUUID $latest.ID
        $targetDir = Find-ExistingProfileFolder $uuid
        if (-not $targetDir) { $targetDir = Join-Path $ProfilesDir $uuid }

        Write-Host "Extracting $($latest.gameName) -> $targetDir..."
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

        try {
            $hash     = Get-FileHashMD5 $zipPath
            $cleanId  = $latest.ID.ToString().Replace("-", "")
            $sourceUrl = "$ProfilesUrlBase/$($latest.exeName)/$cleanId"

            Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
            Remove-NonWhitelisted $targetDir

            $meta = [ordered]@{
                "ID"           = $uuid
                "exeName"      = $latest.exeName
                "gameName"     = $latest.gameName
                "authorName"   = $latest.authorName
                "modifiedDate" = $latest.modifiedDate
                "sourceName"   = $SourceName
                "sourceUrl"    = $sourceUrl
                "downloadDate" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                "zipHash"      = $hash
            }
            $meta | ConvertTo-Json | Set-Content (Join-Path $targetDir "ProfileMeta.json") -Encoding utf8
        } catch {
            Write-Host "  Extraction error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
