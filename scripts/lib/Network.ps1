#region Network Utilities
$Global:ActiveProxyPool = @()
$Global:DeadProxies     = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Get-PreparedProxyPool($requestedProxies, $url = $null) {
    if ($null -eq $requestedProxies) { return @($null) }
    
    $rawList = @()
    if ($requestedProxies -is [System.Management.Automation.PSCustomObject]) {
        # Map format: { "proxy": ["domain1", "domain2"] }
        foreach ($prop in $requestedProxies.PSObject.Properties) {
            $proxy = $prop.Name
            $domains = @($prop.Value)

            if ($null -eq $url -or $proxy -eq "DIRECT") {
                $rawList += $proxy
            } else {
                # Check if this proxy is verified for the target domain
                foreach ($d in $domains) {
                    if ($url -match [regex]::Escape($d)) {
                        $rawList += $proxy
                        break
                    }
                }
            }
        }
        # If no specialized proxies found for this domain, fall back to all
        if ($rawList.Count -le 1 -and $rawList -contains "DIRECT" -and $null -ne $url) {
             foreach ($prop in $requestedProxies.PSObject.Properties) {
                if ($prop.Name -ne "DIRECT") { $rawList += $prop.Name }
             }
        }
    }
    elseif ($requestedProxies -is [array]) { $rawList = $requestedProxies }
    else { $rawList = $requestedProxies -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ } }

    $finalPool = @()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($p in $rawList) {
        if ($p -ieq "DIRECT") {
            if ($seen.Add("DIRECT_MARKER")) { $finalPool += $null }
            continue
        }
        
        if (-not $Global:DeadProxies.Contains($p)) {
            if ($seen.Add($p)) { $finalPool += $p }
        }
    }

    if ($finalPool.Count -eq 0) { $finalPool += $null } 
    return $finalPool
}

function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 2, $Silent = $false, $Proxies = $null, $TimeoutSec = 10) {
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    if ($headers["User-Agent"]) { $userAgent = $headers["User-Agent"]; $headers.Remove("User-Agent") }
    
    # Prepare the pool: Respect the user's order and handle the new map format
    $finalPool = Get-PreparedProxyPool $Proxies $url

    $lastErr = "No connection attempted"
    
    foreach ($p in $finalPool) {
        $proxyLabel = $p ? $p : "Direct"
        Debug-Log "[common.ps1] Trying $url via $proxyLabel for $($TimeoutSec)s"

        for ($i = 1; $i -le $retries; $i++) {
            $requestParams = @{
                Uri = $url
                Headers = $headers
                UserAgent = $userAgent
                SkipCertificateCheck = $true
                ErrorAction = "Stop"
                TimeoutSec = $TimeoutSec
            }
            if ($targetFile) { $requestParams["OutFile"] = $targetFile }
            $actualProxy = ($p -eq "DIRECT") ? $null : $p
            if ($actualProxy) { $requestParams["Proxy"] = $actualProxy }

            try {
                if ($i -gt 1) { 
                    Write-Host "    [Retry $i/$retries] via $proxyLabel..." -ForegroundColor Yellow 
                }
                
                # Add random jitter between 500ms and 2s to avoid bot detection
                if ($i -gt 1) { Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000) }
                
                # We use a background thread for the request because Invoke-WebRequest can ignore TimeoutSec 
                # if the connection is established but data is flowing at ~0 bytes/sec.
                $job = Start-Job -ScriptBlock {
                    param($p, $rp)
                    if ($p) { $rp["Proxy"] = $p }
                    Invoke-WebRequest @rp | Out-Null
                } -ArgumentList $p, $requestParams

                $waitTimeout = $TimeoutSec + 5 # Give it a few extra seconds for the job overhead
                if (Wait-Job $job -Timeout $waitTimeout) {
                    $result = Receive-Job $job -ErrorAction Stop
                    return # SUCCESS!
                } else {
                    Stop-Job $job -PassThru | Remove-Job -Force
                    throw "Absolute timeout ($($waitTimeout)s) reached"
                }
            } catch {
                $lastErr = $_.Exception.Message
                if ($_.Exception.InnerException) { $lastErr = $_.Exception.InnerException.Message }
                $statusCode = 0
                if ($_.Exception.Response) { 
                    $statusCode = [int]$_.Exception.Response.StatusCode 
                } elseif ($lastErr -match "\((\d{3})\)") {
                    $statusCode = [int]$matches[1]
                }

                # Clear blockades: 403 Forbidden, 429 Too Many Requests, 500 Internal Server Error (often Azure block)
                if ($statusCode -in @(403, 429, 500)) {
                    Write-Host "  [!] Proxy $proxyLabel blocked/failed ($statusCode). Moving to next proxy." -ForegroundColor Red
                    if ($p) { $Global:DeadProxies.Add($p) | Out-Null }
                    break # Break inner retry loop, move to next proxy in the pool
                }

                Write-Host "  [!] Attempt $i via $proxyLabel failed: $lastErr" -ForegroundColor Gray
                # If it's a timeout or connection issue, we keep trying this proxy up to $retries
            }
        }

        # If we finished all retries for this proxy without success, mark it dead
        if ($p -and -not $Global:DeadProxies.Contains($p)) {
            Write-Host "  [!] Proxy $proxyLabel failed all $retries attempts. Removing from active pool." -ForegroundColor Yellow
            $Global:DeadProxies.Add($p) | Out-Null
        }
    }

    $finalMsg = "All proxies and connection attempts failed for $url. Last error: $lastErr"
    if ($Silent) { Write-Warning "  [!] $finalMsg" }
    else { throw "Fatal: $finalMsg" }
}
#endregion
