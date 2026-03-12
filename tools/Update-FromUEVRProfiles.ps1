param(
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
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

function Invoke-ProfileRequest($url) {
    # Stealthy headers mimicking modern client, but NO specific User-Agent as requested for this domain
    $headers = @{
        "Accept" = "application/json"
    }
    return Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
}

# ──────── Phase 1: Metadata & Downloads ───────────────────────────────────────
if ($Download) {
    Write-Host "Fetching all metadata from Firestore..." -ForegroundColor Cyan
    try {
        $meta = Invoke-ProfileRequest $FirestoreUrl
        $allProfiles = @()
        foreach ($doc in $meta.documents) {
            $gameName = $doc.fields.gameName.stringValue
            $topExe   = $doc.fields.exeName.stringValue
            
            # Profiles in uevr-profiles.com are in a nested array
            $variants = $doc.fields.profiles.arrayValue.values
            if (-not $variants) { continue }
            
            foreach ($v in $variants) {
                $vf = $v.mapValue.fields
                $profileId = $vf.id.stringValue
                if (-not $profileId) { continue }
                
                # Construct direct download URL (fallback)
                $dlUrl = "https://firebasestorage.googleapis.com/v0/b/uevrprofiles.appspot.com/o/profiles%2f$($profileId).zip?alt=media"
                
                # Extract archive filename from links if present
                $archiveFile = $null
                try {
                    $links = $vf.links.arrayValue.values
                    foreach ($linkObj in $links) {
                        $lFields = $linkObj.mapValue.fields
                        if ($lFields.archive.stringValue) {
                            $archiveFile = $lFields.archive.stringValue
                            break
                        }
                    }
                } catch {}

                $obj = @{
                    "id"           = $profileId
                    "gameName"     = $gameName
                    "authorName"   = $vf.author.stringValue
                    "modifiedDate" = $vf.creationDate.timestampValue
                    "createdDate"  = $vf.creationDate.timestampValue
                    "exeName"      = if ($topExe) { $topExe } else { "" }
                    "downloadUrl"  = $dlUrl
                    "archive"      = if ($archiveFile) { $archiveFile } else { "$($profileId).zip" }
                    "remarks"      = $vf.description.stringValue
                }
                $allProfiles += $obj
            }
        }
        $allProfiles | ConvertTo-Json | Set-Content $MetadataJson -Encoding utf8
    } catch {
        Write-Warning "Firestore API failed. Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }

    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    $count = 0
    foreach ($p in $profiles) {
        if ($count -ge $ProfileLimit) { break }
        $targetFile = Join-Path $DownloadDir "$($p.id).zip"
        $sidecar    = Join-Path $DownloadDir "$($p.id).zip.json"
        
        if (-not (Test-Path $targetFile)) {
            Write-Host "Downloading: $($p.gameName) ($($p.exeName))..." -ForegroundColor Gray
            try {
                $delay = Get-Random -Minimum 500 -Maximum 1500
                Start-Sleep -Milliseconds $delay # Stealth delay
                
                # Try direct download first as it's more reliable than the cloud function
                $UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                Invoke-WebRequest -Uri $p.downloadUrl -OutFile $targetFile -UserAgent $UA -ErrorAction Stop
                
                # Save metadata sidecar for extraction phase
                $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++
            } catch {
                Write-Host "  [!] Direct download failed, trying cloud function..." -ForegroundColor Yellow
                try {
                    # Firebase Callable Functions expect the payload wrapped in a "data" object
                    $payload = @{ "data" = @{ "file" = $p.archive } } | ConvertTo-Json
                    
                    $UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                    $response = Invoke-RestMethod -Method Post -Uri $DownloadFuncUrl -Body $payload -ContentType "application/json" -UserAgent $UA -ErrorAction Stop
                    
                    if ($response.result.url) {
                        Invoke-WebRequest -Uri $response.result.url -OutFile $targetFile -UserAgent $UA -ErrorAction Stop
                        $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                        $count++
                    } else {
                        throw "Cloud function did not return a valid download URL."
                    }
                } catch {
                    Write-Host "  [!] Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

# ──────── Phase 2: Extraction & Integration ────────────────────────────────────
if ($Extract) {
    # Clear target profiles dir to ensure a clean sync (optional, usually preferred)
    # Remove-Item (Join-Path $ProfilesDir "*") -Recurse -Force -ErrorAction SilentlyContinue

    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Write-Host "Processing $($zips.Count) profiles from $SourceName..." -ForegroundColor Cyan

    foreach ($z in $zips) {
        $sidecar = $z.FullName + ".json"
        if (-not (Test-Path $sidecar)) { continue }
        $p = Get-Content $sidecar -Raw | ConvertFrom-Json

        $zipHash = Get-FileHashMD5 $z.FullName
        $sourceUrl = "https://uevr-profiles.com/game/$($p.id)"
        
        # Discover profiles within archive (handles nested structures)
        $discovered = Extract-And-Discover-Profiles $z.FullName $Whitelist $Blacklist
        
        foreach ($d in $discovered) {
            $variant = $d.Variant
            $tempDir = $d.Path
            $uuid = Get-OrCreateUUID $p.id # Use firestore ID as base UUID
            
            # Directory pattern: <Repo>/profiles/<UUID>[/<Variant>]
            $targetDir = Join-Path $ProfilesDir $uuid
            if ($variant -and $variant -ne "[Root]") {
                $vPath = $variant -replace ' / ', '\'
                $targetDir = Join-Path $targetDir $vPath
            }
            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
            
            # Move contents
            $relFiles = Get-ChildItem -Path $tempDir -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object { 
                $_.FullName.Substring($tempDir.Length).TrimStart('\')
            }
            Update-GlobalFilesList $relFiles
            
            Get-ChildItem -Path $tempDir | Move-Item -Destination $targetDir -Force
            Remove-Item $tempDir -Recurse -Force

            $finalExe = if ($extraMeta.exeName) { $extraMeta.exeName } elseif ($p.exeName) { $p.exeName } else { $p.exename }
            $finalAuthor = if ($extraMeta.authorName) { $extraMeta.authorName } elseif ($p.authorName) { $p.authorName } else { $p.author }
            $displayVariant = Get-CleanVariantName $variant $finalExe
            
            $metaProps = [ordered]@{
                "ID"                = $uuid
                "exeName"           = $finalExe
                "gameName"          = $p.gameName
                "authorName"        = $finalAuthor
                "modifiedDate"      = Format-ISO8601Date $p.modifiedDate
                "createdDate"       = Format-ISO8601Date $p.createdDate
                "sourceName"        = $SourceName
                "sourceUrl"         = $sourceUrl
                "sourceDownloadUrl" = $p.downloadUrl
                "remarks"           = $p.remarks
                "downloadDate"      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                "zipHash"           = $zipHash
                "downloadUrl"       = Get-ProfileDownloadUrl $uuid $p.exeName
            }
            
            # Handle Tags (Heuristics)
            $metaProps["tags"] = Get-HeuristicTags $targetDir $metaProps $displayVariant

            $meta = Finalize-ProfileMetadata $targetDir $metaProps $displayVariant
            $meta = Remove-NullProperties $meta
            Update-GlobalPropsJson $z.FullName $variant $meta
            
            $json = $meta | ConvertTo-Json -Depth 5
            $json | Set-Content (Join-Path $targetDir "ProfileMeta.json") -Encoding utf8
            
            if (-not $Silent) {
                Print-ProfileInfo $meta $z.FullName
            }
        }
    }
}

Finalize-GlobalTracking
