#region Variables & Configuration
$RepoRoot       = Split-Path $PSScriptRoot -Parent
$RepoRawUrl     = "https://github.com/Bluscream/UnrealVRMod/raw/main"
$ProfilesDir    = Join-Path $RepoRoot "repo"
$SchemaFile     = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"
$Global:SchemaContent = $null
if (Test-Path $SchemaFile) {
    $Global:SchemaContent = Get-Content $SchemaFile -Raw
}

function Load-ProxiesFromFile($path = $ProxiesFile) {
    if (Test-Path $path) {
        try { return Get-Content $path -Raw | ConvertFrom-Json } catch { }
    }
    return @("DIRECT")
}

$ProxiesFile = Join-Path $PSScriptRoot "proxies.json"
$Global:Proxies = Load-ProxiesFromFile $ProxiesFile

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
if (-not (Test-Path $BaseTempDir)) { New-Item -ItemType Directory -Path $BaseTempDir -Force | Out-Null }
$BaseTempDir     = (Get-Item $BaseTempDir).FullName
$GlobalFilesList = Join-Path $BaseTempDir "files.txt"
$GlobalPropsJson = Join-Path $BaseTempDir "props.json"
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
        $head = "# UEVR Profile for "
        $game = $meta.gameName
        if ($meta.profileName -and $meta.profileName -ne "[Root]") { $game += " ($($meta.profileName))" }
        
        if ($meta.appID) {
            $head += "[$game](https://steamdb.info/app/$($meta.appID))"
        } else {
            $head += $game
        }
        
        if ($meta.authorName) {
            $head += " by $($meta.authorName)"
        }
        $sb.AppendLine($head)
        $sb.AppendLine()

        # Table
        $sb.AppendLine("| Property | Value |")
        $sb.AppendLine("| :--- | :--- |")
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
                    elseif ($p -match "Date$") { $meta.$p = Format-DateISO8601 $val }
                    else { $meta.$p = $val }
                } catch {
                    Debug-Log "[ProfileMetadata] Failed to map property ${p}: $($_.Exception.Message)"
                }
            }
        }
        return $meta
    }

    static [bool] Validate($jsonPath) {
        return [ProfileMetadata]::Validate($jsonPath, $null)
    }

    static [bool] Validate($jsonPath, $jsonText) {
        if (-not $Global:SchemaContent) { return $true }
        
        $content = $jsonText
        if ($jsonPath -and (Test-Path $jsonPath)) {
            $content = Get-Content $jsonPath -Raw
        }

        if ([string]::IsNullOrEmpty($content)) {
            Debug-Log "[ProfileMetadata] Validate: No content to validate"
            return $false
        }

        $jsonErr = $null
        $res = Test-Json -Json $content -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        
        if (-not $res -and $jsonErr) {
            Debug-Log "[ProfileMetadata] JSON Validation FAILED for content:"
            Debug-Log "$content"
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
                    if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[\.DRHSA]{5}\s+\d+\s+\d+\s+(.*)$") {
                        $names += $matches[1].Trim()
                    }
                }
                if ($names.Count -gt 0) { return $names }
            }
        }
        if ($this.Path -like "*.zip") {
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
            $process = Start-Process -FilePath "7z" -ArgumentList "x", "`"$($this.Path)`"", "-o$destination", "-y" -PassThru -NoNewWindow
            if ($null -ne $process -and $process.WaitForExit(60000)) { # 60 second timeout
                if ($process.ExitCode -eq 0) { $extracted = $true }
            } elseif ($null -ne $process) {
                Debug-Log "[common.ps1] 7z extraction timed out for $($this.Path). Killing process."
                $process | Stop-Process -Force -ErrorAction SilentlyContinue
                throw "Extraction timed out after 30 seconds: $($this.Path)"
            }
        }
        if (-not $extracted -and ($this.Path -like "*.zip")) {
            try { Expand-Archive -Path $this.Path -DestinationPath $destination -Force -ErrorAction SilentlyContinue; $extracted = $true } catch {}
        }
        if (-not $extracted) { throw "Failed to extract archive: $($this.Path) (7z not found, failed, or timed out)" }
    }
}
#endregion

#region Archive Utilities
function Compress-Files($FilePaths, $TargetArchive, $CompressionLevel = 9) {
    Debug-Log "[common.ps1] Compressing $($FilePaths.Count) files into $TargetArchive (Level: $CompressionLevel)"
    $TargetArchive = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetArchive)
    $parent = Split-Path $TargetArchive -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        # Using 7z 'a' to add files. -mx sets compression level (0-9).
        $args = @("a", "-mx$CompressionLevel", "-y", "`"$TargetArchive`"")
        foreach ($f in $FilePaths) { $args += "`"$f`"" }
        $process = Start-Process -FilePath "7z" -ArgumentList $args -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -ne 0) { throw "7z failed to compress files into $TargetArchive (ExitCode: $($process.ExitCode))" }
    } else {
        $level = "Optimal"
        if ($CompressionLevel -le 0) { $level = "NoCompression" }
        elseif ($CompressionLevel -le 1) { $level = "Fastest" }
        Compress-Archive -Path $FilePaths -DestinationPath $TargetArchive -CompressionLevel $level -Update -ErrorAction Stop
    }
}

function Compress-Folder($FolderPath, $TargetArchive, $CompressionLevel = 9) {
    Debug-Log "[common.ps1] Compressing folder $FolderPath into $TargetArchive (Level: $CompressionLevel)"
    $TargetArchive = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetArchive)
    $FolderPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FolderPath)
    
    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        $process = Start-Process -FilePath "7z" -ArgumentList "a", "-mx$CompressionLevel", "-y", "`"$TargetArchive`"", "`"$FolderPath\*`"" -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -ne 0) { throw "7z failed to compress folder $FolderPath (ExitCode: $($process.ExitCode))" }
    } else {
        Compress-Archive -Path "$FolderPath\*" -DestinationPath $TargetArchive -CompressionLevel "Optimal" -Update -ErrorAction Stop
    }
}


