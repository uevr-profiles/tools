#region Network Utilities

function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 2, $Silent = $false, $Proxies = $null, $TimeoutSec = 10) {
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    if ($headers["User-Agent"]) { $userAgent = $headers["User-Agent"]; $headers.Remove("User-Agent") }
    
    $lastErr = "No connection attempted"

    # 1. Scraped Proxies Tier (if enabled)
    if ($Global:UseProxies -or $Proxies) {
        Initialize-ProxyPool
        if ($Proxies) {
            $pool = Get-PreparedProxyPool $Proxies $url
        } else {
            $pool = $Global:ProxyPool
        }
        
        $triedCount = 0
        foreach ($p in $pool) {
            if ($triedCount -ge $Global:ProxyLimit) { 
                Debug-Log "[Network.ps1] Reached ProxyLimit ($Global:ProxyLimit). Moving to next tier."
                break 
            }
            if ($null -eq $p -or $p -ieq "DIRECT") { continue }
            if ($Global:DeadProxies.Contains($p)) { continue }

            $triedCount++
            $proxyUri = if ($p -match "^https?://") { $p } else { "http://$p" }
            Debug-Log "[Network.ps1] Testing Proxy: $proxyUri for URL: $url"
            
            $hardFail = $false
            for ($i = 1; $i -le $retries; $i++) {
                try {
                    Debug-Log "[Network.ps1] Attempt $i/$retries via $p"
                    $params = @{
                        Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                        SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
                        Proxy = $proxyUri
                    }
                    if ($targetFile) { $params["OutFile"] = $targetFile }
                    
                    Invoke-WebRequest @params | Out-Null
                    return # SUCCESS!
                } catch {
                    $lastErr = $_.Exception.Message
                    if ($_.Exception.InnerException) { $lastErr = $_.Exception.InnerException.Message }
                    Write-Host "  [!] Proxy $p failed: $lastErr" -ForegroundColor Gray
                    
                    # Hard-fail detection: timeout, refused, or specific status codes
                    if ($lastErr -match "(Timeout|refused|403|429|500)") {
                        $hardFail = $true
                        break # Stop retrying THIS proxy
                    }
                }
            }
            if ($hardFail -or $i -gt $retries) {
                if (-not $Global:DeadProxies.Contains($p)) {
                    Debug-Log "[Network.ps1] Blacklisting proxy: $p"
                    $Global:DeadProxies.Add($p) | Out-Null
                }
            }
            Start-Sleep -Milliseconds 100 # Delay between proxy attempts to prevent hangs
        }
    }

    # 2. Tailscale Mullvad Tier (if enabled)
    if ($Global:UseTailscale) {
        $nodes = Get-MullvadExitNodes | Where-Object { -not $Global:DeadTailscaleNodes.Contains($_.Hostname) } | Get-Random -Count $Global:TailscaleLimit
        foreach ($node in $nodes) {
            if (Set-TailscaleExitNode $node) {
                $hardFail = $false
                for ($i = 1; $i -le $retries; $i++) {
                    try {
                        Debug-Log "[Network.ps1] Trying $url via Tailscale: $($node.Hostname) (Attempt $i/$retries)"
                        $params = @{
                            Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                            SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
                        }
                        if ($targetFile) { $params["OutFile"] = $targetFile }

                        Invoke-WebRequest @params | Out-Null
                        Reset-TailscaleExitNode
                        return # SUCCESS!
                    } catch {
                        $lastErr = $_.Exception.Message
                        Write-Host "  [!] Tailscale $($node.Hostname) failed: $lastErr" -ForegroundColor Gray
                        
                        # Hard-fail detection for VPN nodes as well
                        if ($lastErr -match "(Timeout|refused|403|429|500)") {
                            $hardFail = $true
                            break
                        }
                    }
                }
                if ($hardFail -or $i -gt $retries) {
                    if (-not $Global:DeadTailscaleNodes.Contains($node.Hostname)) {
                        Debug-Log "[Network.ps1] Blacklisting Tailscale node: $($node.Hostname)"
                        $Global:DeadTailscaleNodes.Add($node.Hostname) | Out-Null
                    }
                }
            }
        }
        Reset-TailscaleExitNode
    }

    # 3. Direct Tier (Always last resort or if others disabled)
    Debug-Log "[Network.ps1] Trying $url via Direct"
    for ($i = 1; $i -le $retries; $i++) {
        try {
            $params = @{
                Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
            }
            if ($targetFile) { $params["OutFile"] = $targetFile }
            Invoke-WebRequest @params | Out-Null
            return # SUCCESS!
        } catch {
            $lastErr = $_.Exception.Message
            Write-Host "  [!] Direct attempt $i failed: $lastErr" -ForegroundColor Gray
        }
    }

    $finalMsg = "All tiers failed for $url. Last error: $lastErr"
    if ($Silent) { Write-Warning "  [!] $finalMsg" }
    else { throw "Fatal: $finalMsg" }
}
#endregion
