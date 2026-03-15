#region Variables & Configuration
# Relative to scripts/lib/Config.ps1
$LibDir         = $PSScriptRoot
$ScriptsDir     = Split-Path $LibDir -Parent
$RepoRoot       = Split-Path $ScriptsDir -Parent
$RepoRawUrl     = "https://github.com/Bluscream/UnrealVRMod/raw/main"
$ProfilesDir    = Join-Path $RepoRoot "repo"
$SchemaFile     = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"
$Global:SchemaContent = $null
if (Test-Path $SchemaFile) {
    $Global:SchemaContent = Get-Content $SchemaFile -Raw
}

function Load-ProxiesFromFile($path) {
    if (Test-Path $path) {
        try { return Get-Content $path -Raw | ConvertFrom-Json } catch { }
    }
    return @("DIRECT")
}

$ProxiesFile = Join-Path $ScriptsDir "proxies.json"
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
