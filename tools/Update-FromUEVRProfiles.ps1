param(
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = 99999,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

. "$PSScriptRoot\common.ps1"

$SourceName = "uevr-profiles.com"
$DownloadDir = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir = Join-Path $env:TEMP "uevr_profiles\metadata"
$MetadataJson = Join-Path $MetaCacheDir "uevrprofiles_allmetadata.json"

$FirestoreUrl = "https://firestore.googleapis.com/v1/projects/uevrprofiles/databases/(default)/documents/games?pageSize=500"
$DownloadFuncUrl = "https://us-central1-uevrprofiles.cloudfunctions.net/downloadFile"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Migrate legacy meta.csv or .url files to sidecar .json files
if (Test-Path $DownloadDir) {
    # 1. Migrate meta.csv if exists
    $MetaCsv = Join-Path $DownloadDir "meta.csv"
    if (Test-Path $MetaCsv) {
        Write-Host "Migrating meta.csv to sidecar .zip.json files..."
        $csvData = Import-Csv -Path $MetaCsv -Delimiter ";" -Header "Filename", "Url" -ErrorAction SilentlyContinue
        foreach ($row in $csvData) {
            $jsonSidecar = Join-Path $DownloadDir "$($row.Filename).json"
            if (-not (Test-Path $jsonSidecar)) {
                @{ "sourceDownloadUrl" = $row.Url } | ConvertTo-Json | Set-Content $jsonSidecar -Encoding utf8
            }
        }
        Remove-Item $MetaCsv -Force
    }
    # 2. Migrate legacy .url files
    $urlFiles = Get-ChildItem -Path $DownloadDir -Filter "*.zip.url"
    foreach ($f in $urlFiles) {
        $arch = $f.Name.Replace(".url", "")
        $jsonSidecar = Join-Path $DownloadDir "$arch.json"
        if (-not (Test-Path $jsonSidecar)) {
            $url = Get-Content $f.FullName -Raw | ForEach-Object { $_.Trim() }
            if ($url) {
                @{ "sourceDownloadUrl" = $url } | ConvertTo-Json | Set-Content $jsonSidecar -Encoding utf8
            }
        }
        Remove-Item $f.FullName -Force
    }
}

if ($Download) {
    Write-Host "Fetching $SourceName metadata (with pagination)..."
    $allDocs = @()
    $nextPage = $null
    $url = $FirestoreUrl
    $pageCount = 0
    
    do {
        try {
            $pUrl = if ($nextPage) { "$url&pageToken=$nextPage" } else { $url }
            $resp = Invoke-RestMethod -Uri $pUrl -ErrorAction Stop
            if ($resp.documents) { $allDocs += $resp.documents }
            $nextPage = $resp.nextPageToken
            $pageCount++
        }
        catch {
            Write-Host "  Error fetching metadata page ${pageCount} - $($_.Exception.Message)" -ForegroundColor Red
            break
        }
    } while ($nextPage -and $pageCount -lt 10)

    if ($allDocs.Count -gt 0) {
        $allDocs | ConvertTo-Json -Depth 20 | Set-Content $MetadataJson -Encoding utf8
    }
    else {
        Write-Host "No metadata docs found or fetch failed. Skipping download." -ForegroundColor Yellow
    }
    
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
        if ($downloadedCount -ge $ProfileLimit) { break }
        $zipPath = Join-Path $DownloadDir $arch
        if (-not (Test-Path $zipPath)) {
            Write-Host "Requesting download URL for $($arch)..."
            $body = @{ data = @{ file = $arch } } | ConvertTo-Json
            try {
                $funcResp = Invoke-RestMethod -Method Post -Uri $DownloadFuncUrl -Body $body -ContentType "application/json"
                $downloadUrl = $funcResp.result.url
                if (-not $downloadUrl) { $downloadUrl = $funcResp.result }
                if ($downloadUrl) {
                    Write-Host "  Downloading $arch..."
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
                    # Save metadata sidecar
                    $sidecarPath = "$zipPath.json"
                    $sidecarData = [ordered]@{ "sourceDownloadUrl" = $downloadUrl }
                    # Find original document to get appID/header
                    $doc = $allDocs | Where-Object { 
                        $_.fields.profiles.arrayValue.values | Where-Object { $_.mapValue.fields.archive.stringValue -eq $arch }
                    } | Select-Object -First 1
                    if ($doc) {
                        if ($doc.fields.appID.stringValue) { $sidecarData["appID"] = $doc.fields.appID.stringValue }
                        if ($doc.fields.headerPictureUrl.stringValue) { $sidecarData["headerPictureUrl"] = $doc.fields.headerPictureUrl.stringValue }
                    }
                    $sidecarData | ConvertTo-Json | Set-Content $sidecarPath -Encoding utf8
                    $downloadedCount++
                }
            }
            catch {
                Write-Host "  Failed to download $($arch): $($_.Exception.Message)" -ForegroundColor Red
                if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
            }
        }
        else {
            Write-Host "  $arch already cached, skipping."
            $downloadedCount++
        }
    }
}

