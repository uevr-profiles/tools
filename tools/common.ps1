# ── Common Configuration & Functions ──────────────────────────────────────────

function Get-ProfileDownloadUrl($profileId, $exeName) {
    if ($null -eq $exeName) { $exeName = $profileId }
    $cleanName = $exeName -replace '[^a-zA-Z0-9]', '_'
    # Target URL for the folder downloader pointing to the profile folder in the repo
    $repoUrl = "https://github.com/uevr-profiles/repo/tree/main/profiles/$($profileId)"
    $encodedUrl = [uri]::EscapeDataString($repoUrl)
    return "https://gitfolderdownloader.github.io/?url=$($encodedUrl)&name=$($cleanName)"
}

$RepoRoot       = Split-Path $PSScriptRoot -Parent
$ProfilesDir    = Join-Path $RepoRoot "profiles"
$SchemaFile     = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"
$Global:SchemaContent = if (Test-Path $SchemaFile) { Get-Content $SchemaFile -Raw } else { $null }

# Progress preference to avoid terminal spam during bulk file operations
$ProgressPreference = 'SilentlyContinue'

# Initialize global memory storage
$Global:TrackingFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$Global:TrackingProps = [ordered]@{}
$Global:TempFolders   = @()

function Get-ISO8601Now {
    return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
}

class ProfileReadme {
    [object]$Metadata
    [string]$Content

    ProfileReadme([object]$meta, [string]$content) {
        $this.Metadata = $meta
        $this.Content = [ProfileReadme]::ExtractDescription($content)
    }

    static [string] ExtractDescription([string]$markdown) {
        if ($null -eq $markdown) { return "" }
        if ($markdown -match "(?si)##\s+Description\s+(.*)") {
            return $matches[1].Trim()
        }
        # If it has a table but no Description header? (unlikely but possible)
        # For now, if no ## Description, assume the whole thing is the description.
        return $markdown.Trim()
    }

    [string] Generate() {
        $meta = $this.Metadata
        $sb = [System.Text.StringBuilder]::new()

        # Banner
        if ($meta.headerPictureUrl) {
            $sb.AppendLine("![$($meta.gameName)]($($meta.headerPictureUrl))")
            $sb.AppendLine()
        }

        # Header
        $title = $meta.gameName
        if ($meta.profileName -and $meta.profileName -ne "[Root]") { $title += " ($($meta.profileName))" }
        $sb.AppendLine("# $title")
        $sb.AppendLine()

        # Table
        $sb.AppendLine("| Property | Value |")
        $sb.AppendLine("| :--- | :--- |")
        $sb.AppendLine("| **Author** | $($meta.authorName) |")
        $sb.AppendLine("| **Game EXE** | ``$($meta.exeName)`` |")
        if ($meta.gameVersion) { $sb.AppendLine("| **Game Version** | $($meta.gameVersion) |") }
        $sb.AppendLine("| **Source** | [$($meta.sourceName)]($($meta.sourceUrl)) |")
        if ($meta.createdDate) { $sb.AppendLine("| **Created** | $($meta.createdDate) |") }
        if ($meta.modifiedDate) { $sb.AppendLine("| **Modified** | $($meta.modifiedDate) |") }
        if ($meta.tags) {
            $tagStr = ($meta.tags | ForEach-Object { "$_" }) -join ", "
            $sb.AppendLine("| **Tags** | $tagStr |")
        }
        $sb.AppendLine()

        # Description
        if ($this.Content) {
            $sb.AppendLine("## Description")
            $sb.AppendLine()
            $sb.AppendLine($this.Content)
        }

        return $sb.ToString()
    }

    [void] Save([string]$path) {
        $this.Generate() | Set-Content $path -Encoding utf8
    }
}

class ProfileMetadata {
    [string]$ID
    [string]$exeName
    [string]$gameName
    [string]$gameVersion
    [string]$authorName
    [string]$modifiedDate
    [string]$createdDate
    [string]$downloadDate
    [string]$sourceName
    [string]$sourceUrl
    [string]$zipHash
    [string]$downloadUrl
    [string]$sourceDownloadUrl
    [string]$donateURL
    [string]$appID
    [string]$headerPictureUrl
    [Nullable[int]]$minUEVRNightlyNumber
    [Nullable[int]]$maxUEVRNightlyNumber
    [Nullable[bool]]$nullifyPlugins
    [Nullable[bool]]$lateInjection
    [string]$description
    [string]$profileName
    [object[]]$fileCopies
    [string[]]$tags

