param(
    [switch]$Fix,
    [switch]$Debug
)

#region Dependencies
$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
. "$ScriptRoot\common.ps1"
$Global:Debug = $Debug
#endregion

#region Variables
$Profiles = @()
$ExeToGameMap = @{} # exeName -> @{ gameName = count }
$GameToExeMap = @{} # gameName -> @{ exeName = count }
$ExeToHeader  = @{} # exeName -> headerUrl
$GameToHeader = @{} # gameName -> headerUrl
#endregion

#region Main Logic
Write-Host "Scanning profiles for issues..." -ForegroundColor Cyan

# 1. Load all profiles and build frequency maps
$ProfileFolders = Get-ChildItem -Path $ProfilesDir -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName "ProfileMeta.json") }
foreach ($folder in $ProfileFolders) {
    $metaFile = Join-Path $folder.FullName "ProfileMeta.json"
    try {
        $meta = Get-Content $metaFile -Raw | ConvertFrom-Json
        $p = [PSCustomObject]@{
            Path = $folder.FullName
            Meta = $meta
        }
        $Profiles += $p

        $exe = $meta.exeName
        $game = $meta.gameName
        $header = $meta.headerPictureUrl

        if ($exe) {
            if (-not $ExeToGameMap[$exe]) { $ExeToGameMap[$exe] = @{} }
            $ExeToGameMap[$exe][$game]++
            if ($header -and -not $ExeToHeader[$exe]) { $ExeToHeader[$exe] = $header }
        }

        if ($game) {
            if (-not $GameToExeMap[$game]) { $GameToExeMap[$game] = @{} }
            $GameToExeMap[$game][$exe]++
            if ($header -and -not $GameToHeader[$game]) { $GameToHeader[$game] = $header }
        }
    } catch {
        Write-Warning "Failed to parse $metaFile"
    }
}

# 2. Determine "Source of Truth" for inconsistencies
$CorrectGameForExe = @{}
foreach ($exe in $ExeToGameMap.Keys) {
    $games = $ExeToGameMap[$exe]
    $winner = ($games.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    $CorrectGameForExe[$exe] = $winner
}

$CorrectExeForGame = @{}
foreach ($game in $GameToExeMap.Keys) {
    $exes = $GameToExeMap[$game]
    $winner = ($exes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    $CorrectExeForGame[$game] = $winner
}

# 3. Apply checks and fixes
$ChangesMade = 0
foreach ($p in $Profiles) {
    $meta = $p.Meta
    $folder = $p.Path
    $dirty = $false

    # Check Game Consistency (EXE -> Game)
    if ($meta.exeName -and $CorrectGameForExe[$meta.exeName] -ne $meta.gameName) {
        $old = $meta.gameName
        $new = $CorrectGameForExe[$meta.exeName]
        Write-Host "[ISSUE] Profile $($meta.ID) ($($meta.exeName)): GameName mismatch ('$old' -> '$new')" -ForegroundColor Yellow
        if ($Fix) { $meta.gameName = $new; $dirty = $true }
    }

    # Check Header
    if (-not $meta.headerPictureUrl) {
        $newHeader = $null
        if ($meta.exeName -and $ExeToHeader[$meta.exeName]) {
            $newHeader = $ExeToHeader[$meta.exeName]
            Write-Host "[ISSUE] Profile $($meta.ID): Missing header. Found match via EXE: $newHeader" -ForegroundColor Gray
        } elseif ($meta.gameName -and $GameToHeader[$meta.gameName]) {
            $newHeader = $GameToHeader[$meta.gameName]
            Write-Host "[ISSUE] Profile $($meta.ID): Missing header. Found match via Game: $newHeader" -ForegroundColor Gray
        } elseif ($meta.appID) {
            $newHeader = "https://cdn.cloudflare.steamstatic.com/steam/apps/$($meta.appID)/header.jpg"
            Write-Host "[ISSUE] Profile $($meta.ID): Missing header. Generated via AppID: $newHeader" -ForegroundColor Gray
        }

        if ($newHeader -and $Fix) {
            $meta.headerPictureUrl = $newHeader
            $dirty = $true
        }
    }

    if ($dirty -and $Fix) {
        Write-Host "  [FIX] Saving changes for $($meta.ID)..." -ForegroundColor Green
        $profileMeta = [ProfileMetadata]::FromObject($meta)
        # Use common.ps1 method to save JSON and update README
        $profileMeta.Save($folder, $null, $null)
        $ChangesMade++
    }
}

if ($Fix) {
    Write-Host "`nFixed $ChangesMade profiles." -ForegroundColor Green
} else {
    Write-Host "`nScan complete. Run with -Fix to apply changes." -ForegroundColor Gray
}
#endregion
