#region Metadata & Tracking Utilities
function Update-GlobalFilesList($relPaths) {
    if ($null -eq $relPaths) { return }
    foreach ($p in $relPaths) { $Global:TrackingFiles.Add($p) | Out-Null }
}

function Update-GlobalPropsJson($archivePath, $profile, $metaObj) {
    if ($null -eq $metaObj) { return }
    if ($profile -and $profile -ne "[Root]") {
        $occId = "$archivePath | $profile"
    } else {
        $occId = "$archivePath"
    }
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
        if (Test-Path $GlobalFilesList) {
            $existing = Get-Content $GlobalFilesList -ErrorAction SilentlyContinue
        } else {
            $existing = @()
        }
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
function Load-ConnectionState {
    if (-not (Test-Path $Global:ConnectionStateFile)) { return }
    try {
        $state = Get-Content $Global:ConnectionStateFile -Raw | ConvertFrom-Json
        if ($state.CurrentWorkingProxy) {
            $Global:CurrentWorkingProxy = $state.CurrentWorkingProxy
            Debug-Log "[Tracking.ps1] Loaded persistent proxy: $($Global:CurrentWorkingProxy)"
        }
        if ($state.CurrentWorkingTailscaleNode) {
            $Global:CurrentWorkingTailscaleNode = $state.CurrentWorkingTailscaleNode
            Debug-Log "[Tracking.ps1] Loaded persistent Tailscale node: $($Global:CurrentWorkingTailscaleNode.Hostname)"
        }
    } catch {
        Debug-Log "[Tracking.ps1] Failed to load connection state: $($_.Exception.Message)"
    }
}

function Save-ConnectionState {
    try {
        $state = [ordered]@{
            "CurrentWorkingProxy"         = $Global:CurrentWorkingProxy
            "CurrentWorkingTailscaleNode" = $Global:CurrentWorkingTailscaleNode
            "Timestamp"                   = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        }
        $state | ConvertTo-Json | Set-Content $Global:ConnectionStateFile -Encoding utf8
        Debug-Log "[Tracking.ps1] Saved connection state to disk."
    } catch {
        Debug-Log "[Tracking.ps1] Failed to save connection state: $($_.Exception.Message)"
    }
}
#endregion
