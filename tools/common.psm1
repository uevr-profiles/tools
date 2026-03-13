# ── Common Configuration & Functions ──────────────────────────────────────────

function Get-ProfileDownloadUrl($profileId, $exeName) {
    if ($null -eq $exeName) { $exeName = $profileId }
    $cleanName = $exeName -replace '[^a-zA-Z0-9]', '_'
    $repoUrl = "https://github.com/uevr-profiles/repo/tree/main/profiles/$($profileId)"
    $encodedUrl = [uri]::EscapeDataString($repoUrl)
    return "https://gitfolderdownloader.github.io/?url=$($encodedUrl)&name=$($cleanName)"
}

$Global:RepoRoot       = Split-Path $PSScriptRoot -Parent
$Global:ProfilesDir    = Join-Path $Global:RepoRoot "profiles"
$Global:SchemaFile     = Join-Path $Global:RepoRoot "schemas" "ProfileMeta.schema.json"
$Global:SchemaContent  = if (Test-Path $Global:SchemaFile) { Get-Content $Global:SchemaFile -Raw } else { $null }
$Global:BaseTempDir    = Join-Path $env:TEMP "uevr_profiles"
$Global:MetaCacheDir   = Join-Path $Global:BaseTempDir "metadata"

$ProgressPreference = 'SilentlyContinue'
$Global:TrackingFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$Global:TrackingProps = [ordered]@{}
$Global:TempFolders   = @()

function Get-ISO8601Now { return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") }

function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 5, $Silent = $false) {
    if (-not $headers["User-Agent"]) { $headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
    $lastErr = $null
    for ($i = 1; $i -le $retries; $i++) {
        try {
            if ($i -gt 1) { Write-Host "  Retry $i/$retries..." -ForegroundColor Yellow }
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 1500)
            Invoke-WebRequest -Uri $url -Headers $headers -OutFile $targetFile -ErrorAction Stop
            return
        } catch { $lastErr = $_.Exception.Message; Write-Host "  [!] Attempt $i failed: $lastErr" -ForegroundColor Gray }
    }
    if (-not $Silent) { throw "All download attempts failed: $lastErr" }
    else { Write-Warning "  [!] All download attempts failed: $lastErr. Skipping due to -Silent." }
}

function Get-MetadataDates($p) {
    if ($p.history -and $p.history.Count -gt 0) {
        $sorted = $p.history | Sort-Object modifiedDate
        return @{ Modified = $sorted[-1].modifiedDate; Created  = $sorted[0].modifiedDate }
    }
    $latest = ""
    if ($p.modifiedDate) { $latest = $p.modifiedDate }
    elseif ($p.creationDate.timestampValue) { $latest = $p.creationDate.timestampValue }
    
    $oldest = ""
    if ($p.createdDate) { $oldest = $p.createdDate }
    elseif ($p.creationDate.timestampValue) { $oldest = $p.creationDate.timestampValue }
    else { $oldest = $latest }
    
    return @{ Modified = $latest; Created = $oldest }
}

