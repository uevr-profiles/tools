param(
    [switch]$UseProxies,
    [switch]$UseTailscale,
    [switch]$Clean = $true,
    [switch]$Silent,
    [switch]$Debug,
    [int]$ProfileLimit = 2,
    [switch]$SkipFetch,
    [switch]$Fast
)

#region Dependencies
. "$PSScriptRoot\common.ps1"
#endregion

if ($UseProxies) {
    Write-Warning "Free Proxies are highly unreliable (usually timing out on all endpoints). Use with caution."
}

if ($UseTailscale) {
    Write-Warning "Tailscale VPN test will alter your entire PC's network traffic during the test."
}

if ($Fast) {
    $ProfileLimit = 1
    $SkipFetch = $true
}


#region Variables
$Global:Debug = $Debug
$Global:UseProxies = $UseProxies
$Global:UseTailscale = $UseTailscale
$UpdateScripts = @(
    "Update-FromUEVRProfiles.ps1", 
    "Update-FromUEVRDeluxe.ps1",
    "Update-FromDiscord.ps1"
)
$DedupeScript = "Deduplicate-Profiles.ps1"
$BuildScript  = "Build-UEVRRepo.ps1"
$LogsDir      = Join-Path $RepoRoot "logs"
$UnixTime     = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$LogFile      = Join-Path $LogsDir "$($UnixTime)_Test-Scripts.log"
#endregion

#region Main Logic
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
Write-Host "Logging to $LogFile" -ForegroundColor DarkGray
Start-Transcript -Path $LogFile -Append -Force | Out-Null
try {
    if ($Clean) {
        Write-Host "Cleaning cache: $BaseTempDir" -ForegroundColor Yellow
        Remove-Item $BaseTempDir -Recurse -Force -ErrorAction SilentlyContinue 2>$null
        
        Write-Host "Cleaning profiles: $ProfilesDir" -ForegroundColor Yellow
        if (Test-Path $ProfilesDir) {
            Get-ChildItem -Path $ProfilesDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 2>$null
        }
    }

    # 1. Test Fetch & Download
    if (-not $SkipFetch) {
        foreach ($s in $UpdateScripts) {
            $scriptPath = Join-Path $PSScriptRoot $s
            if (Test-Path $scriptPath) {
                Write-Host "`n>>> Testing $s (Download) <<<" -ForegroundColor Cyan
                try {
                    & $scriptPath -Fetch -Download -ProfileLimit $ProfileLimit -Silent:$Silent -Debug:$Debug -UseProxies:$UseProxies -UseTailscale:$UseTailscale
                } catch {
                    Write-Host "    [!] Download test failed for ${s}: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "`n>>> Skipping Fetch & Download phase <<<" -ForegroundColor Yellow
    }

    # 2. Test Deduplication
    $dedupePath = Join-Path $PSScriptRoot $DedupeScript
    if (Test-Path $dedupePath) {
        Write-Host "`n>>> Testing $DedupeScript <<<" -ForegroundColor Cyan
        try {
            & $dedupePath -Delete -Silent:$Silent -Debug:$Debug
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
                & $scriptPath -Extract -ProfileLimit $ProfileLimit -Silent:$Silent -Debug:$Debug
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
            & $buildPath -Debug:$Debug
        } catch {
            Write-Host "    [!] Build test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 5. Test UUID Verification
    Write-Host "`n>>> Testing UUID Verification <<<" -ForegroundColor Cyan
    $downloadErrors = 0
    $extractionErrors = 0
    $downloadChecks = 0
    $extractionChecks = 0

    if (-not $SkipFetch) {
        Write-Host "  - Verifying Download UUIDs (sourceDownloadUrl -> filename)" -ForegroundColor Gray
        $sidecars = Get-ChildItem -Path $BaseTempDir -Filter "*.zip.json" -Recurse -ErrorAction SilentlyContinue
        foreach ($sc in $sidecars) {
            try {
                $meta = Get-Content $sc.FullName -Raw | ConvertFrom-Json
                $url = if ($meta.sourceDownloadUrl) { $meta.sourceDownloadUrl } else { $meta.downloadUrl }
                if ($url) {
                    $expectedUuid = Get-DownloadUUID $url
                    $actualUuid = ($sc.Name -replace "\.zip\.json$", "").ToLower()
                    if ($expectedUuid.ToLower() -ne $actualUuid) {
                        Write-Host "    [!] Download UUID Mismatch: Expected $expectedUuid, Got $actualUuid for URL: $url" -ForegroundColor Red
                        $downloadErrors++
                    }
                    $downloadChecks++
                }
            } catch {
                Write-Host "    [!] Failed to verify $($sc.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        if ($downloadErrors -eq 0 -and $downloadChecks -gt 0) {
            Write-Host "  [OK] All $downloadChecks download UUIDs verified successfully." -ForegroundColor Green
        }
    }

    Write-Host "  - Verifying Extraction UUIDs (zipHash+variant -> folder name)" -ForegroundColor Gray
    $repoFolders = Get-ChildItem -Path $ProfilesDir -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $repoFolders) {
        $metaPath = Join-Path $folder.FullName "ProfileMeta.json"
        if (Test-Path $metaPath) {
            try {
                $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
                $variant = if ($meta.profileName -and $meta.profileName -ne "[Root]") { $meta.profileName } else { "" }
                $expectedUuid = Get-ExtractionUUID $meta.zipHash $variant
                $actualUuid = $folder.Name.ToLower()
                if ($expectedUuid.ToLower() -ne $actualUuid) {
                    Write-Host "    [!] Extraction UUID Mismatch in $($actualUuid): Expected $expectedUuid (zipHash: $($meta.zipHash), variant: $variant)" -ForegroundColor Red
                    $extractionErrors++
                }
                $extractionChecks++
            } catch {
                Write-Host "    [!] Failed to verify extraction $($folder.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    if ($extractionErrors -eq 0 -and $extractionChecks -gt 0) {
        Write-Host "  [OK] All $extractionChecks extraction UUIDs verified successfully." -ForegroundColor Green
    }
    
    if ($downloadErrors -gt 0 -or $extractionErrors -gt 0) {
        throw "UUID Verification failed with $downloadErrors download errors and $extractionErrors extraction errors."
    }

    Write-Host "`nTest run complete." -ForegroundColor Green
} finally {
    Stop-Transcript | Out-Null
}
exit 0
#endregion
