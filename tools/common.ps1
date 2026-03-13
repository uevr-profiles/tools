#region Variables & Configuration
$RepoRoot       = Split-Path $PSScriptRoot -Parent
$RepoRawUrl     = "https://github.com/Bluscream/UnrealVRMod/raw/master"
$ProfilesDir    = Join-Path $RepoRoot "profiles"
$SchemaFile     = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"
$Global:SchemaContent = $null
if (Test-Path $SchemaFile) {
    $Global:SchemaContent = Get-Content $SchemaFile -Raw
}

# Progress preference to avoid terminal spam during bulk file operations
$ProgressPreference = 'SilentlyContinue'

if ($null -eq $Global:Debug) { $Global:Debug = $false }

function Debug-Log($message) {
    if ($Global:Debug) {
        Write-Host "  [DEBUG] $message" -ForegroundColor DarkGray
    }
}

# Initialize global memory storage
$Global:TrackingFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$Global:TrackingProps = [ordered]@{}
$Global:TempFolders   = @()

# Global tracking paths for diagnostics
$BaseTempDir     = Join-Path $env:TEMP "uevr_profiles"
$GlobalFilesList = Join-Path $BaseTempDir "files.txt"
$GlobalPropsJson = Join-Path $BaseTempDir "props.json"
$MetaCacheDir    = Join-Path $BaseTempDir "metadata"

# Ensure essential directories exist
if (-not (Test-Path $ProfilesDir)) { New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null }
#endregion

#region Classes
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
        $props = ($obj -is [System.Collections.IDictionary]) ? $obj.Keys : $obj.PSObject.Properties.Name
        foreach ($p in $props) {
            $val = ($obj -is [System.Collections.IDictionary]) ? $obj[$p] : $obj.$p
            if ($null -ne $val -and "$val" -ne "") {
                try { 
                    if ($p -ieq "ID") { $meta.ID = [string]$val }
                    else { $meta.$p = $val }
                } catch {}
            }
        }
        return $meta
    }

    static [bool] Validate($jsonPath, $jsonText) {
        if (-not $Global:SchemaContent) { return $true }
        $jsonErr = $null
        $res = $null
        if ($jsonPath) {
            $res = Test-Json -Path $jsonPath -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        } else {
            $res = Test-Json -Json $jsonText -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        }
        if (-not $res -and $jsonErr) {
            foreach ($err in $jsonErr) {
                Write-Host "        - $($err.Exception.Message)" -ForegroundColor Red
            }
        }
        return $res
    }

    [bool] ValidateSelf() {
        return [ProfileMetadata]::Validate($null, $this.ToJson())
    }

    [void] Finalize([string]$targetDir, [string]$profile) {
        $readmeFile = Join-Path $targetDir "README.md"
        if ($profile -and $profile -ne "[Root]") { $this.profileName = $profile }
        $readmeText = (Test-Path $readmeFile) ? (Get-Content $readmeFile -Raw) : ""
        $masterDesc = $readmeText ? [ProfileReadme]::ExtractDescription($readmeText) : ($this.description ? $this.description : "")
        if ($masterDesc) {
            $readme = [ProfileReadme]::new($this, $masterDesc)
            $readme.Save($readmeFile)
            $this.description = Convert-MarkdownToText $masterDesc 100
        }
    }

    [PSCustomObject] GetCleanObject() {
        $newObj = [ordered]@{}
        foreach ($name in $this.PSObject.Properties.Name) {
            $val = $this.$name
            if ($null -ne $val -and "$val" -ne "") {
                if ($name -eq "tags") { $newObj[$name] = @($val) }
                else { $newObj[$name] = $val }
            }
        }
        return [PSCustomObject]$newObj
    }

    [string] ToJson() { return ConvertTo-Json -InputObject ($this.GetCleanObject()) -Depth 5 }

    [void] Save([string]$targetDir, [string]$archivePath, [string]$profile) {
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        $this.Finalize($targetDir, $profile)
        Update-GlobalPropsJson $archivePath $profile ($this.GetCleanObject())
        $jsonFile = Join-Path $targetDir "ProfileMeta.json"
        $this.ToJson() | Set-Content $jsonFile -Encoding utf8
        if (-not [ProfileMetadata]::Validate($jsonFile, $null)) { throw "JSON Schema validation failed for $($this.gameName) ($($this.ID))." }
    }
}

