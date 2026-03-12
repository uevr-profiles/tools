param(
    [switch]$Download,
    [switch]$Extract,
    [int]$DownloadLimit = 99999
)

$SourceName      = "uevr-profiles.com"
$RepoRoot        = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # repo root
$ProfilesDir     = Join-Path $RepoRoot "profiles"
$DownloadDir     = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir    = Join-Path $env:TEMP "uevr_profiles\meta_cache"
$MetadataJson    = Join-Path $MetaCacheDir "uevrprofiles_com_metadata.json"

$FirestoreUrl    = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"

foreach ($d in @($DownloadDir, $MetaCacheDir, $ProfilesDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ── Whitelist ────────────────────────────────────────────────────────────────
$WhitelistFile = Join-Path $RepoRoot ".gitkeep"
$WhitelistPatterns = Get-Content $WhitelistFile |
    Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } |
    ForEach-Object { $_.Trim() }

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace("\\", "/")
    foreach ($pattern in $WhitelistPatterns) {
        $p = $pattern.TrimEnd("/")
        if ($rel -eq $p -or $rel -eq ($p + "/")) { return $true }
        if ($rel -like $pattern) { return $true }
    }
    return $false
}

function Remove-NonWhitelisted($targetDir) {
    Get-ChildItem -Path $targetDir -Recurse | Sort-Object FullName -Descending | ForEach-Object {
        $rel = $_.FullName.Substring($targetDir.Length).TrimStart("\\","/")
        if ($_ -is [System.IO.DirectoryInfo]) { $rel += "/" }
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
# ─────────────────────────────────────────────────────────────────────────────

function Get-FileHashMD5($Path) {
    if (Test-Path $Path) { return (Get-FileHash -Path $Path -Algorithm MD5).Hash }
    return $null
}

function Get-OrCreateUUID($existingId) {
    $null_uuid = "00000000-0000-0000-0000-000000000000"
    if ($existingId -and $existingId -ne $null_uuid -and $existingId -match "^[0-9a-fA-F]{8}-") {
        return $existingId.ToLower()
    }
    return [System.Guid]::NewGuid().ToString().ToLower()
}

function Find-ExistingProfileFolder($uuid) {
    $candidate = Join-Path $ProfilesDir $uuid
    if (Test-Path $candidate) { return $candidate }
    return $null
}

if ($Download) {
    Write-Host "Fetching $SourceName metadata (with pagination)..." -ForegroundColor Cyan
    $allDocs   = @()
    $pageToken = ""

    do {
        $url = $FirestoreUrl
        if ($pageToken) { $url += "&pageToken=$pageToken" }
        $response  = Invoke-RestMethod -Uri $url
        if ($response.documents) { $allDocs += $response.documents }
        $pageToken = $response.nextPageToken
    } while ($pageToken)

    $allDocs | ConvertTo-Json -Depth 10 | Set-Content $MetadataJson -Encoding utf8
    Write-Host "Total games found: $($allDocs.Count)"

    $archives = @()
    foreach ($doc in $allDocs) {
        $profilesField = $doc.fields.profiles.arrayValue.values
        if ($null -eq $profilesField -or $profilesField -eq "") { continue }
        if (-not ($profilesField -is [System.Collections.IEnumerable])) { $profilesField = @($profilesField) }

        foreach ($p in $profilesField) {
            $p_fields = $p.mapValue.fields
            $arch = $p_fields.archive.stringValue
            if ($arch -and $arch.EndsWith(".zip")) { $archives += $arch }

            $linksField = $p_fields.links.arrayValue.values
            if ($linksField -is [System.Collections.IEnumerable]) {
                foreach ($link in $linksField) {
                    $l_arch = $link.mapValue.fields.archive.stringValue
                    if ($l_arch -and $l_arch.EndsWith(".zip")) { $archives += $l_arch }
                }
            }
        }
    }

    $uniqueArchives = $archives | Select-Object -Unique | Where-Object { $_ -ne $null }
    Write-Host "Found $($uniqueArchives.Count) archives to download."

    $downloadedCount = 0
    foreach ($arch in $uniqueArchives) {
        if ($downloadedCount -ge $DownloadLimit) { break }
        $zipPath = Join-Path $DownloadDir $arch
        if (-not (Test-Path $zipPath)) {
            Write-Host "Requesting download URL for $($arch)..."
            $body = @{ data = @{ file = $arch } } | ConvertTo-Json
            try {
                $funcResp    = Invoke-RestMethod -Method Post -Uri $DownloadFuncUrl -Body $body -ContentType "application/json"
                $downloadUrl = $funcResp.result.url
                if (-not $downloadUrl) { $downloadUrl = $funcResp.result }
                if ($downloadUrl) {
                    Write-Host "  Downloading $arch..."
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
                    $downloadedCount++
                }
            } catch {
                Write-Host "  Failed to download $($arch): $($_.Exception.Message)" -ForegroundColor Red
                if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
            }
        } else {
            Write-Host "  $arch already cached, skipping."
            $downloadedCount++
        }
    }
}

if ($Extract) {
    if (-not (Test-Path $MetadataJson)) { Write-Error "Metadata file not found. Run with -Download first."; return }
    $docs    = Get-Content $MetadataJson | ConvertFrom-Json
    $gameMap = @{}

    foreach ($doc in $docs) {
        $gameName      = $doc.fields.gameName.stringValue
        $profilesField = $doc.fields.profiles.arrayValue.values
        if ($null -eq $profilesField -or $profilesField -eq "") { continue }
        if (-not ($profilesField -is [System.Collections.IEnumerable])) { $profilesField = @($profilesField) }

        foreach ($p in $profilesField) {
            $p_fields = $p.mapValue.fields
            $dateStr  = $p_fields.creationDate.timestampValue
            if (-not $dateStr) { $dateStr = "1970-01-01T00:00:00Z" }
            $date = [DateTime]::Parse($dateStr)

            $profileArchives = @()
            if ($p_fields.archive.stringValue -and $p_fields.archive.stringValue.EndsWith(".zip")) {
                $profileArchives += $p_fields.archive.stringValue
            }
            $linksField = $p_fields.links.arrayValue.values
            if ($linksField -is [System.Collections.IEnumerable]) {
                foreach ($link in $linksField) {
                    $l = $link.mapValue.fields.archive.stringValue
                    if ($l -and $l.EndsWith(".zip")) { $profileArchives += $l }
                }
            }

            if ($profileArchives.Count -gt 0) {
                if (-not $gameMap.ContainsKey($gameName) -or $date -gt $gameMap[$gameName].Date) {
                    $gameMap[$gameName] = @{
                        Date     = $date
                        Archives = $profileArchives
                        RawID    = $p_fields.id.stringValue
                        Author   = $p_fields.author.stringValue
                        ExeName  = $p_fields.exeName.stringValue
                    }
                }
            }
        }
    }

    foreach ($game in $gameMap.Keys) {
        $info = $gameMap[$game]
        foreach ($arch in $info.Archives) {
            $zipPath = Join-Path $DownloadDir $arch
            if (-not (Test-Path $zipPath)) { continue }

            $targetExe = $info.ExeName
            if (-not $targetExe) {
                $targetExe = $arch.Replace(".zip", "") -replace "_\d+$", ""
            }

            # UUID: use existing or generate
            $uuid      = Get-OrCreateUUID $info.RawID
            $targetDir = Find-ExistingProfileFolder $uuid
            if (-not $targetDir) { $targetDir = Join-Path $ProfilesDir $uuid }

            Write-Host "Extracting $game ($arch) -> $targetDir..."
            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

            try {
                $hash = Get-FileHashMD5 $zipPath
                Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
                Remove-NonWhitelisted $targetDir

                # Handle nested ZIPs (e.g. archive-within-archive)
                $innerZips = Get-ChildItem -Path $targetDir -Filter "*.zip" -ErrorAction SilentlyContinue
                if ($innerZips.Count -gt 0 -and -not (Test-Path (Join-Path $targetDir "config.txt"))) {
                    foreach ($inner in $innerZips) {
                        $innerUUID   = Get-OrCreateUUID $null
                        $innerTarget = Join-Path $ProfilesDir $innerUUID
                        if (-not (Test-Path $innerTarget)) { New-Item -ItemType Directory -Path $innerTarget -Force | Out-Null }
                        Expand-Archive -Path $inner.FullName -DestinationPath $innerTarget -Force
                        Remove-Item $inner.FullName -Force
                    }
                }

                $meta = [ordered]@{
                    "ID"           = $uuid
                    "exeName"      = $targetExe
                    "gameName"     = $game
                    "authorName"   = $info.Author
                    "modifiedDate" = $info.Date.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    "sourceName"   = $SourceName
                    "sourceUrl"    = "https://uevr-profiles.com/"
                    "downloadDate" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                    "zipHash"      = $hash
                }
                $meta | ConvertTo-Json | Set-Content (Join-Path $targetDir "ProfileMeta.json") -Encoding utf8
            } catch {
                Write-Host "  Extraction error: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}
