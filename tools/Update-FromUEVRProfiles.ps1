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
            $f = $doc.fields
            $obj = @{
                "id"           = Split-Path $doc.name -Leaf
                "gameName"     = $f.gameName.stringValue
                "authorName"   = $f.authorName.stringValue
                "modifiedDate" = $f.modifiedDate.timestampValue
                "createdDate"  = $f.createdDate.timestampValue
                "exeName"      = $f.exeName.stringValue
                "downloadUrl"  = $f.downloadUrl.stringValue
                "remarks"      = $f.remarks.stringValue
            }
            $allProfiles += $obj
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
                $payload = @{ "url" = $p.downloadUrl } | ConvertTo-Json
                $delay = Get-Random -Minimum 500 -Maximum 1500
                Start-Sleep -Milliseconds $delay # Stealth delay
                
                Invoke-WebRequest -Method Post -Uri $DownloadFuncUrl -Body $payload -ContentType "application/json" -OutFile $targetFile -ErrorAction Stop
                
                # Save metadata sidecar for extraction phase
                $p | ConvertTo-Json | Set-Content $sidecar -Encoding utf8
                $count++
            } catch {
                Write-Host "  [!] Failed: $($_.Exception.Message)" -ForegroundColor Red
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

            $displayVariant = Get-CleanVariantName $variant $p.exeName
            
            $metaProps = [ordered]@{
                "ID"                = $uuid
                "exeName"           = $p.exeName
                "gameName"          = $p.gameName
                "authorName"        = $p.authorName
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
