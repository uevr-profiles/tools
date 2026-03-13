#region Parameters
param(
    [switch]$Clean,
    [switch]$Silent
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

#region Variables
$UpdateScripts = @(
    "Update-FromUEVRProfiles.ps1", 
    "Update-FromUEVRDeluxe.ps1",
    "Update-FromDiscord.ps1"
)
$DedupeScript = "Deduplicate-Profiles.ps1"
$BuildScript  = "Build-UEVRRepo.ps1"
#endregion

#region Main Logic
if ($Clean) {
    Write-Host "Cleaning cache: $BaseTempDir" -ForegroundColor Yellow
    Remove-Item $BaseTempDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    
    Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
    if (Test-Path $ProfilesDir) {
        Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
    }
}

# 1. Test Fetch & Download
foreach ($s in $UpdateScripts) {
    $scriptPath = Join-Path $PSScriptRoot $s
    if (Test-Path $scriptPath) {
        Write-Host "`n>>> Testing $s (Download) <<<" -ForegroundColor Cyan
        try {
            & $scriptPath -Fetch -Download -ProfileLimit 1 -Silent:$Silent
        } catch {
            Write-Host "    [!] Download test failed for ${s}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 2. Test Deduplication
$dedupePath = Join-Path $PSScriptRoot $DedupeScript
if (Test-Path $dedupePath) {
    Write-Host "`n>>> Testing $DedupeScript <<<" -ForegroundColor Cyan
    try {
        & $dedupePath -Delete -Silent:$Silent
    } catch {
        Write-Host "    [!] Deduplication test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 3. Test Extraction
foreach ($s in $UpdateScripts) {
    $scriptPath = Join-Path $PSScriptRoot $s
    if (Test-Path $scriptPath) {
        Write-Host "`n>>> Testing $s (Extract) <<<" -ForegroundColor Cyan
        try {
            & $scriptPath -Extract -Silent:$Silent
        } catch {
            Write-Host "    [!] Extraction test failed for ${s}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 4. Test Build
$buildPath = Join-Path $PSScriptRoot $BuildScript
if (Test-Path $buildPath) {
    Write-Host "`n>>> Testing $BuildScript <<<" -ForegroundColor Cyan
    try {
        & $buildPath
    } catch {
        Write-Host "    [!] Build test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTest run complete." -ForegroundColor Green
exit 0
#endregion
