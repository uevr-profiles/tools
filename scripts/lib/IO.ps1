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

function Move-Item-Smart($Source, $Destination) {
    Debug-Log "[common.ps1] Move-Item-Smart: $Source -> $Destination"
    if (-not (Test-Path $Source)) { return }
    $parent = Split-Path $Destination -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if (Test-Path $Destination) { Remove-Item $Destination -Recurse -Force }
    Move-Item $Source -Destination $Destination -Force
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

#endregion