class ProfileArchive {
    [string]$Path
    [string[]]$Extensions

    ProfileArchive([string]$path) { $this.Path = $path }

    static [string[]] GetSupportedArchiveExtensions() { return Get-SupportedArchiveExtensions }
    static [string[]] List([string]$path) { return ([ProfileArchive]::new($path)).GetContent() }
    static [void] Extract([string]$path, [string]$destination) { ([ProfileArchive]::new($path)).ExtractTo($destination) }

    [string[]] GetContent() {
        if (-not (Test-Path $this.Path)) { return @() }
        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            $out = & 7z l $this.Path -y 2>$null
            if ($LASTEXITCODE -eq 0) {
                $names = @(); $capture = $false
                foreach ($line in $out) {
                    if ($line -match "^-+\s+-+") { $capture = $true; continue }
                    if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[D.][R.][H.][S.][A.]\s+\d+\s+\d+\s+(.*)$") {
                        $names += $matches[1].Trim()
                    }
                }
                if ($names.Count -gt 0) { return $names }
            }
        }
        if ($this.Path.EndsWith(".zip")) {
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                $zip = [System.IO.Compression.ZipFile]::OpenRead($this.Path)
                $names = $zip.Entries.FullName; $zip.Dispose(); return $names
            } catch { return @() }
        }
        return @()
    }

    [void] ExtractTo([string]$destination) {
        if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
        $extracted = $false
        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            & 7z x $this.Path "-o$destination" -y >$null 2>$null
            if ($LASTEXITCODE -eq 0) { $extracted = $true }
        }
        if (-not $extracted -and $this.Path.EndsWith(".zip")) {
            try { Expand-Archive -Path $this.Path -DestinationPath $destination -Force -ErrorAction SilentlyContinue; $extracted = $true } catch {}
        }
        if (-not $extracted) { throw "Failed to extract archive: $($this.Path) (7z not found or extraction failed)" }
    }
}
#endregion


#region Profile Helpers
function Get-ProfileDownloadUrl($uuid, $exeName) {
    Debug-Log "[common.ps1] Entering Get-ProfileDownloadUrl (ID: $uuid, Exe: $exeName)"
    $baseUrl = "https://github.com/uevr-profiles/repo/tree/main/profiles/$uuid"
    $encodedUrl = [System.Web.HttpUtility]::UrlEncode($baseUrl)
    
    $name = $uuid
    if ($exeName) {
        $name = $exeName.Replace(" ", "_").Replace(".", "_")
    }
    Debug-Log "[common.ps1] Name for downloader: $name"
    
    $res = "https://gitfolderdownloader.github.io/?url=$encodedUrl&name=$name"
    Debug-Log "[common.ps1] Result: $res"
    return $res
}