#region Profile Helpers
function Get-ProfileDownloadUrl($uuid, $exeName) {
    Debug-Log "[common.ps1] Entering Get-ProfileDownloadUrl (ID: $uuid, Exe: $exeName)"
    if ([string]::IsNullOrWhiteSpace($exeName)) {
        throw "Cannot generate Download URL: exeName is missing for profile $uuid."
    }
    $baseUrl = "https://github.com/uevr-profiles/repo/tree/main/$uuid"
    $encodedUrl = [System.Web.HttpUtility]::UrlEncode($baseUrl)
    
    $name = $exeName.Replace(" ", "_").Replace(".", "_")
    Debug-Log "[common.ps1] Name for downloader: $name"
    
    $res = "https://gitfolderdownloader.github.io/?url=$encodedUrl&name=$name"
    Debug-Log "[common.ps1] Result: $res"
    return $res
}

function Get-ISO8601Now {
    return (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

function Format-DateISO8601($date) {
    if ($null -eq $date -or "$date" -eq "") { return Get-ISO8601Now }
    try {
        # Handle already formatted strings to avoid re-formatting errors
        if ($date -match "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$") { return $date }
        $dt = [DateTime]$date
        return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } catch {
        return Get-ISO8601Now
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
        $existing = [ordered]@{}
        if (Test-Path $GlobalPropsJson) {
            try { $existing = Get-Content $GlobalPropsJson -Raw | ConvertFrom-Json } catch { }
        }
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
function Load-ProfilesFromFile($path) {
    if (-not (Test-Path $path)) { return @() }
    try {
        $content = Get-Content $path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) { return @() }
        $data = $content | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $data) { return @() }
        if ($data -is [array]) { return $data }
        return @($data)
    } catch {
        Write-Warning "Failed to load profiles from ${path}: $($_.Exception.Message)"
        return @()
    }
}

#endregion

#region File & IO Utilities

function Flatten-Folder($targetDir) {
    Debug-Log "[common.ps1] Flatten-Folder: $targetDir"
    # Keep flattening as long as there's only one child and it's a directory
    while ($true) {
        $items = Get-ChildItem -Path $targetDir -ErrorAction SilentlyContinue
        if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
            $subDir = $items[0].FullName
            Debug-Log "[common.ps1] Flattening single subfolder: $($items[0].Name)"
            Get-ChildItem -Path $subDir | ForEach-Object { 
                Move-Item -Path $_.FullName -Destination $targetDir -Force -ErrorAction SilentlyContinue 
            }
            Remove-Item $subDir -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            break
        }
    }
}

function Get-FileHashMD5($path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Path $path -Algorithm MD5).Hash.ToUpper()
}

function Get-SafeExeName($name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return "" }
    # Remove .exe suffix (case-insensitive)
    # Remove _\d+ suffixes (common in uevr-profiles.com versioning)
    # Remove (v\d+) or [v\d+] patterns
    return ($name.Trim() -replace "(?i)\.exe$", "" -replace "_(\d+)$", "" -replace "\s*[\[\(][vV]?\d+[\)\]]$", "").Trim()
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


