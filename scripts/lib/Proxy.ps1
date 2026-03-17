#region Proxy Discovery
function Get-FreshProxyList {
    param (
        
    )
    # Sources for free proxies in plain text (IP:Port)
    $sources = @(
        "https://api.proxyscrape.com/v2/?request=getproxies&protocol=https&timeout=10000&country=all&ssl=yes&anonymity=all",
        "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/https.txt",
        "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-https.txt",
        "https://raw.githubusercontent.com/mmpx12/proxy-list/master/https.txt",
        "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/https.txt",
        "https://raw.githubusercontent.com/Thordata/awesome-free-proxy-list/main/proxies/https.txt",
        "https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS_RAW.txt"
    )

    $proxies = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    
    foreach ($source in $sources) {
        Debug-Log "[Proxy.ps1] Fetching proxies from $source"
        try {
            # Use basic Invoke-WebRequest here to avoid recursion with Network.ps1's wrapper
            $response = Invoke-WebRequest -Uri $source -TimeoutSec 2 -ErrorAction Stop
            $lines = $response.Content -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' }
            foreach ($line in $lines) { $proxies.Add($line) | Out-Null }
        } catch {
            Write-Warning "[Proxy.ps1] Failed to fetch proxies from $source : $($_.Exception.Message)"
        }
    }

    $list = @($proxies) | Sort-Object { Get-Random }
    Debug-Log "[Proxy.ps1] Discovered $($list.Count) fresh proxies."
    return $list
}

function Get-PreparedProxyPool($Proxies, $url) {
    if ($null -eq $Proxies) { return @() }
    $pList = @()
    if ($Proxies -is [string]) {
        $pList = $Proxies -split "," | ForEach-Object { $_.Trim() }
    } elseif ($Proxies -is [array]) {
        $pList = $Proxies
    }
    return $pList | Sort-Object { Get-Random }
}

function Initialize-ProxyPool {
    if (-not $Global:UseProxies) {
        $Global:ProxyPool = @()
        return
    }

    if ($Global:ProxyPool.Count -eq 0) {
        Write-Host "Initializing fresh proxy pool..." -ForegroundColor Cyan
        $Global:ProxyPool = Get-FreshProxyList
    }
}
#endregion
