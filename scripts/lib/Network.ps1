#region Network Utilities

function Invoke-WebRequestWithRetry($url, $targetFile, $headers = @{}, $retries = 3, $Silent = $false, $Proxies = $null, $TimeoutSec = 5) {
    # Ensure modern SSL/TLS protocols are enabled and ignore certificate errors for this request
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    
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
        # Try current working proxy first if it exists
        if ($Global:CurrentWorkingProxy -and -not $Global:DeadProxies.Contains($Global:CurrentWorkingProxy)) {
            $p = $Global:CurrentWorkingProxy
            $proxyUri = if ($p -match "^https?://") { $p } else { "http://$p" }
            Debug-Log "[Network.ps1] Trying current working proxy: $proxyUri for URL: $url"
            
            $hardFail = $false
            for ($i = 1; $i -le $retries; $i++) {
                Debug-Log "Waiting 1s..."
                Start-Sleep -Seconds 1 # Global delay between all network requests
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
                    Write-Host "  [!] Current working proxy $p failed: $lastErr" -ForegroundColor Gray
                    
                    # Hard-fail detection: timeout, refused, or specific status codes
                    if ($lastErr -match "(Timeout|refused|403|429|500)") {
                        $hardFail = $true
                        break # Stop retrying THIS proxy
                    }
                }
            }
            if ($hardFail -or $i -gt $retries) {
                if (-not $Global:DeadProxies.Contains($p)) {
                    Debug-Log "[Network.ps1] Blacklisting current working proxy: $p"
                    $Global:DeadProxies.Add($p) | Out-Null
                    $Global:CurrentWorkingProxy = $null
                }
            }
        }
        
        # Try other proxies if current one failed or doesn't exist
        foreach ($p in $pool) {
            if ($triedCount -ge $Global:ProxyLimit) { 
                Debug-Log "[Network.ps1] Reached ProxyLimit ($Global:ProxyLimit). Moving to next tier."
                break 
            }
            if ($null -eq $p -or $p -ieq "DIRECT") { continue }
            if ($Global:DeadProxies.Contains($p)) { continue }
            if ($p -eq $Global:CurrentWorkingProxy) { continue } # Skip if we already tried it

            $triedCount++
            $proxyUri = if ($p -match "^https?://") { $p } else { "http://$p" }
            Debug-Log "[Network.ps1] Testing Proxy: $proxyUri for URL: $url"
            
            $hardFail = $false
            for ($i = 1; $i -le $retries; $i++) {
                Debug-Log "Waiting 1s..."
                Start-Sleep -Seconds 1 # Global delay between all network requests
                try {
                    Debug-Log "[Network.ps1] Attempt $i/$retries via $p"
                    $params = @{
                        Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                        SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
                        Proxy = $proxyUri
                    }
                    if ($targetFile) { $params["OutFile"] = $targetFile }
                    
                    Invoke-WebRequest @params | Out-Null
                    $Global:CurrentWorkingProxy = $p # Set as current working proxy
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
            # Start-Sleep handled globally inside the retry loop
        }
    }

    # 2. Tailscale Mullvad Tier (if enabled)
    if ($Global:UseTailscale) {
        $nodes = Get-MullvadExitNodes | Where-Object { -not $Global:DeadTailscaleNodes.Contains($_.Hostname) } | Get-Random -Count $Global:TailscaleLimit
        
        # Try current working tailscale node first if it exists
        if ($Global:CurrentWorkingTailscaleNode -and -not $Global:DeadTailscaleNodes.Contains($Global:CurrentWorkingTailscaleNode.Hostname)) {
            $node = $Global:CurrentWorkingTailscaleNode
            if (Set-TailscaleExitNode $node) {
                $hardFail = $false
                for ($i = 1; $i -le $retries; $i++) {
                    Debug-Log "Waiting 1s..."
                    Start-Sleep -Seconds 1 # Global delay between all network requests
                    try {
                        Debug-Log "[Network.ps1] Trying $url via current Tailscale: $($node.Hostname) (Attempt $i/$retries)"
                        $params = @{
                            Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                            SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
                        }
                        if ($targetFile) { $params["OutFile"] = $targetFile }

                        Invoke-WebRequest @params | Out-Null
                        return # SUCCESS!
                    } catch {
                        $lastErr = $_.Exception.Message
                        Write-Host "  [!] Current Tailscale $($node.Hostname) failed: $lastErr" -ForegroundColor Gray
                        
                        # Hard-fail detection for VPN nodes as well
                        if ($lastErr -match "(Timeout|refused|403|429|500)") {
                            $hardFail = $true
                            break
                        }
                    }
                }
                if ($hardFail -or $i -gt $retries) {
                    if (-not $Global:DeadTailscaleNodes.Contains($node.Hostname)) {
                        Debug-Log "[Network.ps1] Blacklisting current Tailscale node: $($node.Hostname)"
                        $Global:DeadTailscaleNodes.Add($node.Hostname) | Out-Null
                        $Global:CurrentWorkingTailscaleNode = $null
                    }
                }
            }
        }
        
        # Try other nodes if current one failed or doesn't exist
        foreach ($node in $nodes) {
            if ($node.Hostname -eq $Global:CurrentWorkingTailscaleNode.Hostname) { continue } # Skip if we already tried it
            if (Set-TailscaleExitNode $node) {
                $hardFail = $false
                for ($i = 1; $i -le $retries; $i++) {
                    Debug-Log "Waiting 1s..."
                    Start-Sleep -Seconds 1 # Global delay between all network requests
                    try {
                        Debug-Log "[Network.ps1] Trying $url via Tailscale: $($node.Hostname) (Attempt $i/$retries)"
                        $params = @{
                            Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                            SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
                        }
                        if ($targetFile) { $params["OutFile"] = $targetFile }

                        Invoke-WebRequest @params | Out-Null
                        $Global:CurrentWorkingTailscaleNode = $node # Set as current working node
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
        Debug-Log "Waiting 1s..."
        Start-Sleep -Seconds 1 # Global delay between all network requests
        try {
            Debug-Log "[Network.ps1] Direct Attempt $i/$retries"
            if (-not $Silent) { 
                Write-Host "  [~] Downloading (Direct Attempt $i/$retries)... please wait." -ForegroundColor Cyan 
            }
            $params = @{
                Uri = $url; Headers = $headers; UserAgent = $userAgent; 
                SkipCertificateCheck = $true; ErrorAction = "Stop"; TimeoutSec = $TimeoutSec;
            }
            if ($targetFile) { $params["OutFile"] = $targetFile }
            Invoke-WebRequest @params | Out-Null
            return # SUCCESS!
        } catch {
            $lastErr = $_.Exception.Message
            if ($_.Exception.InnerException) { $lastErr = $_.Exception.InnerException.Message }
            Write-Host "  [!] Direct attempt $i failed: $lastErr" -ForegroundColor Gray
            
            # Fallback 1: WebClient for tricky SSL/CDN issues (like Discord)
            if ($lastErr -match "(SSL|transport connection|forcibly closed)") {
                Debug-Log "[Network.ps1] Attempting WebClient fallback for direct connection..."
                try {
                    # For WebClient, we must explicitly ensure the global callback is active right before the call
                    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add("User-Agent", $userAgent)
                    foreach ($key in $headers.Keys) { $wc.Headers.Add($key, $headers[$key]) }
                    if ($targetFile) {
                        $wc.DownloadFile($url, $targetFile)
                    } else {
                        $wc.DownloadString($url) | Out-Null
                    }
                    Debug-Log "[Network.ps1] WebClient fallback succeeded."
                    return # SUCCESS!
                } catch {
                    $lastErr = "WebClient fallback failed: $($_.Exception.Message)"
                    Debug-Log "[Network.ps1] $lastErr"
                    
                    # Fallback 2: Native curl.exe (Bypasses .NET SSL stack entirely)
                    Debug-Log "[Network.ps1] Attempting native curl.exe fallback..."
                    try {
                        $curlArgs = @("-s", "-L", "-k") # Silent, follow redirects, insecure (skip cert check)
                        if ($targetFile) {
                            $curlArgs += @("-o", $targetFile)
                        }
                        $curlArgs += @($url)
                        $curlArgs += @("-H", "User-Agent: $userAgent")
                        foreach ($key in $headers.Keys) { $curlArgs += @("-H", "${key}: $($headers[$key])") }
                        
                        & curl.exe @curlArgs
                        if ($LASTEXITCODE -eq 0 -and (-not $targetFile -or (Test-Path $targetFile))) {
                            Debug-Log "[Network.ps1] curl.exe fallback succeeded."
                            return # SUCCESS!
                        } else {
                            throw "curl.exe exited with code $LASTEXITCODE"
                        }
                    } catch {
                        $lastErr = "curl.exe fallback failed: $($_.Exception.Message)"
                        Debug-Log "[Network.ps1] $lastErr"
                    }
                }
            }
        }
    }

    $finalMsg = "All tiers failed for $url. Last error: $lastErr"
    if ($Silent) { Write-Warning "  [!] $finalMsg" }
    else { throw "Fatal: $finalMsg" }
}
#endregion