if ($Extract) {
    $processedCount = 0
    if (-not (Test-Path $MetadataJson)) { Write-Error "Metadata file not found. Run with -Download first."; return }
    $docs = Get-Content $MetadataJson | ConvertFrom-Json
    $gameMap = @{}

    foreach ($doc in $docs) {
        $fields   = $doc.fields
        $gameName = $fields.gameName.stringValue
        $appID    = $fields.appID.stringValue
        $headerUrl = $fields.headerPictureUrl.stringValue
        
        $profilesField = $fields.profiles.arrayValue.values
        if ($null -eq $profilesField -or $profilesField -eq "") { continue }
        if (-not ($profilesField -is [System.Collections.IEnumerable])) { $profilesField = @($profilesField) }

        foreach ($p in $profilesField) {
            $p_fields = $p.mapValue.fields
            $dateStr = $p_fields.creationDate.timestampValue
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
                # Look for createdDate in doc level createTime or profile level createdAt
                $createdDate = $doc.createTime
                if (-not $createdDate) { $createdDate = $p_fields.createdAt.timestampValue }
                if (-not $createdDate) { $createdDate = $dateStr } # Fallback to modified date

                if (-not $gameMap.ContainsKey($gameName) -or $date -gt $gameMap[$gameName].Date) {
                    $gameMap[$gameName] = @{
                        Date             = $date
                        CreatedDate      = $createdDate
                        Archives         = $profileArchives
                        RawID            = $p_fields.id.stringValue
                        Author           = $p_fields.author.stringValue
                        ExeName          = $p_fields.exeName.stringValue
                        Description      = $p_fields.description.stringValue
                        AppID            = $appID
                        HeaderPictureUrl = $headerUrl
                    }
                }
            }
        }
    }

    foreach ($game in $gameMap.Keys) {
        if ($processedCount -ge $ProfileLimit) { break }
        $info = $gameMap[$game]
        foreach ($arch in $info.Archives) {
            if ($processedCount -ge $ProfileLimit) { break }
            $zipPath = Join-Path $DownloadDir $arch
            if (-not (Test-Path $zipPath)) { continue }
            $zipHash = Get-FileHashMD5 $zipPath
            $processedCount++

            $discovered = Extract-And-Discover-Profiles $zipPath $Whitelist $Blacklist
            if ($discovered.Count -eq 0) {
                Write-Warning "Archive $arch for $game resulted in NO valid profiles!"
                # Centralized info print for empty extraction
                Print-ProfileInfo @{ "ID"="N/A"; "gameName"=$game; "authorName"=$info.Author; "sourceName"=$SourceName; "sourceUrl"="https://uevr-profiles.com/"; "zipHash"=$zipHash } $zipPath
                continue
            }

            foreach ($p in $discovered) {
                $tempDir = $p.Path
                $variant = $p.Variant
                
                $targetExe = $info.ExeName
                if (-not $targetExe) {
                    $targetExe = $arch.Replace(".zip", "") -replace "_\d+$", ""
                }

                # Resolve UUID: If single profile, keep original. If multi, first gets original, others get new.
                $uuid = if ($discovered.Count -eq 1 -or ($p -eq $discovered[0])) { Get-OrCreateUUID $info.RawID } else { Get-OrCreateUUID $null }
                
                $targetDir = Join-Path $ProfilesDir $uuid
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                
                # Move contents to target
                Get-ChildItem -Path $tempDir | Move-Item -Destination $targetDir -Force
                Remove-Item $tempDir -Recurse -Force
                
                # Write Description if available
                $descPath = Join-Path $targetDir "ProfileDescription.md"
                if ($info.Description -and -not (Test-Path $descPath)) {
                    $info.Description | Set-Content $descPath -Encoding utf8
                }

                $sourceDownloadUrl = $null
                $extraMeta = $null
                $sidecarPath = "$zipPath.json"
                if (Test-Path $sidecarPath) {
                    $extraMeta = Get-Content $sidecarPath | ConvertFrom-Json
                    $sourceDownloadUrl = $extraMeta.sourceDownloadUrl
                }

                if ($null -eq $sourceDownloadUrl -or $sourceDownloadUrl -match "^https?://uevr-profiles\.com/?$") {
                    if (-not $Silent) {
                        throw "Fatal: No valid direct sourceDownloadUrl for $uuid ($game). Re-run with -Silent to omit."
                    }
                    $sourceDownloadUrl = $null
                }

                $finalGameName = if ($variant) { "$game ($variant)" } else { $game }

                $metaProps = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $targetExe
                    "gameName"          = $finalGameName
                    "authorName"        = $info.Author
                    "modifiedDate"      = $info.Date.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    "createdDate"       = $info.CreatedDate
                    "appID"             = if ($extraMeta.appID) { $extraMeta.appID } else { $info.AppID }
                    "headerPictureUrl"  = if ($extraMeta.headerPictureUrl) { $extraMeta.headerPictureUrl } else { $info.HeaderPictureUrl }
                    "sourceName"        = $SourceName
                    "sourceUrl"         = "https://uevr-profiles.com/"
                    "downloadDate"      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                    "zipHash"           = $zipHash
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $targetExe
                }
                if ($null -ne $sourceDownloadUrl) {
                    $metaProps["sourceDownloadUrl"] = $sourceDownloadUrl
                }
                $meta = Finalize-ProfileMetadata $targetDir $metaProps $item.ProfileName
                $meta = Remove-NullProperties $meta
                $json = $meta | ConvertTo-Json
                Test-Metadata $json (Join-Path $targetDir "ProfileMeta.json")
                $json | Set-Content (Join-Path $targetDir "ProfileMeta.json") -Encoding utf8
            }
        }
    }
}
