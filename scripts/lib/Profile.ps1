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
        Write-Warning "$msg"
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
        Write-Host "    - Variant:    $profile" -ForegroundColor Gray
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
