param(
    [switch]$Download,
    [switch]$Extract,
    [int]$DownloadLimit = 99999
)

$SourceName    = "uevrdeluxe.org"
$RepoRoot      = Split-Path $PSScriptRoot -Parent  # tools -> repo root
$ProfilesDir   = Join-Path $RepoRoot "profiles"
$DownloadDir   = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir  = Join-Path $env:TEMP "uevr_profiles\meta_cache"
$ProfilesJson  = Join-Path $MetaCacheDir "uevrdeluxe_allprofiles.json"
$ApiUrl        = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"
$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"
$SchemaFile    = Join-Path $RepoRoot "schemas\ProfileMeta.schema.json"

foreach ($d in @($DownloadDir, $MetaCacheDir, $ProfilesDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ── Whitelist & Duplication Checks ────────────────────────────────────────────
$WhitelistFile = Join-Path $PSScriptRoot "whitelist.json"
$WhitelistRegexes = @()

if (Test-Path $WhitelistFile) {
    $wl = Get-Content $WhitelistFile -Raw | ConvertFrom-Json
    foreach ($p in $wl.exact) { $WhitelistRegexes += "^" + [regex]::Escape($p) + "$" }
    foreach ($p in $wl.recursive_folders) { $WhitelistRegexes += "^" + [regex]::Escape($p.TrimEnd('/')) + "(/|$)" }
    foreach ($p in $wl.globs) {
        $r = [regex]::Escape($p)
        $r = $r.Replace("\\*\\*/", ".*").Replace("\\*\\*", ".*").Replace("\\*", ".*")
        $WhitelistRegexes += "^" + $r + "$"
    }
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace("\\", "/").Trim('/')
    if ($rel -eq "") { return $true }
    foreach ($re in $WhitelistRegexes) {
        if ($rel -match $re) { return $true }
        # Also allow parent directories of anything whitelisted
        $patternWithoutAnchors = $re.TrimStart('^').TrimEnd('$')
        if ($patternWithoutAnchors.StartsWith($rel + "/")) { return $true }
    }
    return $false
}

function Remove-NonWhitelisted($targetDir) {
    Get-ChildItem -Path $targetDir -Recurse | Sort-Object FullName -Descending | ForEach-Object {
        $rel = $_.FullName.Substring($targetDir.Length) -replace '^[\\/]+', ''
        if (-not (Test-Whitelisted $rel)) {
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

function Find-ProfileByHash($hash) {
    if ($null -eq $hash) { return $null }
    $metaFiles = Get-ChildItem -Path $ProfilesDir -Filter "ProfileMeta.json" -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $metaFiles) {
        try {
            # Fast check: skip if file is way too big
            if ($f.Length -gt 10kb) { continue }
            $json = Get-Content $f.FullName -Raw | ConvertFrom-Json
            if ($json.zipHash -eq $hash) { return $f.Directory.Name }
        } catch {}
    }
    return $null
}

function Test-Metadata($jsonText, $path) {
    if (Test-Path $SchemaFile) {
        $isValid = Test-Json -Json $jsonText -SchemaFile $SchemaFile -ErrorAction SilentlyContinue
        if (-not $isValid) {
            Write-Host "[!] Metadata validation FAILED for $path" -ForegroundColor Red
            try {
                $detailed = Test-Json -Json $jsonText -SchemaFile $SchemaFile -Detailed
                foreach ($e in $detailed.Errors) { Write-Host "    - $e" -ForegroundColor Yellow }
            } catch {}
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
            $zipHash = Get-FileHashMD5 $zipPath
            $cleanId  = $latest.ID.ToString().Replace("-", "")
            $sourceUrl = "$ProfilesUrlBase/$($latest.exeName)/$cleanId"
            $existingId = Find-ProfileByHash $zipHash
            if ($existingId) {
                Write-Host "  Found existing profile with same hash: $existingId. Skipping extraction." -ForegroundColor Gray
                # Update metadata if needed, but skip extraction
                $targetDir = Join-Path $ProfilesDir $existingId
                $uuid = $existingId
            } else {
                Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
                Remove-NonWhitelisted $targetDir
            }

            $meta = [ordered]@{
                "ID"           = $uuid
                "exeName"      = $latest.exeName
                "gameName"     = $latest.gameName
                "authorName"   = $latest.authorName
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
