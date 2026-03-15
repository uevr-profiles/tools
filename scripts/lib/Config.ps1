#region Variables & Configuration
# Ensure modern SSL/TLS protocols are enabled and ignore certificate errors
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

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

# Network Flags
if ($null -eq $Global:UseProxies)   { $Global:UseProxies = $false }
if ($null -eq $Global:UseTailscale) { $Global:UseTailscale = $false }
$Global:ProxyPool = @()
$Global:TailscaleNodeCache = @()

# Failover Limits
if ($null -eq $Global:ProxyLimit)     { $Global:ProxyLimit = 50 }
if ($null -eq $Global:TailscaleLimit) { $Global:TailscaleLimit = 5 }

# Global dead connection tracking
$Global:DeadProxies = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$Global:DeadTailscaleNodes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

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
