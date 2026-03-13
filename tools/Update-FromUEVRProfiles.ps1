param(
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

. "$PSScriptRoot\common.ps1"

$SourceName  = "uevr-profiles.com"
$DownloadDir = Join-Path $BaseTempDir $SourceName
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

                $variantExe = if ($vf.exeName.stringValue) { $vf.exeName.stringValue } else { "" }
                $obj = @{
                    "id"           = $profileId
                    "gameName"     = $gameName
                    "authorName"   = $vf.author.stringValue
                    "modifiedDate" = $vf.creationDate.timestampValue
                    "createdDate"  = $vf.creationDate.timestampValue
                    "exeName"      = if ($variantExe) { $variantExe } elseif ($topExe) { $topExe } else { "" }
                    "downloadUrl"  = $dlUrl
                    "archive"      = if ($archiveFile) { $archiveFile } else { "$($profileId).zip" }
                    "description"  = $vf.description.stringValue
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
    $failCount = 0
    foreach ($p in $profiles) {
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }

        $targetFile = Join-Path $DownloadDir "$($p.id).zip"
        $sidecar    = Join-Path $DownloadDir "$($p.id).zip.json"
        
        if (-not (Test-Path $targetFile)) {
            $msg = "Downloading: $($p.gameName)"
            if ($p.exeName) { $msg += " ($($p.exeName))" }
            Write-Host "$msg..." -ForegroundColor Gray
            $success = $false
            $lastErr = $null
            for ($i = 1; $i -le 3; $i++) {
                try {
                    if ($i -gt 1) { Write-Host "  Retry $i/3..." -ForegroundColor Yellow }
                    $delay = Get-Random -Minimum 500 -Maximum 1500
                    Start-Sleep -Milliseconds $delay # Stealth delay

                    $UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                    
                    # Try Cloud Function first
                    Write-Host "  Trying cloud function..." -ForegroundColor Gray
                    try {
                        $payload = @{ "data" = @{ "file" = $p.archive } } | ConvertTo-Json
                        $response = Invoke-RestMethod -Method Post -Uri $DownloadFuncUrl -Body $payload -ContentType "application/json" -UserAgent $UA -ErrorAction Stop
                        
                        if ($response.result.url) {
                            Invoke-WebRequest -Uri $response.result.url -OutFile $targetFile -UserAgent $UA -ErrorAction Stop
                            Write-Host "  [OK] Downloaded via cloud function." -ForegroundColor Green
                            $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                            $count++
                            $failCount = 0
                            $success = $true
                            break
                        } else {
                            throw "Cloud function did not return a valid download URL."
                        }
                    } catch {
                        # Fallback to direct download
                        Write-Host "  [!] Cloud function failed, trying direct download..." -ForegroundColor Yellow
                        Invoke-WebRequest -Uri $p.downloadUrl -OutFile $targetFile -UserAgent $UA -ErrorAction Stop
                        Write-Host "  [OK] Direct download successful." -ForegroundColor Green
                        
                        # Save metadata sidecar for extraction phase
                        $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                        $count++
                        $failCount = 0
                        $success = $true
                        break
                    }
                } catch {
                    $lastErr = $_.Exception.Message
                    Write-Host "  [!] Attempt $i failed: $lastErr" -ForegroundColor Gray
                }
            }

            if (-not $success) {
                Write-Host "  [!] All download attempts failed: $lastErr" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
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
        try {
            $sidecar = $z.FullName + ".json"
            if (-not (Test-Path $sidecar)) { continue }
            $p = Get-Content $sidecar -Raw | ConvertFrom-Json

            $zipHash = Get-FileHashMD5 $z.FullName
            $sourceUrl = "https://uevr-profiles.com/game/$($p.id)"
            
            # Discover profiles within archive (handles nested structures)
            $discovered = Extract-And-Discover-Profiles $z.FullName $Whitelist $Blacklist
            
            if ($null -eq $discovered -or $discovered.Count -eq 0) {
                # This could be a legitimate filter or an error. 
                # If it's a structural failure, Extract-And-Discover-Profiles usually yields 0 results.
                # However, for now, let's just warn unless we want to be very strict.
                # If the user wants to fail on error, structural errors in zips should throw.
            }

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
                
                Move-Item-Smart $tempDir $targetDir

                # Final fallback for exeName: try to find any exe in the profile doc or variants
                $finalExe = if ($extraMeta.exeName) { $extraMeta.exeName } elseif ($p.exeName) { $p.exeName } else { $p.exename }
                if (-not $finalExe) {
                    Write-Warning "  [!] Missing exeName for $($p.gameName). Falling back to gameName slug."
                    $finalExe = $p.gameName -replace '[^a-zA-Z0-9]', ''
                }

                $finalAuthor = if ($extraMeta.authorName) { $extraMeta.authorName } elseif ($p.authorName) { $p.authorName } else { $p.author }
                $displayVariant = Get-CleanVariantName $variant $finalExe
                
                $metaProps = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $finalExe
                    "gameName"          = $p.gameName
                    "authorName"        = $finalAuthor
                    "modifiedDate"      = Format-ISO8601Date $p.modifiedDate
                    "createdDate"       = Format-ISO8601Date $p.createdDate
                    "sourceName"        = "uevr-profiles.com"
                    "sourceUrl"         = $sourceUrl
                    "sourceDownloadUrl" = $p.downloadUrl
                    "description"       = $p.description
                    "downloadDate"      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                    "zipHash"           = $zipHash.ToUpper()
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $finalExe
                }
                
                # Handle Tags (Heuristics)
                $tagArray = @(Get-HeuristicTags $targetDir $metaProps $displayVariant)
                if ($tagArray -and $tagArray.Count -gt 0) {
                    $metaProps["tags"] = $tagArray
                }

                $meta = Finalize-ProfileMetadata $targetDir $metaProps $displayVariant
                $meta = Remove-NullProperties $meta
                Update-GlobalPropsJson $z.FullName $variant $meta
                
                $jsonFile = Join-Path $targetDir "ProfileMeta.json"
                $meta | ConvertTo-Json -Depth 5 | Set-Content $jsonFile -Encoding utf8
                
                if (-not (Test-Json -Path $jsonFile -Schema (Get-Content $SchemaFile -Raw))) {
                    throw "JSON Schema validation failed for $($p.gameName) ($uuid)."
                }

                if (-not $Silent) {
                    Print-ProfileInfo $meta $z.FullName
                }
            }
        } catch {
            Write-Host "  [!] Extraction failed for $($z.Name): $($_.Exception.Message)" -ForegroundColor Red
            if (-not $Silent) { throw "Fatal: Profile processing error. Stopping because -Silent is not set." }
        }
    }
}

Finalize-GlobalTracking
