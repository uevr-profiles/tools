param(
    [string]$ProfilesDir,
    [string]$SchemaFile,
    [string]$OutputFile,
    [switch]$Update
)

. "$PSScriptRoot\common.ps1"

# Defaults if not provided via param
if (-not $ProfilesDir) { $ProfilesDir = $Global:ProfilesDir }
if (-not $SchemaFile)  { $SchemaFile  = $Global:SchemaFile }
if (-not $OutputFile)  { $OutputFile  = Join-Path $RepoRoot "repo.json" }

# Resolve to absolute paths
$ProfilesDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilesDir)
$SchemaFile  = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SchemaFile)
$OutputFile  = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)

if ($Update) {
    Write-Host "Running profile updates before build..." -ForegroundColor Cyan
    Get-ChildItem -Path "$PSScriptRoot" -Filter "Update-From*.ps1" | ForEach-Object {
        Write-Host ">>> Running $($_.Name) <<<" -ForegroundColor Cyan
        pwsh -NoProfile -File $_.FullName -Fetch -Download -Extract
    }
}

if (-not (Test-Path $ProfilesDir)) {
    Write-Error "Profiles directory not found: $ProfilesDir"
    exit 1
}

$allMeta = @()
$errors  = 0

Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") } | ForEach-Object {
    $metaFile = Join-Path $_.FullName "ProfileMeta.json"
    
    # Use centralized validation logic
    if (-not [ProfileMetadata]::Validate($metaFile)) {
        $errors++
    }

    try {
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
$allMeta | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding utf8

Write-Host "Done. repo.json contains $($allMeta.Count) profiles." -ForegroundColor Green
if ($errors -gt 0) {
    Write-Host "Encountered $errors validation/parse errors. Failing build." -ForegroundColor Red
    exit 1
}
