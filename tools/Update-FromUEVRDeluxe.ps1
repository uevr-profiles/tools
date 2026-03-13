param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

. "$PSScriptRoot\common.ps1"

$SourceName  = "uevrdeluxe.org"
$DownloadDir = Join-Path $BaseTempDir $SourceName
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

function Fetch-UEVRDeluxeMetadata {
    Write-Host "Fetching all metadata from UEVR Deluxe API..." -ForegroundColor Cyan
    try {
        $allProfiles = Invoke-DeluxeRequest $AllProfilesUrl
        $allProfiles | ConvertTo-Json -Depth 10 | Set-Content $MetadataJson -Encoding utf8
        Write-Host "  [OK] Metadata fetched and cached: $($allProfiles.Count) profiles." -ForegroundColor Green
    } catch {
        Write-Warning "Deluxe API failed (Internal Server Error is common). Falling back to cached metadata."
        if (-not (Test-Path $MetadataJson)) { throw "No metadata cache found. Cannot continue." }
    }
}

function Download-UEVRDeluxeProfiles {
    if (-not (Test-Path $MetadataJson)) {
        Write-Error "Metadata not found at $MetadataJson. Run with -Fetch first."
        return
    }

    $profiles = Get-Content $MetadataJson -Raw | ConvertFrom-Json
    $count = 0
    $failCount = 0
    $total = $profiles.Count
    $index = 0
    foreach ($p in $profiles) {
        $index++
        if ($count -ge $ProfileLimit) { break }
        if ($failCount -ge 5) { Write-Error "Too many consecutive failures in $SourceName. Stopping."; break }
        
        $uuid = Get-OrCreateUUID $p
        $p | Add-Member -MemberType NoteProperty -Name "uuid" -Value $uuid -ErrorAction SilentlyContinue

        $actualExe = if ($p.exeName) { $p.exeName } else { $p.exename }
        if (-not $uuid -or -not $actualExe) { continue }
        
        # Deluxe zip naming: <uuid>.zip
        $targetFile = Join-Path $DownloadDir "$uuid.zip"
        $sidecar    = $targetFile + ".json"
        
        if (-not (Test-Path $targetFile)) {
            $encodedExe = $actualExe -replace ' ', '%20'
            $url = "$ProfilesUrlBase/$encodedExe/$uuid"
            
            $msg = "[$index/$total] Downloading $($p.gameName)"
            if ($actualExe) { $msg += " ($actualExe)" }
            Write-Host "$msg from $url..." -ForegroundColor Gray

            try {
                Invoke-WebRequestWithRetry -url $url -targetFile $targetFile -headers @{ "User-Agent" = "UEVRDeluxe"; "Accept" = "application/json" } -Silent $Silent
                
                $dates = Get-MetadataDates $p
                $sidecarObj = [ordered]@{
                    "authorName"   = $p.authorName
                    "gameName"     = $p.gameName
                    "exeName"      = $p.exeName
                    "modifiedDate" = $dates.Modified
                    "createdDate"  = $dates.Created
                    "sourceUrl"    = $url
                    "sourceDownloadUrl" = $url
                    "description"  = $p.remarks
                    "uuid"         = $uuid
                }
                $sidecarObj | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++
                $failCount = 0
                Write-Host "  [OK] Download successful." -ForegroundColor Green
            } catch {
                Write-Host "  [!] All download attempts failed: $($_.Exception.Message)" -ForegroundColor Red
                $failCount++
                if (-not $Silent) { throw "Fatal: Download failed for $($p.gameName). Stopping because -Silent is not set." }
            }
        }
    }
}

function Extract-UEVRDeluxeProfiles {
    $archiveroots = Get-ChildItem -Path $DownloadDir -Filter "*.zip"
    Write-Host "Processing $($archiveroots.Count) profiles from $SourceName..." -ForegroundColor Cyan

    foreach ($archiveroot in $archiveroots) {
        try {
            $sidecar = $archiveroot.FullName + ".json"
            
            # Use sidecar if available, else try to find in allprofiles.json
            if (Test-Path $sidecar) {
                $extraMeta = Get-Content $sidecar -Raw | ConvertFrom-Json
                $uuid = $extraMeta.uuid
            } else {
                continue
            }

            $zipHash = Get-FileHashMD5 $archiveroot.FullName
            
            # Discover profiles within archive
            $extracted_archives = Extract-And-Discover-Profiles $archiveroot.FullName $Whitelist $Blacklist
            
            foreach ($extracted_archive in $extracted_archives) {
                $profile = $extracted_archive.Profile
                $tempDir = $extracted_archive.Path
                
                $targetDir = Join-Path $ProfilesDir $uuid
                if ($profile -and $profile -ne "[Root]") {
                    $vPath = $profile -replace ' / ', '\'
                    $targetDir = Join-Path $targetDir $vPath
                }
                
                # Move contents
                $relFiles = Get-ChildItem -Path $tempDir -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object { 
                    $_.FullName.Substring($tempDir.Length).TrimStart('\')
                }
                Update-GlobalFilesList $relFiles
                
                Move-Item-Smart $tempDir $targetDir

                # Meta creation
                $meta = [ProfileMetadata]::new()
                $meta.ID                = $uuid
                $meta.exeName           = $extraMeta.exeName
                $meta.gameName          = $extraMeta.gameName
                $meta.authorName        = $extraMeta.authorName
                $meta.modifiedDate      = Format-ISO8601Date $extraMeta.modifiedDate
                $meta.createdDate       = Format-ISO8601Date $extraMeta.createdDate
                $meta.sourceName        = "uevrdeluxe.org"
                $meta.sourceUrl         = $extraMeta.sourceUrl
                $meta.sourceDownloadUrl = $extraMeta.sourceDownloadUrl
                $meta.description       = $extraMeta.description
                $meta.downloadDate      = Get-ISO8601Now
                $meta.zipHash           = $zipHash.ToUpper()
                $meta.downloadUrl       = Get-ProfileDownloadUrl $uuid $extraMeta.exeName

                # Handle Tags (Heuristics only for Deluxe)
                $tagArray = @(Get-HeuristicTags $targetDir $meta $profile)
                if ($tagArray -and $tagArray.Count -gt 0) {
                    $meta.tags = $tagArray
                }

                $meta.Save($targetDir, $archiveroot.FullName, $profile)

                if (-not $Silent) {
                    Print-ProfileInfo $meta $archiveroot.FullName $profile
                }
            }
        } catch {
            Write-Host "  [!] Extraction failed for $($archiveroot.Name): $($_.Exception.Message)" -ForegroundColor Red
            if (-not $Silent) { throw "Fatal: Profile processing error for $($archiveroot.Name). Stopping because -Silent is not set." }
        }
    }
}

# ──────── Main Logic Entry ────────────────────────────────────────────────────
if ($Fetch)    { Fetch-UEVRDeluxeMetadata }
if ($Download) { Download-UEVRDeluxeProfiles }
if ($Extract)  { Extract-UEVRDeluxeProfiles }