    ProfileMetadata() {}

    static [ProfileMetadata] FromObject($obj) {
        $meta = [ProfileMetadata]::new()
        if ($null -eq $obj) { return $meta }
        $props = if ($obj -is [System.Collections.IDictionary]) { $obj.Keys } else { $obj.PSObject.Properties.Name }
        foreach ($p in $props) {
            $val = if ($obj -is [System.Collections.IDictionary]) { $obj[$p] } else { $obj.$p }
            if ($null -ne $val -and "$val" -ne "") {
                try { 
                    if ($p -ieq "ID") { $meta.ID = [string]$val }
                    else { $meta.$p = $val }
                } catch {
                    # Silently skip properties that don't match the class structure
                }
            }
        }
        return $meta
    }

    [void] Finalize([string]$targetDir, [string]$profile) {
        $readmeFile = Join-Path $targetDir "README.md"
        
        # 0. Set simple fields
        if ($profile -and $profile -ne "[Root]") {
            $this.profileName = $profile
        }

        # 1. Determine the "Master Description"
        $readmeText = if (Test-Path $readmeFile) { Get-Content $readmeFile -Raw } else { "" }
        $masterDesc = $null
        
        if ($readmeText) { 
            # Extract only the description part to avoid duplicating the table on subsequent runs
            $masterDesc = [ProfileReadme]::ExtractDescription($readmeText)
        } elseif ($this.description) {
            $masterDesc = $this.description
        }

        if ($masterDesc) {
            # 1.1 Generate/Overwrite README.md with enriched content
            $readme = [ProfileReadme]::new($this, $masterDesc)
            $readme.Save($readmeFile)
            
            # 1.2 Truncate the description in the metadata object
            $this.description = Convert-MarkdownToText $masterDesc 100
        }
    }

    [PSCustomObject] GetCleanObject() {
        $newObj = [ordered]@{}
        $names = $this.PSObject.Properties.Name
        foreach ($name in $names) {
            $val = $this.$name
            if ($null -ne $val -and "$val" -ne "") {
                if ($name -eq "tags") { $newObj[$name] = @($val) }
                else { $newObj[$name] = $val }
            }
        }
        return [PSCustomObject]$newObj
    }

    [string] ToJson() {
        return ConvertTo-Json -InputObject ($this.GetCleanObject()) -Depth 5
    }

    [bool] Validate([string]$jsonPath) {
        if (-not $Global:SchemaContent) { return $true }
        $jsonErr = $null
        $res = if ($jsonPath) {
            Test-Json -Path $jsonPath -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        } else {
            Test-Json -Json ($this.ToJson()) -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        }
        if (-not $res -and $jsonErr) {
            foreach ($err in $jsonErr) {
                Write-Host "        - $($err.Exception.Message)" -ForegroundColor Red
            }
        }
        return $res
    }

    [void] Save([string]$targetDir, [string]$archivePath, [string]$profile) {
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        
        $this.Finalize($targetDir, $profile)
        
        # 2. Update Global Tracking
        Update-GlobalPropsJson $archivePath $profile ($this.GetCleanObject())
        
        # 3. Save to disk
        $jsonFile = Join-Path $targetDir "ProfileMeta.json"
        try {
            $this.ToJson() | Set-Content $jsonFile -Encoding utf8
        } catch {
            Write-Error "Failed to write ${jsonFile}: $($_.Exception.Message)"
            throw
        }
        
        # 4. Validate
        if (-not $this.Validate($jsonFile)) {
             Write-Warning "    [!] Metadata validation failed for $($this.gameName) ($jsonFile)"
             throw "JSON Schema validation failed for $($this.gameName) ($($this.ID))."
        }
    }
}