function Format-ISO8601Date($date) {
    if ($null -eq $date -or "$date" -eq "") { return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") }
    try { return [DateTime]::Parse($date, [System.Globalization.CultureInfo]::InvariantCulture).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }
    catch { try { return [DateTime]::Parse($date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") } catch { return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") } }
}

function Update-GlobalFilesList($relPaths) { if ($null -eq $relPaths) { return }; foreach ($p in $relPaths) { $Global:TrackingFiles.Add($p) | Out-Null } }

function Update-GlobalPropsJson($archivePath, $profile, $metaObj) {
    if ($null -eq $metaObj) { return }
    $occId = $archivePath
    if ($profile -and $profile -ne "[Root]") { $occId = "$archivePath | $profile" }
    
    $occKey = "$occId | $([DateTimeOffset]::Now.ToUnixTimeMilliseconds())_$(Get-Random)"
    foreach ($name in $metaObj.PSObject.Properties.Name) {
        $val = $metaObj.$name
        if (-not $Global:TrackingProps.PSObject.Properties[$name]) { Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $name -Value @{} }
        $Global:TrackingProps.$name[$occKey] = $val
    }
}

function Move-Item-Smart($source, $destination) {
    if (-not (Test-Path $source)) { return }; if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
    Get-ChildItem -Path $source | ForEach-Object {
        $destPath = Join-Path $destination $_.Name
        if ($_.PSIsContainer) { if (Test-Path $destPath -PathType Container) { Move-Item-Smart $_.FullName $destPath } else { Move-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue } }
        else { Move-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path $source) { if (-not (Get-ChildItem -Path $source -Recurse -ErrorAction SilentlyContinue)) { Remove-Item $source -Force -ErrorAction SilentlyContinue 2>$null } }
}

function Finalize-GlobalTracking {
    if (-not (Test-Path $Global:BaseTempDir)) { New-Item -ItemType Directory -Path $Global:BaseTempDir -Force | Out-Null }
    if ($Global:TrackingFiles.Count -gt 0) {
        $GlobalFilesList = Join-Path $Global:BaseTempDir "files.txt"
        $existing = if (Test-Path $GlobalFilesList) { Get-Content $GlobalFilesList -ErrorAction SilentlyContinue } else { @() }
        foreach ($e in $existing) { $Global:TrackingFiles.Add($e) | Out-Null }
        $Global:TrackingFiles | Sort-Object | Set-Content $GlobalFilesList -Encoding utf8
    }
    if ($Global:TrackingProps.PSObject.Properties.Count -gt 0) {
        $GlobalPropsJson = Join-Path $Global:BaseTempDir "props.json"
        $existing = if (Test-Path $GlobalPropsJson) { try { Get-Content $GlobalPropsJson -Raw | ConvertFrom-Json } catch { [ordered]@{} } } else { [ordered]@{} }
        foreach ($p in $existing.PSObject.Properties) {
            if (-not $Global:TrackingProps.PSObject.Properties[$p.Name]) { Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $p.Name -Value $p.Value }
            else { foreach ($sub in $p.Value.PSObject.Properties) { if (-not $Global:TrackingProps.$($p.Name).PSObject.Properties[$sub.Name]) { Add-Member -InputObject $Global:TrackingProps.$($p.Name) -MemberType NoteProperty -Name $sub.Name -Value $sub.Value } } }
        }
        $Global:TrackingProps | ConvertTo-Json -Depth 10 | Set-Content $GlobalPropsJson -Encoding utf8
    }
    foreach ($f in $Global:TempFolders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue 2>$null } }; $Global:TempFolders = @()
}

function Get-HeuristicTags($profileDir, $meta, $profile) {
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $hasMC = $false; $hasUObject = $false
    if (Test-Path $profileDir) {
        $uDir = Join-Path $profileDir "uobjecthook"; if (Test-Path $uDir) { $hasUObject = $true; if (Get-ChildItem -Path $uDir -Filter "*_mc_state.json" -Recurse) { $hasMC = $true } }
    }
    if ($hasMC) { $tagSet.Add("6DOF") | Out-Null; $tagSet.Add("Motion Controls") | Out-Null } elseif ($hasUObject) { $tagSet.Add("3DOF") | Out-Null }
    $textSources = @()
    if ($meta.description) { $textSources += $meta.description }
    if ($meta.gameName) { $textSources += $meta.gameName }
    if ($profile) { $textSources += $profile }
    if (Test-Path $profileDir) { Get-ChildItem -Path $profileDir -File | Where-Object { $_.Extension -match "txt|md|json|lua" } | ForEach-Object { try { $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue; if ($c) { $textSources += $c } } catch {} } }
    $allText = $textSources -join "`n"
    if ($allText -match "motion\s+controls") { if (-not ($profile -match "3\s*dof")) { $tagSet.Add("Motion Controls") | Out-Null } }
    if ($allText -match "6\s*dof") { if (-not ($profile -match "3\s*dof")) { $tagSet.Add("6DOF") | Out-Null } }
    if ($allText -match "3\s*dof") { if (-not ($profile -match "6\s*dof")) { $tagSet.Add("3DOF") | Out-Null } }
    $res = $tagSet | Sort-Object | Select-Object -Unique; return if ($null -eq $res) { @() } else { [string[]]$res }
}

function Get-WhitelistPatterns { return @("^README\.md$","^ProfileMeta\.json$","^_interaction_profiles_oculus_touch_controller\.json$","^actions\.json$","^binding_rift\.json$","^binding_vive\.json$","^bindings_knuckles\.json$","^bindings_oculus_touch\.json$","^bindings_vive_controller\.json$","^cameras\.txt$","^config\.txt$","^cvars_data\.txt$","^cvars_standard\.txt$","^uevr_nightly_build\.txt$","^user_script\.txt$","^scripts/.*\.lua$","^plugins/.*\.(dll|so)$","^uobjecthook/.*\.json$","^(_EXTRAS|data|libs|paks)/.+") }
function Test-Whitelisted($relPath) { $rel = $relPath.Replace('\', '/').Trim('/'); foreach ($p in Get-WhitelistPatterns) { if ($rel -match $p) { return $true } }; return $false }
function Is-ProfileFolder($path) { if (-not (Test-Path $path)) { return $false }; $essentials = @("config.txt", "ProfileMeta.json"); foreach ($f in Get-ChildItem -Path $path -File) { if ($essentials -contains $f.Name -or $f.Name -match "^bindings?_.*\.json$" -or $f.Name -match "^_interaction_profiles_.*\.json$") { return $true } }; return $false }
function Get-BlacklistPatterns { return @("^sdkdump/.*\.(cpp|hpp)$","^plugins/.*\.pdb$","\.bak$","\.org$","^cvardump\.json$") }
function Test-Blacklisted($relPath) { $rel = $relPath.Replace('\', '/').Trim('/'); foreach ($p in Get-BlacklistPatterns) { if ($rel -match $p) { return $true } }; return $false }

function Get-Archive-Entries($path) {
    $out = & 7z l $path -y 2>$null; if ($LASTEXITCODE -eq 0) { $names = @(); $capture = $false; foreach ($line in $out) { if ($line -match "^-+\s+-+") { $capture = $true; continue }; if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[D.][R.][H.][S.][A.]\s+\d+\s+\d+\s+(.*)$") { $names += $matches[1].Trim() } }; if ($names.Count -gt 0) { return $names } }
    if ($path.EndsWith(".zip")) { try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue; $zip = [System.IO.Compression.ZipFile]::OpenRead($path); $names = $zip.Entries.FullName; $zip.Dispose(); return $names } catch { return @() } }; return @()
}

function Expand-Archive-Smart($path, $destination) { if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }; & 7z x $path "-o$destination" -y >$null 2>$null; if ($LASTEXITCODE -ne 0 -and $path.EndsWith(".zip")) { try { Expand-Archive -Path $path -DestinationPath $destination -Force } catch {} } }

function Extract-And-Discover-Profiles($sourceArchiveroot, $whitelist, $blacklist, $maxDepth = 5) {
    if ($maxDepth -le 0) { return @() }
    $tempBaseDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "uevr_extract_$(New-Guid)") -Force
    $tempBase = $tempBaseDir.FullName
    $Global:TempFolders += $tempBase
    try { Expand-Archive-Smart $sourceArchiveroot $tempBase } catch { return @() }
    $extracted_archives = @()
    foreach ($a in Get-ChildItem -Path $tempBase -Recurse -Include "*.zip", "*.7z", "*.rar", "*.tar", "*.gz", "*.bz2", "*.xz") {
        $subContext = $a.FullName.Substring($tempBase.Length).TrimStart('\').Replace('\', ' / ').Replace('.zip', '')
        $subProfiles = Extract-And-Discover-Profiles $a.FullName $whitelist $blacklist ($maxDepth - 1)
        foreach ($sp in $subProfiles) {
            if ($sp.Profile -and $sp.Profile -ne "[Root]") { $sp.Profile = "$subContext / $($sp.Profile)" }
            else { $sp.Profile = $subContext }
            if (-not $sp.ProfileName) { $sp.ProfileName = $subContext.Split('/')[-1].Trim() }
            $extracted_archives += $sp
        }
        Remove-Item $a.FullName -Force -ErrorAction SilentlyContinue
    }
    $candidateDirs = Get-ChildItem -Path $tempBase -Recurse -Directory | Where-Object { Is-ProfileFolder $_.FullName }
    if (Is-ProfileFolder $tempBase) { $candidateDirs += Get-Item $tempBase }
    $uniqueProfiles = @()
    foreach ($f in ($candidateDirs | Sort-Object { $_.FullName.Length })) {
        $alreadyFound = $false
        foreach ($found in $uniqueProfiles) { if ($f.FullName.StartsWith($found.FullName + "\")) { $alreadyFound = $true; break } }
        if (-not $alreadyFound) { $uniqueProfiles += $f }
    }
    foreach ($folderItem in $uniqueProfiles) {
        $folderPath = $folderItem.FullName
        $rel = $folderPath.Substring($tempBase.Length).TrimStart('\')
        $profile = "[Root]"
        if ($rel) { $profile = $rel.Replace('\', ' / ') }
        
        $targetDir = Join-Path $env:TEMP "uevr_profile_tmp_$(New-Guid)"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        $Global:TempFolders += $targetDir
        foreach ($f in Get-ChildItem -Path $folderPath -Recurse -File) {
            $fRel = $f.FullName.Substring($folderPath.Length).TrimStart('\')
            $isWhite = $true
            if ($whitelist) { $isWhite = Test-Whitelisted $fRel }
            $isBlack = $false
            if ($blacklist) { $isBlack = Test-Blacklisted $fRel }
            
            if ($isWhite -and -not $isBlack) {
                $fTarget = Join-Path $targetDir $fRel
                $fParent = Split-Path $fTarget -Parent
                if (-not (Test-Path $fParent)) { New-Item -ItemType Directory -Path $fParent -Force | Out-Null }
                Copy-Item $f.FullName -Destination $fTarget -Force -ErrorAction SilentlyContinue
            }
        }
        if ((Get-ChildItem $targetDir).Count -gt 0) {
            $extracted_archives += [PSCustomObject]@{
                Path = $targetDir
                Profile = $profile
                ProfileName = if ($rel) { $folderItem.Name } else { "" }
            }
        } else { Remove-Item $targetDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null }
    }
    return $extracted_archives
}

function Get-DeterministicGuid($seed) { if ($seed -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$") { return ([guid]$seed).ToString() }; $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($seed)); return ([guid]$hash).ToString() }
function Get-OrCreateUUID($p) {
    $id = ""
    if ($p.ID) { $id = $p.ID } elseif ($p.id) { $id = $p.id }
    if ($id -and $id -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$") { try { return ([guid]$id).ToString() } catch {} }
    $seedParts = @()
    if ($p.sourceUrl) { $seedParts += $p.sourceUrl }
    elseif ($p.sourceDownloadUrl) { $seedParts += $p.sourceDownloadUrl }
    elseif ($id) { $seedParts += $id }
    if ($p.archive) { $seedParts += $p.archive }
    $seed = $seedParts -join "|"
    return if (-not $seed) { [guid]::NewGuid().ToString() } else { Get-DeterministicGuid $seed }
}

function Print-ProfileInfo($meta, $archiveroot, $profile) {
    Write-Host "  - Profile $($meta.ID)" -ForegroundColor Cyan
    Write-Host "    - Game:       $($meta.gameName) ($($meta.exeName))" -ForegroundColor Gray
    Write-Host "    - Author:     $($meta.authorName)" -ForegroundColor Gray
    Write-Host "    - Source:     $($meta.sourceName) ($($meta.sourceUrl))" -ForegroundColor Gray
    $zipName = "N/A"
    if ($archiveroot) { $zipName = Split-Path $archiveroot -Leaf }
    Write-Host "    - ZIP:        $zipName" -ForegroundColor Gray
    Write-Host "    - Hash:       $($meta.zipHash)" -ForegroundColor Gray
    Write-Host "    - URL:        $($meta.sourceDownloadUrl)" -ForegroundColor Gray
    if ($profile -and $profile -ne "[Root]") { Write-Host "    - Profile:    $profile" -ForegroundColor Gray }
    if ($archiveroot -and (Test-Path $archiveroot)) {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($archiveroot)
            $zip.Entries | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor DarkGray }
            $zip.Dispose()
        } catch { Write-Host "    [!] Failed to list ZIP contents: $($_.Exception.Message)" -ForegroundColor Red }
    }
}

function Get-FileHashMD5($path) { if (-not (Test-Path $path)) { return $null }; return (Get-FileHash -Path $path -Algorithm MD5).Hash.ToUpper() }
function Convert-MarkdownToText($md, $maxLen = 100) { if ($null -eq $md) { return "" }; $txt = (((($md -replace '(?m)^#+\s+', '') -replace '\*\*|__', '') -replace '\[([^\]]+)\]\([^\)]+\)', '$1') -replace '`', '') -replace '\r?\n', ' '; $txt = $txt.Trim(); return if ($txt.Length -gt $maxLen) { $txt.Substring(0, $maxLen - 3) + "..." } else { $txt } }

Export-ModuleMember -Function * -Variable *