#endregion

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
    if ($allText -match "6\s*dof" -and -not $is3DOF) { $tagSet.Add("6DoF") | Out-Null }
    if ($allText -match "3\s*dof" -and -not $is6DOF) { $tagSet.Add("3DoF") | Out-Null }
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
$Global:ActiveProxyPool = @()
$Global:DeadProxies     = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Get-PreparedProxyPool($requestedProxies, $url = $null) {
    if ($null -eq $requestedProxies) { return @($null) }
    
    $rawList = @()
    if ($requestedProxies -is [System.Management.Automation.PSCustomObject]) {
        # Map format: { "proxy": ["domain1", "domain2"] }
        foreach ($prop in $requestedProxies.PSObject.Properties) {
            $proxy = $prop.Name
            $domains = @($prop.Value)

            if ($null -eq $url -or $proxy -eq "DIRECT") {
                $rawList += $proxy
            } else {
                # Check if this proxy is verified for the target domain
                foreach ($d in $domains) {
                    if ($url -match [regex]::Escape($d)) {
                        $rawList += $proxy
                        break
                    }
                }
            }
        }
        # If no specialized proxies found for this domain, fall back to all
        if ($rawList.Count -le 1 -and $rawList -contains "DIRECT" -and $null -ne $url) {
             foreach ($prop in $requestedProxies.PSObject.Properties) {
                if ($prop.Name -ne "DIRECT") { $rawList += $prop.Name }
             }
        }
    }
    elseif ($requestedProxies -is [array]) { $rawList = $requestedProxies }
    else { $rawList = $requestedProxies -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ } }

    $finalPool = @()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($p in $rawList) {
        if ($p -ieq "DIRECT") {
            if ($seen.Add("DIRECT_MARKER")) { $finalPool += $null }
            continue
        }
        
        if (-not $Global:DeadProxies.Contains($p)) {
            if ($seen.Add($p)) { $finalPool += $p }
        }
    }

    if ($finalPool.Count -eq 0) { $finalPool += $null } 
    return $finalPool
}

function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 2, $Silent = $false, $Proxies = $null, $TimeoutSec = 10) {
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    if ($headers["User-Agent"]) { $userAgent = $headers["User-Agent"]; $headers.Remove("User-Agent") }
    
    # Prepare the pool: Respect the user's order and handle the new map format
    $finalPool = Get-PreparedProxyPool $Proxies $url

    $lastErr = "No connection attempted"
    
    foreach ($p in $finalPool) {
        $proxyLabel = $p ? $p : "Direct"
        Debug-Log "[common.ps1] Trying $url via $proxyLabel for $($TimeoutSec)s"

        for ($i = 1; $i -le $retries; $i++) {
            $requestParams = @{
                Uri = $url
                Headers = $headers
                UserAgent = $userAgent
                SkipCertificateCheck = $true
                ErrorAction = "Stop"
                TimeoutSec = $TimeoutSec
            }
            if ($targetFile) { $requestParams["OutFile"] = $targetFile }
            $actualProxy = ($p -eq "DIRECT") ? $null : $p
            if ($actualProxy) { $requestParams["Proxy"] = $actualProxy }

            try {
                if ($i -gt 1) { 
                    Write-Host "    [Retry $i/$retries] via $proxyLabel..." -ForegroundColor Yellow 
                }
                
                # Add random jitter between 500ms and 2s to avoid bot detection
                if ($i -gt 1) { Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000) }
                
                # We use a background thread for the request because Invoke-WebRequest can ignore TimeoutSec 
                # if the connection is established but data is flowing at ~0 bytes/sec.
                $job = Start-Job -ScriptBlock {
                    param($p, $rp)
                    if ($p) { $rp["Proxy"] = $p }
                    Invoke-WebRequest @rp | Out-Null
                } -ArgumentList $p, $requestParams

                $waitTimeout = $TimeoutSec + 5 # Give it a few extra seconds for the job overhead
                if (Wait-Job $job -Timeout $waitTimeout) {
                    $result = Receive-Job $job -ErrorAction Stop
                    return # SUCCESS!
                } else {
                    Stop-Job $job -PassThru | Remove-Job -Force
                    throw "Absolute timeout ($($waitTimeout)s) reached"
                }
            } catch {
                $lastErr = $_.Exception.Message
                if ($_.Exception.InnerException) { $lastErr = $_.Exception.InnerException.Message }
                $statusCode = 0
                if ($_.Exception.Response) { 
                    $statusCode = [int]$_.Exception.Response.StatusCode 
                } elseif ($lastErr -match "\((\d{3})\)") {
                    $statusCode = [int]$matches[1]
                }

                # Clear blockades: 403 Forbidden, 429 Too Many Requests, 500 Internal Server Error (often Azure block)
                if ($statusCode -in @(403, 429, 500)) {
                    Write-Host "  [!] Proxy $proxyLabel blocked/failed ($statusCode). Moving to next proxy." -ForegroundColor Red
                    if ($p) { $Global:DeadProxies.Add($p) | Out-Null }
                    break # Break inner retry loop, move to next proxy in the pool
                }

                Write-Host "  [!] Attempt $i via $proxyLabel failed: $lastErr" -ForegroundColor Gray
                # If it's a timeout or connection issue, we keep trying this proxy up to $retries
            }
        }

        # If we finished all retries for this proxy without success, mark it dead
        if ($p -and -not $Global:DeadProxies.Contains($p)) {
            Write-Host "  [!] Proxy $proxyLabel failed all $retries attempts. Removing from active pool." -ForegroundColor Yellow
            $Global:DeadProxies.Add($p) | Out-Null
        }
    }

    $finalMsg = "All proxies and connection attempts failed for $url. Last error: $lastErr"
    if ($Silent) { Write-Warning "  [!] $finalMsg" }
    else { throw "Fatal: $finalMsg" }
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
        if ($exts.Count -gt 0) { return @($exts | Sort-Object | ForEach-Object { if ($_ -notmatch "^\.") { ".$_" } else { $_ } }) }
    } catch {}
    return $defaultExts | ForEach-Object { ".$_" }
}