function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 5, $Silent = $false) {
    if (-not $headers["User-Agent"]) {
        $headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    $lastErr = $null
    for ($i = 1; $i -le $retries; $i++) {
        try {
            if ($i -gt 1) { Write-Host "  Retry $i/$retries..." -ForegroundColor Yellow }
            $delay = Get-Random -Minimum 500 -Maximum 1500
            Start-Sleep -Milliseconds $delay
            
            Invoke-WebRequest -Uri $url -Headers $headers -OutFile $targetFile -ErrorAction Stop
            return
        } catch {
            $lastErr = $_.Exception.Message
            Write-Host "  [!] Attempt $i failed: $lastErr" -ForegroundColor Gray
        }
    }
    if (-not $Silent) {
        throw "All download attempts failed: $lastErr"
    } else {
        Write-Warning "  [!] All download attempts failed: $lastErr. Skipping due to -Silent."
    }
}

function Get-MetadataDates($p) {
    # Check if we have a history array (Deluxe)
    if ($p.history -and $p.history.Count -gt 0) {
        $sorted = $p.history | Sort-Object modifiedDate
        return @{
            Modified = $sorted[-1].modifiedDate
            Created  = $sorted[0].modifiedDate
        }
    }
    # Check for direct properties (Profiles uses creationDate.timestampValue)
    $latest = if ($p.modifiedDate) { $p.modifiedDate } elseif ($p.creationDate.timestampValue) { $p.creationDate.timestampValue } else { "" }
    $oldest = if ($p.createdDate) { $p.createdDate } elseif ($p.creationDate.timestampValue) { $p.creationDate.timestampValue } else { $latest }
    
    return @{ Modified = $latest; Created = $oldest }
}

function Format-ISO8601Date($date) {
    if ($null -eq $date -or "$date" -eq "") { return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") }
    try {
        $dt = [DateTime]::Parse($date, [System.Globalization.CultureInfo]::InvariantCulture)
        return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } catch {
        try {
            $dt = [DateTime]::Parse($date)
            return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        } catch {
            return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
}

# Global tracking for diagnostics
$BaseTempDir     = Join-Path $env:TEMP "uevr_profiles"
$GlobalFilesList = Join-Path $BaseTempDir "files.txt"
$GlobalPropsJson = Join-Path $BaseTempDir "props.json"
$MetaCacheDir    = Join-Path $BaseTempDir "metadata"

function Update-GlobalFilesList($relPaths) {
    if ($null -eq $relPaths) { return }
    foreach ($p in $relPaths) {
        $Global:TrackingFiles.Add($p) | Out-Null
    }
}

function Update-GlobalPropsJson($archivePath, $profile, $metaObj) {
    if ($null -eq $metaObj) { return }
    
    $occId = if ($profile -and $profile -ne "[Root]") { "$archivePath | $profile" } else { "$archivePath" }
    # Unique sub-key for this specific iteration
    $occKey = "$occId | $([DateTimeOffset]::Now.ToUnixTimeMilliseconds())_$(Get-Random)"

    foreach ($name in $metaObj.PSObject.Properties.Name) {
        $val = $metaObj.$name
        if (-not $Global:TrackingProps.PSObject.Properties[$name]) {
            Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $name -Value @{}
        }
        $targetBucket = $Global:TrackingProps.$name
        $targetBucket[$occKey] = $val
    }
}

function Move-Item-Smart($source, $destination) {
    if (-not (Test-Path $source)) { return }
    if (-not (Test-Path $destination)) { 
        New-Item -ItemType Directory -Path $destination -Force | Out-Null 
    }
    
    Get-ChildItem -Path $source | ForEach-Object {
        $destPath = Join-Path $destination $_.Name
        if ($_.PSIsContainer) {
            # Recurse if destination already has a directory by this name
            if (Test-Path $destPath -PathType Container) {
                Move-Item-Smart $_.FullName $destPath
            } else {
                Move-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
            }
        } else {
            Move-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
        }
    }
    # Cleanup empty source
    if (Test-Path $source) {
        $rem = Get-ChildItem -Path $source -Recurse -ErrorAction SilentlyContinue
        if ($null -eq $rem -or $rem.Count -eq 0) {
            Remove-Item $source -Force -ErrorAction SilentlyContinue 2>$null
        }
    }
}

function Finalize-GlobalTracking {
    if (-not (Test-Path $BaseTempDir)) { New-Item -ItemType Directory -Path $BaseTempDir -Force | Out-Null }

    # 1. Write unique files list
    if ($Global:TrackingFiles.Count -gt 0) {
        Write-Host "Flushing tracked files to disk ($($Global:TrackingFiles.Count))..." -ForegroundColor Cyan
        $existing = if (Test-Path $GlobalFilesList) { Get-Content $GlobalFilesList -ErrorAction SilentlyContinue } else { @() }
        foreach ($e in $existing) { $Global:TrackingFiles.Add($e) | Out-Null }
        $sorted = $Global:TrackingFiles | Sort-Object
        $sorted | Set-Content $GlobalFilesList -Encoding utf8
    }

    # 2. Write props JSON
    if ($Global:TrackingProps.PSObject.Properties.Count -gt 0) {
        Write-Host "Flushing tracked properties to disk..." -ForegroundColor Cyan
        $existing = if (Test-Path $GlobalPropsJson) { 
            try { Get-Content $GlobalPropsJson -Raw | ConvertFrom-Json } catch { [ordered]@{} }
        } else { [ordered]@{} }
        
        # Merge existing into current
        foreach ($p in $existing.PSObject.Properties) {
            $name = $p.Name
            if (-not $Global:TrackingProps.PSObject.Properties[$name]) {
                Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $name -Value $p.Value
            } else {
                # Merge sub-properties
                foreach ($sub in $p.Value.PSObject.Properties) {
                    if (-not $Global:TrackingProps.$name.PSObject.Properties[$sub.Name]) {
                        Add-Member -InputObject $Global:TrackingProps.$name -MemberType NoteProperty -Name $sub.Name -Value $sub.Value
                    }
                }
            }
        }
        $Global:TrackingProps | ConvertTo-Json -Depth 10 | Set-Content $GlobalPropsJson -Encoding utf8
    }

    if ($Global:TempFolders.Count -gt 0) {
        Write-Host "Cleaning up $($Global:TempFolders.Count) temporary folders..." -ForegroundColor Cyan
        foreach ($f in $Global:TempFolders) {
            if (Test-Path $f) {
                Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue 2>$null
            }
        }
        $Global:TempFolders = @()
    }
}

function Get-HeuristicTags($profileDir, $meta, $profile) {
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    
    # 0. Technical Signals (Strongest)
    $hasMC = $false
    $hasUObject = $false
    if (Test-Path $profileDir) {
        $uDir = Join-Path $profileDir "uobjecthook"
        if (Test-Path $uDir) {
            $hasUObject = $true
            if (Get-ChildItem -Path $uDir -Filter "*_mc_state.json" -Recurse) { $hasMC = $true }
        }
    }

    if ($hasMC) {
        $tagSet.Add("6DOF") | Out-Null
        $tagSet.Add("Motion Controls") | Out-Null
    } elseif ($hasUObject) {
        $tagSet.Add("3DOF") | Out-Null
    }

    # 1. Textual Analysis (Metadata & Files)
    $textSources = @()
    if ($meta.description) { $textSources += $meta.description }
    if ($meta.gameName) { $textSources += $meta.gameName }
    if ($profile) { $textSources += $profile }
    
    # Gather content from top-level non-binary files
    if (Test-Path $profileDir) {
        $files = Get-ChildItem -Path $profileDir -File | Where-Object { $_.Extension -match "txt|md|json|lua" }
        foreach ($f in $files) {
            try {
                $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) { $textSources += $content }
            } catch {}
        }
    }

    $allText = $textSources -join "`n"
    
    # Keyword Detection
    $foundMotion = $allText -match "motion\s+controls"
    $found6DOF   = $allText -match "6\s*dof"
    $found3DOF   = $allText -match "3\s*dof"

    # Contextual Filtering: If profile explicitly identifies as one mode, be skeptical of the other in text
    $is3DOFProfile = $profile -match "3\s*dof"
    $is6DOFProfile = $profile -match "6\s*dof"

    if ($foundMotion) {
        if (-not $is3DOFProfile -or $profile -match "motion") { $tagSet.Add("Motion Controls") | Out-Null }
    }
    if ($found6DOF) {
        if (-not $is3DOFProfile) { $tagSet.Add("6DOF") | Out-Null }
    }
    if ($found3DOF) {
        if (-not $is6DOFProfile) { $tagSet.Add("3DOF") | Out-Null }
    }

    # Final Conflict Strip: If we are certain this is a 3DOF profile, remove any 6DOF tags that bled in
    $finalTags = [System.Collections.Generic.List[string]]::new($tagSet)
    if ($is3DOFProfile) {
        for ($i = $finalTags.Count - 1; $i -ge 0; $i--) {
            if ($finalTags[$i] -match "6\s*dof") { $finalTags.RemoveAt($i) }
        }
    }
    if ($is6DOFProfile) { # Changed from $is6DOFVariant to $is6DOFProfile
        for ($i = $finalTags.Count - 1; $i -ge 0; $i--) {
            if ($finalTags[$i] -match "3\s*dof") { $finalTags.RemoveAt($i) }
        }
    }

    $res = $finalTags | Sort-Object | Select-Object -Unique
    if ($null -eq $res) { return @() }
    return [string[]]$res
}

# Ensure essential directories exist
if (-not (Test-Path $ProfilesDir)) { New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null }

# ── Whitelist Pattern Definitions ────────────────────────────────────────────
function Get-WhitelistPatterns {
    return @(
        "^README\.md$",
        "^ProfileMeta\.json$",
        "^_interaction_profiles_oculus_touch_controller\.json$",
        "^actions\.json$",
        "^binding_rift\.json$",
        "^binding_vive\.json$",
        "^bindings_knuckles\.json$",
        "^bindings_oculus_touch\.json$",
        "^bindings_vive_controller\.json$",
        "^cameras\.txt$",
        "^config\.txt$",
        "^cvars_data\.txt$",
        "^cvars_standard\.txt$",
        "^uevr_nightly_build\.txt$",
        "^user_script\.txt$",
        "^scripts/.*\.lua$",
        "^plugins/.*\.(dll|so)$",
        "^uobjecthook/.*\.json$",
        "^(_EXTRAS|data|libs|paks)/.+"
    )
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    $patterns = Get-WhitelistPatterns
    foreach ($p in $patterns) {
        if ($rel -match $p) { return $true }
    }
    return $false
}

function Is-ProfileFolder($path) {
    if (-not (Test-Path $path)) { return $false }
    $essentials = @("config.txt", "ProfileMeta.json")
    $files = Get-ChildItem -Path $path -File
    foreach ($f in $files) {
        if ($essentials -contains $f.Name) { return $true }
        if ($f.Name -match "^bindings?_.*\.json$") { return $true }
        if ($f.Name -match "^_interaction_profiles_.*\.json$") { return $true }
    }
    return $false
}

function Get-BlacklistPatterns {
    return @(
        "^sdkdump/.*\.(cpp|hpp)$",
        "^plugins/.*\.pdb$",
        "\.bak$",
        "\.org$",
        "^cvardump\.json$"
    )
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    $patterns = Get-BlacklistPatterns
    foreach ($p in $patterns) {
        if ($rel -match $p) { return $true }
    }
    return $false
}

function Flatten-Folder($targetDir) {
    $items = Get-ChildItem -Path $targetDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $subDir = $items[0].FullName
        Write-Host "    Found single root directory, flattening: $($items[0].Name)" -ForegroundColor Gray
        Get-ChildItem -Path $subDir | Move-Item -Destination $targetDir -Force
        Remove-Item $subDir -Force
    }
}

function Get-Archive-Entries($path) {
    # Try generic 7z listing first as it handles almost everything
    $out = & 7z l $path -y 2>$null
    if ($LASTEXITCODE -eq 0) {
        # 7zip 'l' output typical line: "2024-03-12 16:35:46 ....        11116         7407  folder/file.txt"
        # We skip lines until we see the "----" separator or match the date pattern
        $names = @()
        $capture = $false
        foreach ($line in $out) {
            if ($line -match "^-+\s+-+") { $capture = $true; continue }
            if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[D.][R.][H.][S.][A.]\s+\d+\s+\d+\s+(.*)$") {
                $names += $matches[1].Trim()
            }
        }
        if ($names.Count -gt 0) { return $names }
    }
    
    # Fallback to .NET for ZIPs if 7z fails or missing
    if ($path.EndsWith(".zip")) {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
            $names = $zip.Entries.FullName
            $zip.Dispose()
            return $names
        } catch { return @() }
    }
    return @()
}

