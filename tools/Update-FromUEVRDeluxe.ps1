param(
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

. "$PSScriptRoot\common.ps1"

$SourceName = "uevrdeluxe.org"
$DownloadDir = Join-Path $env:TEMP "uevr_profiles\$SourceName"
$MetaCacheDir = Join-Path $env:TEMP "uevr_profiles\metadata"
$MetadataJson = Join-Path $MetaCacheDir "uevrdeluxe_allprofiles.json"

$ProfilesUrlBase = "https://uevrdeluxefunc.azurewebsites.net/api/profiles"
$AllProfilesUrl  = "https://uevrdeluxefunc.azurewebsites.net/api/allprofiles"

foreach ($d in @($DownloadDir, $MetaCacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Invoke-DeluxeRequest($url) {
    # Stealthy headers mimicking the official Deluxe client behavior
    $headers = @{
        "User-Agent" = "UEVRDeluxe"
        "Accept"     = "application/json"
    }
    return Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
}

# ──────── Phase 1: Metadata & Downloads ───────────────────────────────────────
if ($Download) {
    Write-Host "Fetching all metadata from UEVR Deluxe API..." -ForegroundColor Cyan
    try {
        $allProfiles = Invoke-DeluxeRequest $AllProfilesUrl
        $allProfiles | ConvertTo-Json -Depth 10 | Set-Content $MetadataJson -Encoding utf8
    } catch {
        Write-Warning "Deluxe API failed (Internal Server Error is common). Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }

    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    $failCount = 0
    foreach ($p in $profiles) {
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }
        
        $uuid = if ($p.ID) { $p.ID } else { $p.id }
        $actualExe = if ($p.exeName) { $p.exeName } else { $p.exename }
        if (-not $uuid -or -not $actualExe) { continue }
        
        # Deluxe zip naming: <exeName>_<id>.zip
        $targetFile = Join-Path $DownloadDir "$($actualExe)_$($uuid).zip"
        $sidecar    = $targetFile + ".json"
        
        if (-not (Test-Path $targetFile)) {
            $encodedExe = $actualExe -replace ' ', '%20'
            $url = "$ProfilesUrlBase/$encodedExe/$uuid"
            
            Write-Host "Downloading $($p.gameName) ($actualExe) from $url..." -ForegroundColor Gray
            $success = $false
            $lastErr = $null
            for ($i = 1; $i -le 3; $i++) {
                try {
                    if ($i -gt 1) { Write-Host "  Retry $i/3..." -ForegroundColor Yellow }
                    $delay = Get-Random -Minimum 500 -Maximum 1500
                    Start-Sleep -Milliseconds $delay # Randomized stealth delay
                    
                    # Resolve dates from history or fallback to root property
                    $latestDate  = if ($p.history) { ($p.history | Sort-Object modifiedDate -Descending | Select-Object -First 1).modifiedDate } else { $p.modifiedDate }
                    $oldestDate  = if ($p.history) { ($p.history | Sort-Object modifiedDate | Select-Object -First 1).modifiedDate } else { $p.modifiedDate }

                    $sidecarObj = [ordered]@{
                        "authorName"   = $p.authorName
                        "gameName"     = $p.gameName
                        "exeName"      = $p.exeName
                        "modifiedDate" = $latestDate
                        "createdDate"  = $oldestDate
                        "sourceUrl"    = $url
                        "sourceDownloadUrl" = $url
                        "remarks"      = $p.remarks
                    }

                    $headers = @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" }
                    Invoke-WebRequest -Uri $url -Headers $headers -OutFile $targetFile -ErrorAction Stop
                    Write-Host "  [OK] Download successful." -ForegroundColor Green
                    
                    # Save metadata sidecar
                    $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                    $count++
                    $failCount = 0
                    $success = $true
                    break
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
    $zips = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Write-Host "Processing $($zips.Count) profiles from $SourceName..." -ForegroundColor Cyan

    foreach ($z in $zips) {
        try {
            $sidecar = $z.FullName + ".json"
            
            # Use sidecar if available, else try to find in allprofiles.json
            $extraMeta = if (Test-Path $sidecar) { Get-Content $sidecar -Raw | ConvertFrom-Json } else { $null }
            $p = if (Test-Path $MetadataJson) {
                # Deluxe zip naming is <exeName>_<id>.zip. Grab the last part for the ID.
                $idStr = ($z.BaseName -split '_')[-1]
                $cached = Get-Content $MetadataJson -Raw | ConvertFrom-Json
                $cached | Where-Object { 
                    $thisId = if ($_.ID) { $_.ID } else { $_.id }
                    if (-not $thisId) { return $false }
                    $thisId -ieq $idStr -or $thisId.Replace("-","") -ieq $idStr.Replace("-","") 
                } | Select-Object -First 1
            } else { $null }

            if (-not $p -and -not $extraMeta) { continue }
            if (-not $p) { $p = $extraMeta }

            $zipHash = Get-FileHashMD5 $z.FullName
            
            # Discover profiles within archive
            $discovered = Extract-And-Discover-Profiles $z.FullName $Whitelist $Blacklist
            
            foreach ($d in $discovered) {
                $variant = $d.Variant
                $tempDir = $d.Path
                $uuid = if ($p.ID) { $p.ID } elseif ($p.id) { $p.id } elseif ($extraMeta.ID) { $extraMeta.ID } else { $extraMeta.id }
                $uuid = Get-OrCreateUUID $uuid
                
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

                $actualExe = if ($p.exeName) { $p.exeName } else { $p.exename }
                $cleanId = $uuid.Replace("-", "").ToLower()
                $encodedExe = [uri]::EscapeDataString($actualExe)
                $sourceUrl = "$ProfilesUrlBase/$encodedExe/$cleanId"
                $latestDate = if ($p.history) { ($p.history | Sort-Object modifiedDate -Descending | Select-Object -First 1).modifiedDate } else { $p.modifiedDate }
                $oldestDate = if ($p.history) { ($p.history | Sort-Object modifiedDate | Select-Object -First 1).modifiedDate } else { $p.modifiedDate }

                $finalExe = if ($extraMeta.exeName) { $extraMeta.exeName } elseif ($p.exeName) { $p.exeName } else { $p.exename }
                $finalAuthor = if ($extraMeta.authorName) { $extraMeta.authorName } elseif ($p.authorName) { $p.authorName } else { $p.author }
                $displayVariant = Get-CleanVariantName $variant $finalExe

                $metaProps = [ordered]@{
                    "ID"                = $uuid
                    "exeName"           = $finalExe
                    "gameName"          = if ($extraMeta.gameName) { $extraMeta.gameName } else { $p.gameName }
                    "authorName"        = $finalAuthor
                    "modifiedDate"      = Format-ISO8601Date $(if ($extraMeta.modifiedDate) { $extraMeta.modifiedDate } else { $latestDate })
                    "createdDate"       = Format-ISO8601Date $(if ($extraMeta.createdDate) { $extraMeta.createdDate } else { $oldestDate })
                    "sourceName"        = "uevrdeluxe.org"
                    "sourceUrl"         = if ($extraMeta.sourceUrl) { $extraMeta.sourceUrl } else { $sourceUrl }
                    "sourceDownloadUrl" = if ($extraMeta.sourceDownloadUrl) { $extraMeta.sourceDownloadUrl } else { $sourceUrl }
                    "downloadDate"      = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                    "zipHash"           = $zipHash.ToUpper()
                    "downloadUrl"       = Get-ProfileDownloadUrl $uuid $finalExe
                }

                # Handle Tags (Heuristics only for Deluxe)
                $tagArray = @(Get-HeuristicTags $targetDir $extraMeta $displayVariant)
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
