#region Parameters
param(
    [string]$ProfilesDir,
    [string]$SchemaFile,
    [string]$OutputFile,
    [switch]$Update,
    [switch]$Debug
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$Global:Debug = $Debug
# Defaults if not provided via param
if (-not $ProfilesDir) { $ProfilesDir = $Global:ProfilesDir }
if (-not $SchemaFile)  { $SchemaFile  = $Global:SchemaFile }
if (-not $OutputFile)  { $OutputFile  = Join-Path $RepoRoot "repo.json" }

# Resolve to absolute paths
$ProfilesDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilesDir)
$SchemaFile  = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SchemaFile)
$OutputFile  = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

$allMeta = @()
$errors  = 0
#endregion

#region Main Logic
Debug-Log "[Build-UEVRRepo.ps1] Main Logic Start"
if ($Update) {
    Write-Host "Running profile updates before build..." -ForegroundColor Cyan
    Debug-Log "[Build-UEVRRepo.ps1] Enumerating update scripts"
    Get-ChildItem -Path "$PSScriptRoot" -Filter "Update-From*.ps1" | ForEach-Object {
        Write-Host ">>> Running $($_.Name) <<<" -ForegroundColor Cyan
        Debug-Log "[Build-UEVRRepo.ps1] Running pwsh: $($_.FullName)"
        pwsh -NoProfile -File $_.FullName -Fetch -Download -Extract -Debug:$Debug
    }
}

if (-not (Test-Path $ProfilesDir)) {
    Write-Error "Profiles directory not found: $ProfilesDir"
    exit 1
}

Debug-Log "[Build-UEVRRepo.ps1] Scanning profiles in $ProfilesDir"
Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") } | ForEach-Object {
    Debug-Log "[Build-UEVRRepo.ps1] Found profile: $($_.FullName)"
    $metaFile = Join-Path $_.FullName "ProfileMeta.json"
    
    # Use centralized validation logic
    Debug-Log "[Build-UEVRRepo.ps1] Validating profile: $metaFile"
    if (-not [ProfileMetadata]::Validate($metaFile)) {
        Debug-Log "[Build-UEVRRepo.ps1] Validation FAILED for $metaFile"
        $errors++
    }

    try {
        Debug-Log "[Build-UEVRRepo.ps1] Loading and normalizing $metaFile"
        $meta = Get-Content $metaFile -Raw | ConvertFrom-Json
        
        # Normalize exeName for repo.json (join arrays into comma-separated strings)
        if ($meta.exeName -is [System.Collections.IEnumerable] -and $meta.exeName -isnot [string]) {
            $meta.exeName = ($meta.exeName | Sort-Object -Unique) -join ", "
        }
        $allMeta += $meta
    } catch {
        Write-Warning "Could not parse JSON in $metaFile"
        $errors++
    }
}

$allMeta = $allMeta | Sort-Object gameName
Debug-Log "[Build-UEVRRepo.ps1] Saving $OutputFile with $($allMeta.Count) profiles"
$allMeta | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding utf8

Write-Host "Done. repo.json contains $($allMeta.Count) profiles." -ForegroundColor Green
if ($errors -gt 0) {
    Write-Host "Encountered $errors validation/parse errors. Failing build." -ForegroundColor Red
    exit 1
}
Debug-Log "[Build-UEVRRepo.ps1] Main Logic End"
#endregion