function Expand-Archive-Smart($path, $destination) {
    if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
    # Try 7z first - suppress all output to handle errors internally
    & 7z x $path "-o$destination" -y >$null 2>$null
    if ($LASTEXITCODE -ne 0 -and $path.EndsWith(".zip")) {
        try {
            Expand-Archive -Path $path -DestinationPath $destination -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "    [!] Failed to extract $path with both 7z and Expand-Archive."
        }
    }
}

function Extract-And-Discover-Profiles($sourceArchiveroot, $whitelist, $blacklist, $maxDepth = 5) {
    if ($maxDepth -le 0) { return @() }
    
    # Create temp base and ensure we have the full, long path
    $tempBaseDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "uevr_extract_$(New-Guid)") -Force
    $tempBase = $tempBaseDir.FullName
    $Global:TempFolders += $tempBase
    
    try {
        Expand-Archive-Smart $sourceArchiveroot $tempBase
    } catch {
        Write-Error "    [!] Fatal error during extraction of $sourceArchiveroot"
        return @()
    }
    
    $extracted_archives = @() # Renamed from $profilesFound
    
    # 1. Look for nested archives
    $archiveroots = Get-ChildItem -Path $tempBase -Recurse -Include "*.zip", "*.7z", "*.rar", "*.tar", "*.gz", "*.bz2", "*.xz"
    foreach ($a in $archiveroots) {
        $subContext = $a.FullName.Substring($tempBase.Length).TrimStart('\').Replace('\', ' / ').Replace('.zip', '')
        $subProfiles = Extract-And-Discover-Profiles $a.FullName $whitelist $blacklist ($maxDepth - 1)
        foreach ($sp in $subProfiles) {
            # Update profile name to include sub-archive context
            if ($sp.Profile -and $sp.Profile -ne "[Root]") {
                $sp.Profile = "$subContext / $($sp.Profile)"
            } else {
                $sp.Profile = $subContext
            }
            # Also update ProfileName if it was null/empty (meaning it was root in sub-archive)
            if (-not $sp.ProfileName) {
                $sp.ProfileName = $subContext.Split('/')[-1].Trim()
            }
            $extracted_archives += $sp # Renamed from $profilesFound
        }
        Remove-Item $a.FullName -Force -ErrorAction SilentlyContinue
    }

    # 2. Look for profile folders
    $candidateDirs = Get-ChildItem -Path $tempBase -Recurse -Directory | Where-Object { Is-ProfileFolder $_.FullName }
    if (Is-ProfileFolder $tempBase) { $candidateDirs += Get-Item $tempBase }

    $sortedCandidates = $candidateDirs | Sort-Object { $_.FullName.Length }
    Write-Host "    Found $($sortedCandidates.Count) candidate profile roots..." -ForegroundColor Gray
    
    $uniqueProfiles = @()
    foreach ($f in $sortedCandidates) {
        $alreadyFound = $false
        foreach ($found in $uniqueProfiles) {
            if ($f.FullName.StartsWith($found.FullName + "\")) { $alreadyFound = $true; break }
        }
        if (-not $alreadyFound) { $uniqueProfiles += $f }
    }

    foreach ($folderItem in $uniqueProfiles) {
        $folderPath = $folderItem.FullName
        $rel = $folderPath.Substring($tempBase.Length).TrimStart('\')
        $profile = if ($rel) { $rel.Replace('\', ' / ') } else { "[Root]" }
        
        $targetDir = Join-Path $env:TEMP "uevr_profile_tmp_$(New-Guid)"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        $Global:TempFolders += $targetDir
        
        # Determine ProfileName (folder name)
        $pName = if ($rel) { $folderItem.Name } else { "" }

        # Smart Copy: Only filter if switches are active
        $allFiles = Get-ChildItem -Path $folderPath -Recurse -File
        foreach ($f in $allFiles) {
            $fRel = $f.FullName.Substring($folderPath.Length).TrimStart('\')
            
            $isWhitelisted = if ($whitelist) { Test-Whitelisted $fRel } else { $true }
            $isBlacklisted = if ($blacklist) { Test-Blacklisted $fRel } else { $false }

            if ($isWhitelisted -and -not $isBlacklisted) {
                $fTarget = Join-Path $targetDir $fRel
                $fParent = Split-Path $fTarget -Parent
                if (-not (Test-Path $fParent)) { New-Item -ItemType Directory -Path $fParent -Force | Out-Null }
                Copy-Item $f.FullName -Destination $fTarget -Force -ErrorAction SilentlyContinue
            } else {
                Write-Host "    Filtered: $fRel (WH:$isWhitelisted, BL:$isBlacklisted)" -ForegroundColor DarkRed
            }
        }
        
        if ((Get-ChildItem $targetDir).Count -gt 0) {
            $extracted_archives += [PSCustomObject]@{ Path = $targetDir; Profile = $profile; ProfileName = $pName } # Renamed from $profilesFound
        } else {
            # Partial cleanup if empty
            Remove-Item $targetDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
        }
    }
    # Cleanup postponed until script end via $Global:TempFolders
    return $extracted_archives # Renamed from $profilesFound
}

function Get-DeterministicGuid($seed) {
    if ($seed -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$") {
        return ([guid]$seed).ToString()
    }
    $hasher = [System.Security.Cryptography.MD5]::Create()
    $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($seed))
    return ([guid]$hash).ToString()
}

function Get-OrCreateUUID($p) {
    # 1. If we already have a valid UUID, use it as is
    $id = if ($p.ID) { $p.ID } else { $p.id }
    if ($id -and $id -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$") {
        try { return ([guid]$id).ToString() } catch {}
    }
    
    # 2. Use sourceUrl as the primary stable seed for deterministic hashing
    # For Discord, this will be the permanent message link
    $seedParts = @()
    if ($p.sourceUrl) { $seedParts += $p.sourceUrl }
    elseif ($p.sourceDownloadUrl) { $seedParts += $p.sourceDownloadUrl }
    elseif ($id) { $seedParts += $id }
    
    if ($p.archiveroot) { $seedParts += $p.archiveroot } # Changed from $p.archive
    
    $seed = $seedParts -join "|"
    if (-not $seed) { return [guid]::NewGuid().ToString() }
    
    return Get-DeterministicGuid $seed
}


function Print-ProfileInfo($meta, $archiveroot, $profile) { # Changed from $zipPath to $archiveroot, added $profile
    Write-Host "  - Profile $($meta.ID)" -ForegroundColor Cyan
    Write-Host "    - Game:       $($meta.gameName) ($($meta.exeName))" -ForegroundColor Gray
    Write-Host "    - Author:     $($meta.authorName)" -ForegroundColor Gray
    Write-Host "    - Source:     $($meta.sourceName) ($($meta.sourceUrl))" -ForegroundColor Gray
    Write-Host "    - ZIP:        $(if ($archiveroot) { Split-Path $archiveroot -Leaf } else { 'N/A' })" -ForegroundColor Gray # Changed from $zipPath to $archiveroot
    Write-Host "    - Hash:       $($meta.zipHash)" -ForegroundColor Gray
    Write-Host "    - URL:        $($meta.sourceDownloadUrl)" -ForegroundColor Gray
    
    if ($profile -and $profile -ne "[Root]") {
        Write-Host "    - Profile:    $profile" -ForegroundColor Gray
    }
    if ($archiveroot -and (Test-Path $archiveroot)) { # Changed from $zipPath to $archiveroot
        Write-Host "  - ZIP Content List:" -ForegroundColor Cyan
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($archiveroot) # Changed from $zipPath to $archiveroot
            $zip.Entries | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor DarkGray }
            $zip.Dispose()
        } catch {
            Write-Host "    [!] Failed to list ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - [!] ZIP file not found at $zipPath" -ForegroundColor Red
    }
}

function Get-FileHashMD5($path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Path $path -Algorithm MD5).Hash.ToUpper()
}



function Get-CleanProfileName($profile, $currentExe) {
    if (-not $profile) { return $null }
    $segments = $profile.Split(@(" / "), [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    $validSegments = @()
    foreach ($s in $segments) {
        if ($s -ieq "Root") { continue }
        $cleanS = $s.Replace("-Win64-Shipping", "").Replace("-Win64-DebugGame", "").Replace(".zip", "").Trim()
        $cleanE = if ($currentExe) { $currentExe.Replace("-Win64-Shipping", "").Replace("-Win64-DebugGame", "").Trim() } else { "" }
        if ($cleanE -and $cleanS -ieq $cleanE) { continue }
        if ($s -match "-Win64-(Shipping|DebugGame|Development|Test)$") { continue }
        $validSegments += $s
    }
    if ($validSegments.Count -eq 0) { return $null }
    return $validSegments -join " / "
}

function Convert-MarkdownToText($md, $maxLen = 100) {
    if ($null -eq $md) { return "" }
    $txt = $md -replace '(?m)^#+\s+', ''
    $txt = $txt -replace '\*\*|__', ''
    $txt = $txt -replace '\*|_', ''
    $txt = $txt -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    $txt = $txt -replace '`', ''
    $txt = $txt -replace '(?m)^\s*>\s+', ''
    $txt = $txt -replace '(?m)^\s*[-*+]\s+', ''
    $txt = $txt -replace '\r?\n', ' '
    $txt = $txt.Trim()
    if ($txt.Length -gt $maxLen) {
        return $txt.Substring(0, $maxLen - 3) + "..."
    }
    return $txt
}