function Extract-And-Discover-Profiles($archivePath) {
    Debug-Log "[common.ps1] Entering Extract-And-Discover-Profiles ($archivePath)"
    $discovered = @()
    $tempBase = Join-Path $BaseTempDir "discovery_$(Get-Random)"
    # Normalize tempBase to long path
    $tempBase = (New-Item -ItemType Directory -Path $tempBase -Force).FullName
    $Global:TempFolders += $tempBase
    
    try {
        $profileArchive = [ProfileArchive]::new($archivePath)
        $profileArchive.ExtractTo($tempBase)
        
        # Flatten-Folder will collapse single-folder wrappers (e.g. Zip/ExeName/config.txt -> Zip/config.txt)
        Flatten-Folder $tempBase
        # Profile discovery: any folder with ProfileMeta.json or known patterns
        # We limit depth to 3 and skip folders like "sdkdump" that can contain thousands of files.
        $searchBlacklist = @("sdkdump", "Source", "Intermediate", "Binaries", "Saved")
        $candidateDirs = Get-ChildItem -Path $tempBase -Directory -Recurse -Depth 3 | Where-Object { 
            if ($searchBlacklist -contains $_.Name) { return $false }
            Is-ProfileFolder $_.FullName
        }
        
        # If no internal folders match, check the root
        if ($candidateDirs.Count -eq 0) {
            if (Is-ProfileFolder $tempBase) {
                $candidateDirs = @(Get-Item $tempBase)
            }
        }

        # Filter out sub-profiles of already discovered profiles (keep deepest or specific ones)
        # Actually, if we have Profile/SubProfile, and both contain essentials? 
        # Usually we want all of them.
        
        foreach ($dir in $candidateDirs) {
            # Normalize dir path to long path
            $dirPath = (Get-Item $dir.FullName).FullName
            $rel = [IO.Path]::GetRelativePath($tempBase, $dirPath)
            if ($rel -eq ".") { $rel = "" }
            $relName = $rel ? $rel : "[Root]"
            $discovered += [PSCustomObject]@{ Path = $dirPath; Profile = $relName; ProfileName = $dir.Name }
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

function Extract-ArchivesFolder($folderPath, [int]$Limit = [int]::MaxValue, [switch]$Silent) {
    Debug-Log "[common.ps1] Entering Extract-ArchivesFolder: $folderPath (Limit: $Limit)"
    if (-not (Test-Path $folderPath)) { 
        Debug-Log "[common.ps1] Folder not found: $folderPath"
        return 
    }
    $exts = Get-SupportedArchiveExtensions
    Debug-Log "[common.ps1] Searching for archives with extensions: $($exts -join ', ')"
    $archives = Get-ChildItem -Path $folderPath -File | Where-Object { $exts -contains $_.Extension }
    
    if ($Limit -lt $archives.Count) {
        Debug-Log "[common.ps1] Limiting extraction to $Limit newest files"
        $archives = $archives | Sort-Object LastWriteTime -Descending | Select-Object -First $Limit
    }
    
    Debug-Log "[common.ps1] Found $($archives.Count) archives to extract"
    return Extract-Archives $archives.FullName -Silent:$Silent
}
#endregion
