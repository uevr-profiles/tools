# ── Common Configuration & Functions ──────────────────────────────────────────
$RepoRoot    = Split-Path $PSScriptRoot -Parent
$ProfilesDir = Join-Path $RepoRoot "profiles"
$SchemaFile  = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"
$WhitelistFile = Join-Path $PSScriptRoot "whitelist.txt"
$BlacklistFile = Join-Path $PSScriptRoot "blacklist.txt"

# Ensure essential directories exist
foreach ($d in @($ProfilesDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Load Whitelist & Blacklist Regexes
$WhitelistRegexes = @()
if (Test-Path $WhitelistFile) {
    $WhitelistRegexes = Get-Content $WhitelistFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }
}
$BlacklistRegexes = @()
if (Test-Path $BlacklistFile) {
    $BlacklistRegexes = Get-Content $BlacklistFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace("\\", "/").Trim('/')
    if ($rel -eq "") { return $true }
    foreach ($re in $WhitelistRegexes) {
        if ($rel -match $re) { return $true }
        $patternWithoutAnchors = $re.TrimStart('^').TrimEnd('$')
        if ($patternWithoutAnchors.StartsWith($rel + "/")) { return $true }
    }
    return $false
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace("\\", "/").Trim('/')
    foreach ($re in $BlacklistRegexes) {
        if ($rel -match $re) { return $true }
    }
    return $false
}

function Remove-NonWhitelisted($targetDir, [switch]$applyWhitelist, [switch]$applyBlacklist) {
    if (-not $applyWhitelist -and -not $applyBlacklist) { return }
    
    Get-ChildItem -Path $targetDir -Recurse | Sort-Object FullName -Descending | ForEach-Object {
        $rel = $_.FullName.Substring($targetDir.Length) -replace '^[\\/]+', ''
        
        $shouldRemove = $false
        if ($applyBlacklist -and (Test-Blacklisted $rel)) {
            $shouldRemove = $true
        }
        elseif ($applyWhitelist -and -not (Test-Whitelisted $rel)) {
            $shouldRemove = $true
        }

        if ($shouldRemove) {
            if ($_ -is [System.IO.DirectoryInfo]) {
                if ((Get-ChildItem $_.FullName).Count -eq 0) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    Write-Host "  Removed unlisted/blacklisted dir:  $rel" -ForegroundColor DarkGray
                }
            } else {
                Remove-Item $_.FullName -Force
                Write-Host "  Removed unlisted/blacklisted file: $rel" -ForegroundColor DarkGray
            }
        }
    }
}

function Find-ProfileByHash($hash) {
    if ($null -eq $hash) { return $null }
    $metaFiles = Get-ChildItem -Path $ProfilesDir -Filter "ProfileMeta.json" -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $metaFiles) {
        try {
            if ($f.Length -gt 10kb) { continue }
            $json = Get-Content $f.FullName -Raw | ConvertFrom-Json
            if ($json.zipHash -eq $hash) { return $f.Directory.Name }
        } catch {}
    }
    return $null
}

function Test-Metadata($jsonText, $path) {
    if (Test-Path $SchemaFile) {
        $isValid = Test-Json -Json $jsonText -SchemaFile $SchemaFile -ErrorAction SilentlyContinue
        if (-not $isValid) {
            Write-Host "[!] Metadata validation FAILED for $path" -ForegroundColor Red
            try {
                $detailed = Test-Json -Json $jsonText -SchemaFile $SchemaFile -Detailed
                foreach ($e in $detailed.Errors) { Write-Host "    - $e" -ForegroundColor Yellow }
            } catch {}
        }
    }
}

function Get-FileHashMD5($Path) {
    return (Get-FileHash -Path $Path -Algorithm MD5).Hash.ToUpper()
}

function Get-OrCreateUUID($existingId) {
    if ($existingId -and $existingId -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
        return $existingId.ToLower()
    }
    return [guid]::NewGuid().ToString().ToLower()
}

function Find-ExistingProfileFolder($uuid) {
    $metaFiles = Get-ChildItem -Path $ProfilesDir -Filter "ProfileMeta.json" -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $metaFiles) {
        try {
            $json = Get-Content $f.FullName -Raw | ConvertFrom-Json
            if ($json.ID -eq $uuid) { return $f.Directory.FullName }
        } catch {}
    }
    return $null
}
