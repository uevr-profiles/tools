param(
    [switch]$Download,
    [switch]$Extract,
    [int]$DownloadLimit = 99999
)

$SourceName      = "uevr-profiles.com"
$RepoRoot        = Split-Path $PSScriptRoot -Parent  # tools -> repo root
$ProfilesDir     = Join-Path $RepoRoot "profiles"
$DownloadDir     = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir    = Join-Path $env:TEMP "uevr_profiles\meta_cache"
$MetadataJson    = Join-Path $MetaCacheDir "uevrprofiles_com_metadata.json"

$FirestoreUrl    = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"
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
                $zipHash = Get-FileHashMD5 $zipPath
                $existingId = Find-ProfileByHash $zipHash
                if ($existingId) {
                    Write-Host "  Found existing profile with same hash: $existingId. Skipping extraction." -ForegroundColor Gray
                    $targetDir = Join-Path $ProfilesDir $existingId
                    $uuid = $existingId
                } else {
                    Expand-Archive -Path $zipPath -DestinationPath $targetDir -Force
                    Remove-NonWhitelisted $targetDir
                }

                # Handle nested ZIPs
                $innerZips = Get-ChildItem -Path $targetDir -Filter "*.zip" -ErrorAction SilentlyContinue
                if ($innerZips.Count -gt 0 -and -not (Test-Path (Join-Path $targetDir "config.txt"))) {
                    foreach ($inner in $innerZips) {
                        $innerUUID   = Get-OrCreateUUID $null
                        $innerTarget = Join-Path $ProfilesDir $innerUUID
                        if (-not (Test-Path $innerTarget)) { New-Item -ItemType Directory -Path $innerTarget -Force | Out-Null }
                        Expand-Archive -Path $inner.FullName -DestinationPath $innerTarget -Force
                        Remove-NonWhitelisted $innerTarget
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
}