function Get-ISO8601Now { return [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") }

function Format-DateISO8601($date) {
    if (-not $date) { return $null }
    try {
        return ([DateTime]$date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } catch {
        return $date
    }
}

function Assert-ProfileCount($count, $expected, [switch]$Silent, $stage) {
    if ($expected -ne [int]::MaxValue -and $count -lt $expected) {
        $msg = "$stage count mismatch: Expected at least $expected, got $count."
        if ($Silent) { Write-Warning "$msg Skipping due to -Silent." }
        else { throw "Fatal: $msg Stopping because -Silent is not set." }
    }
}

function Print-ProfileInfo($meta, $archiveroot, $profile) {
    Write-Host "  - Profile $($meta.ID)" -ForegroundColor Cyan
    Write-Host "    - Game:       $($meta.gameName) ($($meta.exeName))" -ForegroundColor Gray
    Write-Host "    - Author:     $($meta.authorName)" -ForegroundColor Gray
    Write-Host "    - Source:     $($meta.sourceName) ($($meta.sourceUrl))" -ForegroundColor Gray
    Write-Host "    - ZIP:        $(if ($archiveroot) { Split-Path $archiveroot -Leaf } else { 'N/A' })" -ForegroundColor Gray
    Write-Host "    - Hash:       $($meta.zipHash)" -ForegroundColor Gray
    Write-Host "    - URL:        $($meta.sourceDownloadUrl)" -ForegroundColor Gray
    
    if ($profile -and $profile -ne "[Root]") {
        Write-Host "    - Profile:    $profile" -ForegroundColor Gray
    }
    if ($archiveroot -and (Test-Path $archiveroot)) {
        Write-Host "  - ZIP Content List:" -ForegroundColor Cyan
        try {
            $contents = [ProfileArchive]::List($archiveroot)
            foreach ($c in $contents) { Write-Host "    $c" -ForegroundColor DarkGray }
        } catch {
            Write-Host "    [!] Failed to list archive contents: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
#endregion

#region Metadata & Tracking Utilities
function Update-GlobalFilesList($relPaths) {
    if ($null -eq $relPaths) { return }
    foreach ($p in $relPaths) { $Global:TrackingFiles.Add($p) | Out-Null }
}

function Update-GlobalPropsJson($archivePath, $profile, $metaObj) {
    if ($null -eq $metaObj) { return }
    $occId = ($profile -and $profile -ne "[Root]") ? "$archivePath | $profile" : "$archivePath"
    $occKey = "$occId | $([DateTimeOffset]::Now.ToUnixTimeMilliseconds())_$(Get-Random)"
    foreach ($name in $metaObj.PSObject.Properties.Name) {
        if (-not $Global:TrackingProps.PSObject.Properties[$name]) {
            Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $name -Value @{}
        }
        $Global:TrackingProps.$name[$occKey] = $metaObj.$name
    }
}

function Finalize-GlobalTracking {
    if (-not (Test-Path $BaseTempDir)) { New-Item -ItemType Directory -Path $BaseTempDir -Force | Out-Null }
    if ($Global:TrackingFiles.Count -gt 0) {
        Write-Host "Flushing tracked files to disk ($($Global:TrackingFiles.Count))..." -ForegroundColor Cyan
        $existing = (Test-Path $GlobalFilesList) ? (Get-Content $GlobalFilesList -ErrorAction SilentlyContinue) : @()
        foreach ($e in $existing) { $Global:TrackingFiles.Add($e) | Out-Null }
        $Global:TrackingFiles | Sort-Object | Set-Content $GlobalFilesList -Encoding utf8
    }
    if ($Global:TrackingProps.PSObject.Properties.Count -gt 0) {
        Write-Host "Flushing tracked properties to disk..." -ForegroundColor Cyan
        $existing = (Test-Path $GlobalPropsJson) ? (try { Get-Content $GlobalPropsJson -Raw | ConvertFrom-Json } catch { [ordered]@{} }) : [ordered]@{}
        foreach ($p in $existing.PSObject.Properties) {
            if (-not $Global:TrackingProps.PSObject.Properties[$p.Name]) {
                Add-Member -InputObject $Global:TrackingProps -MemberType NoteProperty -Name $p.Name -Value $p.Value
            } else {
                foreach ($sub in $p.Value.PSObject.Properties) {
                    if (-not $Global:TrackingProps.$($p.Name).PSObject.Properties[$sub.Name]) {
                        Add-Member -InputObject $Global:TrackingProps.$($p.Name) -MemberType NoteProperty -Name $sub.Name -Value $sub.Value
                    }
                }
            }
        }
        $Global:TrackingProps | ConvertTo-Json -Depth 10 | Set-Content $GlobalPropsJson -Encoding utf8
    }
    if ($Global:TempFolders.Count -gt 0) {
        Write-Host "Cleaning up $($Global:TempFolders.Count) temporary folders..." -ForegroundColor Cyan
        foreach ($f in $Global:TempFolders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue 2>$null } }
        $Global:TempFolders = @()
    }
}
#endregion

#region File & IO Utilities
function Move-Item-Smart($source, $destination) {
    if (-not (Test-Path $source)) { return }
    if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
    Get-ChildItem -Path $source | ForEach-Object {
        $destPath = Join-Path $destination $_.Name
        if ($_.PSIsContainer -and (Test-Path $destPath -PathType Container)) { Move-Item-Smart $_.FullName $destPath }
        else { Move-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path $source) {
        $rem = Get-ChildItem -Path $source -Recurse -ErrorAction SilentlyContinue
        if ($null -eq $rem -or $rem.Count -eq 0) { Remove-Item $source -Force -ErrorAction SilentlyContinue 2>$null }
    }
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

function Get-FileHashMD5($path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Path $path -Algorithm MD5).Hash.ToUpper()
}

function Get-DeterministicGuid($seed) {
    if ($seed -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$") { return ([guid]$seed).ToString() }
    $hasher = [System.Security.Cryptography.MD5]::Create()
    $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($seed))
    return ([guid]$hash).ToString()
}

function Get-OrCreateUUID($p) {
    Debug-Log "[common.ps1] Entering Get-OrCreateUUID"
    $id = $null
    if ($p.ID) { $id = $p.ID } else { $id = $p.id }
    Debug-Log "[common.ps1] Found ID in p: $id"
    
    if ($id -and $id -match "^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$") { 
        try { 
            return ([guid]$id).ToString() 
        } catch {
            Debug-Log "[common.ps1] GUID conversion failed"
        } 
    }
    
    Debug-Log "[common.ps1] Generating UUID from details"
    $seedParts = @()
    if ($p.sourceUrl) { $seedParts += $p.sourceUrl }
    if ($p.sourceDownloadUrl) { $seedParts += $p.sourceDownloadUrl }
    if ($p.gameName) { $seedParts += $p.gameName }
    if ($p.exeName) { $seedParts += $p.exeName }
    
    $seed = $seedParts -join "|"
    Debug-Log "[common.ps1] Seed: $seed"
    $finalUuid = Get-DeterministicGuid $seed
    Debug-Log "[common.ps1] Generated UUID: $finalUuid"
    return $finalUuid
}

function Get-SupportedArchiveExtensions {
    return @(".zip", ".7z", ".rar")
}

function Get-ISO8601Now {
    return (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}
#endregion

#region Filtering Helpers
function Get-WhitelistPatterns {
    return @("^README\.md$","^ProfileMeta\.json$","^_interaction_profiles_oculus_touch_controller\.json$","^actions\.json$","^binding_rift\.json$","^binding_vive\.json$","^bindings_knuckles\.json$","^bindings_oculus_touch\.json$","^bindings_vive_controller\.json$","^cameras\.txt$","^config\.txt$","^cvars_data\.txt$","^cvars_standard\.txt$","^uevr_nightly_build\.txt$","^user_script\.txt$","^scripts/.*\.lua$","^plugins/.*\.(dll|so)$","^uobjecthook/.*\.json$","^(_EXTRAS|data|libs|paks)/.+")
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    foreach ($p in Get-WhitelistPatterns) { if ($rel -match $p) { return $true } }
    return $false
}

function Get-BlacklistPatterns {
    return @("^sdkdump/.*\.(cpp|hpp)$","^plugins/.*\.pdb$","\.bak$","\.org$","^cvardump\.json$")
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    foreach ($p in Get-BlacklistPatterns) { if ($rel -match $p) { return $true } }
    return $false
}

function Is-ProfileFolder($path) {
    if (-not (Test-Path $path)) { return $false }
    $essentials = @("config.txt", "ProfileMeta.json")
    foreach ($f in Get-ChildItem -Path $path -File) {
        if ($essentials -contains $f.Name) { return $true }
        if ($f.Name -match "^bindings?_.*\.json$" -or $f.Name -match "^_interaction_profiles_.*\.json$") { return $true }
    }
    return $false
}
#endregion

#region Heuristics & Text
function Get-HeuristicTags($profileDir, $meta, $profile) {
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $hasMC = $false; $hasUObject = $false
    if (Test-Path $profileDir) {
        $uDir = Join-Path $profileDir "uobjecthook"
        if (Test-Path $uDir) {
            $hasUObject = $true
            if (Get-ChildItem -Path $uDir -Filter "*_mc_state.json" -Recurse) { $hasMC = $true }
        }
    }
    if ($hasMC) { $tagSet.Add("6DOF") | Out-Null; $tagSet.Add("Motion Controls") | Out-Null }
    elseif ($hasUObject) { $tagSet.Add("3DOF") | Out-Null }
    $textSources = @()
    if ($meta.description) { $textSources += $meta.description }
    if ($meta.gameName) { $textSources += $meta.gameName }
    if ($profile) { $textSources += $profile }
    if (Test-Path $profileDir) {
        Get-ChildItem -Path $profileDir -File | Where-Object { $_.Extension -match "txt|md|json|lua" } | ForEach-Object { try { $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue; if ($c) { $textSources += $c } } catch {} }
    }
    $allText = $textSources -join "`n"
    $is3DOF = $profile -match "3\s*dof"; $is6DOF = $profile -match "6\s*dof"
    if ($allText -match "motion\s+controls" -and (-not $is3DOF -or $profile -match "motion")) { $tagSet.Add("Motion Controls") | Out-Null }
    if ($allText -match "6\s*dof" -and -not $is3DOF) { $tagSet.Add("6DOF") | Out-Null }
    if ($allText -match "3\s*dof" -and -not $is6DOF) { $tagSet.Add("3DOF") | Out-Null }
    $finalTags = [System.Collections.Generic.List[string]]::new($tagSet)
    if ($is3DOF) { for ($i = $finalTags.Count - 1; $i -ge 0; $i--) { if ($finalTags[$i] -match "6\s*dof") { $finalTags.RemoveAt($i) } } }
    if ($is6DOF) { for ($i = $finalTags.Count - 1; $i -ge 0; $i--) { if ($finalTags[$i] -match "3\s*dof") { $finalTags.RemoveAt($i) } } }
    return @($finalTags | Sort-Object | Select-Object -Unique)
}

function Convert-MarkdownToText($md, $maxLen = 100) {
    if ($null -eq $md) { return "" }
    $txt = $md -replace '(?m)^#+\s+', '' -replace '\*\*|__', '' -replace '\*|_', '' -replace '\[([^\]]+)\]\([^\)]+\)', '$1' -replace '`', '' -replace '(?m)^\s*>\s+', '' -replace '(?m)^\s*[-*+]\s+', '' -replace '\r?\n', ' '
    $txt = $txt.Trim()
    
    $res = $txt
    if ($txt.Length -gt $maxLen) {
        $res = $txt.Substring(0, $maxLen - 3) + "..."
    }
    return $res
}

function Move-Item-Smart($Source, $Destination) {
    Debug-Log "[common.ps1] Move-Item-Smart: $Source -> $Destination"
    if (-not (Test-Path $Source)) { return }
    $parent = Split-Path $Destination -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if (Test-Path $Destination) { Remove-Item $Destination -Recurse -Force }
    Move-Item $Source -Destination $Destination -Force
}
#endregion

#region Network Utilities
function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 5, $Silent = $false) {
    if (-not $headers["User-Agent"]) { $headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
    $lastErr = $null
    for ($i = 1; $i -le $retries; $i++) {
        try {
            if ($i -gt 1) { Write-Host "  Retry $i/$retries..." -ForegroundColor Yellow }
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 1500)
            Invoke-WebRequest -Uri $url -Headers $headers -OutFile $targetFile -ErrorAction Stop; return
        } catch { $lastErr = $_.Exception.Message; Write-Host "  [!] Attempt $i failed: $lastErr" -ForegroundColor Gray }
    }
    if (-not $Silent) { throw "All download attempts failed: $lastErr" } else { Write-Warning "  [!] All download attempts failed: $lastErr. Skipping due to -Silent." }
}
#endregion

#region Extraction & Discovery
function Get-SupportedArchiveExtensions {
    $defaultExts = @("zip", "7z", "rar", "tar", "gz", "bz2", "xz")
    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) { return $defaultExts | ForEach-Object { ".$_" } }
    try {
        $info = & 7z i -y 2>$null; $exts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase); $capture = $false
        foreach ($line in $info) {
            if ($line -match "^Formats:") { $capture = $true; continue }
            if ($line -match "^Codecs:") { $capture = $false; break }
            if ($capture -and $line -match "^\s*\d+\s+([\w.+-]+)\s+(\S+)\s+(.*)$") {
                foreach ($p in ($matches[3].Trim() -split "\s+")) {
                    if ($p -match "^[a-zA-Z0-9]{2,10}$" -and $p -notmatch "^\d+$" -and $p -notmatch "[A-F0-9]{2}") { $exts.Add($p) | Out-Null }
                }
            }
        }
        if ($exts.Count -gt 0) { return @($exts | ForEach-Object { ".$_" } | Sort-Object) }
    } catch {}
    return $defaultExts | ForEach-Object { ".$_" }
}

function Extract-And-Discover-Profiles($archivePath) {
    Debug-Log "[common.ps1] Entering Extract-And-Discover-Profiles ($archivePath)"
    $discovered = @()
    $tempBase = Join-Path $BaseTempDir "discovery_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempBase -Force | Out-Null
    
    try {
        $profileArchive = [ProfileArchive]::new($archivePath)
        $profileArchive.Extract($tempBase)
        
        # Profile discovery: any folder with ProfileMeta.json or known patterns
        $candidateDirs = Get-ChildItem -Path $tempBase -Directory -Recurse | Where-Object { 
            (Test-Path (Join-Path $_.FullName "ProfileMeta.json")) -or 
            (Get-ChildItem -Path $_.FullName -File | Where-Object { $_.Name -match "actions\.json|cameras\.txt|uobjecthook" })
        }
        
        if (-not $candidateDirs -and (Get-ChildItem $tempBase -File)) {
            $candidateDirs = @(Get-Item $tempBase)
        }

        foreach ($dir in $candidateDirs) {
            $rel = $dir.FullName.Substring($tempBase.Length).TrimStart('\')
            $relName = $rel ? $rel : "[Root]"
            $discovered += [PSCustomObject]@{ Path = $dir.FullName; Profile = $relName; ProfileName = $dir.Name }
        }
    } catch {
        Write-Warning "Discovery failed for ${archivePath}: $($_.Exception.Message)"
    }
    
    return $discovered
}

function Extract-Archives($archivePaths, [switch]$Silent) {
    Debug-Log "[common.ps1] Entering Extract-Archives"
    if (-not $archivePaths) { 
        Debug-Log "[common.ps1] No archive paths provided"
        return 
    }
    $results = @()
    foreach ($archivePath in $archivePaths) {
        $archive = Get-Item $archivePath
        Debug-Log "[common.ps1] Processing archive $($archive.Name)"
        Write-Host "Processing archive: $($archive.Name)..." -ForegroundColor Cyan
        
        $sidecarPath = $archive.FullName + ".json"
        if (-not (Test-Path $sidecarPath)) { 
            $sidecarPath = [IO.Path]::ChangeExtension($archive.FullName, ".json") 
        }
        
        $sidecar = $null
        if (Test-Path $sidecarPath) {
            Debug-Log "[common.ps1] Found sidecar: $sidecarPath"
            $sidecar = Get-Content $sidecarPath -Raw | ConvertFrom-Json
        }
        
        Debug-Log "[common.ps1] Discovering profiles in archive"
        $discovered = Extract-And-Discover-Profiles $archive.FullName
        Write-Host "  Found $($discovered.Count) profiles within archive." -ForegroundColor Gray
        
        foreach ($p in $discovered) {
            try {
                Debug-Log "[common.ps1] Processing discovered profile: $($p.Profile)"
                $internalPath = Join-Path $p.Path "ProfileMeta.json"
                
                $internal = $null
                if (Test-Path $internalPath) {
                    $internal = Get-Content $internalPath -Raw | ConvertFrom-Json
                }
                
                $merged = [ordered]@{}
                if ($internal) { foreach ($prop in $internal.PSObject.Properties) { $merged[$prop.Name] = $prop.Value } }
                if ($sidecar) { foreach ($prop in $sidecar.PSObject.Properties) { $merged[$prop.Name] = $prop.Value } }
                
                Debug-Log "[common.ps1] Generating metadata"
                if (-not $merged.ID) { $merged.ID = Get-OrCreateUUID $merged }
                if (-not $merged.zipHash) { $merged.zipHash = Get-FileHashMD5 $archive.FullName }
                if (-not $merged.downloadDate) { $merged.downloadDate = Get-ISO8601Now }

                $finalMeta = [ProfileMetadata]::FromObject($merged)
                $targetDir = Join-Path $ProfilesDir $finalMeta.ID
                if ($p.Profile -and $p.Profile -ne "[Root]") { 
                    $targetDir = Join-Path $targetDir ($p.Profile -replace ' / ', '\') 
                }
                
                Debug-Log "[common.ps1] Moving profile to target: $targetDir"
                Move-Item-Smart $p.Path $targetDir
                
                $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                if ($finalMeta.tags) { foreach ($t in $finalMeta.tags) { $tagSet.Add($t) | Out-Null } }
                $hTags = Get-HeuristicTags $targetDir $finalMeta $p.Profile
                if ($hTags) { foreach ($t in $hTags) { $tagSet.Add($t) | Out-Null } }
                if ($tagSet.Count -gt 0) { $finalMeta.tags = @($tagSet | Sort-Object) }
                
                Debug-Log "[common.ps1] Saving finalized metadata"
                $finalMeta.Save($targetDir, $archive.FullName, $p.Profile)
                
                if (-not $Silent) { 
                    Print-ProfileInfo $finalMeta $archive.FullName $p.Profile 
                }
                $results += $finalMeta
            } catch { Write-Host "  [!] Failed to process profile in $($archive.Name): $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
    return $results
}

function Extract-ArchivesFolder($folderPath, [switch]$Silent) {
    Debug-Log "[common.ps1] Entering Extract-ArchivesFolder: $folderPath"
    if (-not (Test-Path $folderPath)) { 
        Debug-Log "[common.ps1] Folder not found: $folderPath"
        return 
    }
    $exts = Get-SupportedArchiveExtensions
    $filter = ($exts | ForEach-Object { "*$_" })
    Debug-Log "[common.ps1] Searching for archives with filters: $($filter -join ', ')"
    $archives = Get-ChildItem -Path $folderPath -File -Include $filter
    Debug-Log "[common.ps1] Found $($archives.Count) archives"
    return Extract-Archives $archives.FullName -Silent:$Silent
}
#endregion
