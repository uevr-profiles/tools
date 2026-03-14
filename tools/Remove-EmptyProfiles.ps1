#region Parameters
param(
    [switch]$Delete,
    [switch]$Debug
)
#endregion

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

$Global:Debug = $Debug
Write-Host "Scanning for empty profiles in $ProfilesDir..." -ForegroundColor Cyan

$metadataFiles = @("ProfileMeta.json", "README.md")
$removedCount = 0

# Get all directories, sorted by depth (deepest first) to allow bottom-up cleanup
$dirs = Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Sort-Object { $_.FullName.Split('\').Count } -Descending

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir.FullName)) { continue } # Already deleted by a previous step

    $files = Get-ChildItem -Path $dir.FullName -File
    $subdirs = Get-ChildItem -Path $dir.FullName -Directory
    
    # Filter files to see if anything substantial exists
    $realFiles = $files | Where-Object { $metadataFiles -notcontains $_.Name }
    
    if ($realFiles.Count -eq 0 -and $subdirs.Count -eq 0) {
        if (-not $Delete) {
            Write-Host "[LIST ONLY] Would remove empty/metadata-only folder: $($dir.FullName)" -ForegroundColor Gray
        } else {
            Debug-Log "Removing empty/metadata-only folder: $($dir.FullName)"
            Remove-Item $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $removedCount++
        }
    }
}

# Finally check top-level ID folders in case they are now empty
$topDirs = Get-ChildItem -Path $ProfilesDir -Directory
foreach ($dir in $topDirs) {
    if (-not (Test-Path $dir.FullName)) { continue }
    $items = Get-ChildItem -Path $dir.FullName
    if ($items.Count -eq 0) {
        if (-not $Delete) {
             Write-Host "[LIST ONLY] Would remove empty ID folder: $($dir.FullName)" -ForegroundColor Gray
        } else {
            Debug-Log "Removing empty ID folder: $($dir.FullName)"
            Remove-Item $dir.FullName -Force -ErrorAction SilentlyContinue
            $removedCount++
        }
    }
}

if ($Delete) {
    Write-Host "`n[OK] Cleanup complete. Removed $removedCount folders." -ForegroundColor Green
} else {
    Write-Host "`n[INFO] Scan complete. Found $removedCount potentially empty folders. Run with -Delete to remove them." -ForegroundColor Yellow
}
