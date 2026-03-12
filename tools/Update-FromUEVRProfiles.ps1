param(
    [switch]$Download,
    [switch]$Extract,
    [int]$DownloadLimit = 99999,
    [switch]$Whitelist,
    [switch]$Blacklist
)

. "$PSScriptRoot\common.ps1"

$SourceName      = "uevr-profiles.com"
$DownloadDir     = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir    = Join-Path $env:TEMP "uevr_profiles\metadata"
$MetadataJson    = Join-Path $MetaCacheDir "uevrprofiles_allmetadata.json"

$FirestoreUrl    = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

if ($Download) {
    Write-Host "Fetching $SourceName metadata (with pagination)..."
    $allDocs    = @()
    $nextPage   = $null
    $url        = $FirestoreUrl
    $pageCount  = 0
    
    do {
        $pUrl = if ($nextPage) { "$url&pageToken=$nextPage" } else { $url }
        $resp = Invoke-RestMethod -Uri $pUrl
        $allDocs += $resp.documents
        $nextPage = $resp.nextPageToken
        $pageCount++
    } while ($nextPage -and $pageCount -lt 10)

    $allDocs | ConvertTo-Json -Depth 20 | Set-Content $MetadataJson -Encoding utf8
    
    $archives = @()
    foreach ($doc in $allDocs) {
        $profilesField = $doc.fields.profiles.arrayValue.values
        if ($null -eq $profilesField -or $profilesField -eq "") { continue }
        if (-not ($profilesField -is [System.Collections.IEnumerable])) { $profilesField = @($profilesField) }

        foreach ($p in $profilesField) {
            $p_fields = $p.mapValue.fields
            $arch     = $p_fields.archive.stringValue
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
                    Remove-NonWhitelisted $targetDir -applyWhitelist:$Whitelist -applyBlacklist:$Blacklist
                }

                # Handle nested ZIPs
                $innerZips = Get-ChildItem -Path $targetDir -Filter "*.zip" -ErrorAction SilentlyContinue
                if ($innerZips.Count -gt 0 -and -not (Test-Path (Join-Path $targetDir "config.txt"))) {
                    foreach ($inner in $innerZips) {
                        $innerUUID   = Get-OrCreateUUID $null
                        $innerTarget = Join-Path $ProfilesDir $innerUUID
                        if (-not (Test-Path $innerTarget)) { New-Item -ItemType Directory -Path $innerTarget -Force | Out-Null }
                        Expand-Archive -Path $inner.FullName -DestinationPath $innerTarget -Force
                        Remove-NonWhitelisted $innerTarget -applyWhitelist:$Whitelist -applyBlacklist:$Blacklist
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
