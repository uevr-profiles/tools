param(
    [switch]$FetchNew = $true,
    [switch]$TestExisting = $true,
    [int]$Limit = 50,
    [switch]$Debug
)

#region Dependencies
. "$PSScriptRoot\common.ps1"
$Global:Debug = $Debug
#endregion

$LogsDir = Join-Path $RepoRoot "logs"
$UnixTime = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$LogFile = Join-Path $LogsDir "$($UnixTime)_Update-Proxies.log"

if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
Write-Host "Logging to $LogFile" -ForegroundColor DarkGray
Start-Transcript -Path $LogFile -Append -Force | Out-Null

try {
    $Domains = @(
        "https://firestore.googleapis.com",
        "https://us-central1-uevrprofiles.cloudfunctions.net",
        "https://firebasestorage.googleapis.com",
        "https://uevrdeluxefunc.azurewebsites.net"
    )

    $ProxyPool = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($TestExisting) {
        Write-Host "Re-verifying existing proxies..." -ForegroundColor Cyan
        if (Test-Path $ProxiesFile) {
            $existing = Get-Content $ProxiesFile -Raw | ConvertFrom-Json
            foreach ($p in $existing) {
                $ProxyPool.Add($p) | Out-Null
            }
        }
    }

    if ($FetchNew) {
        Write-Host "Fetching new proxies from multiple sources..." -ForegroundColor Cyan
        
        $Sources = @(
            @{ Name = "Proxifly"; Url = "https://cdn.jsdelivr.net/gh/proxifly/free-proxy-list@main/proxies/protocols/https/data.txt"; Format = "txt" },
            @{ Name = "Jetkai"; Url = "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-https.txt"; Format = "txt" },
            @{ Name = "RoosterKid"; Url = "https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS_RAW.txt"; Format = "txt" },
            @{ Name = "Vakhov"; Url = "https://vakhov.github.io/fresh-proxy-list/https.txt"; Format = "txt" },
            @{ Name = "Zaeem20"; Url = "https://raw.githubusercontent.com/Zaeem20/FREE_PROXIES_LIST/master/https.txt"; Format = "txt" },
            @{ Name = "Komutan"; Url = "https://raw.githubusercontent.com/komutan234/Proxy-List-Free/main/proxies/http.txt"; Format = "txt" },
            @{ Name = "ShiftyTR"; Url = "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/proxy.txt"; Format = "txt" },
            @{ Name = "Monosans"; Url = "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt"; Format = "txt" },
            @{ Name = "Monosans-Socks5"; Url = "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/socks5.txt"; Format = "txt" },
            @{ Name = "ProxyScrape"; Url = "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=5000&country=all&ssl=yes&anonymity=all"; Format = "txt" },
            @{ Name = "Geonode"; Url = "https://proxylist.geonode.com/api/proxy-list?limit=500&page=1&sort_by=lastChecked&sort_type=desc&protocols=http%2chttps"; Format = "geonode" }
        )

        foreach ($source in $Sources) {
            Write-Host "  - From $($source.Name)..." -ForegroundColor Gray
            try {
                $resp = Invoke-WebRequest -Uri $source.Url -UseBasicParsing -TimeoutSec 15
                if ($source.Format -eq "txt") {
                    $lines = $resp.Content -split "`n" | ForEach-Object { $_.Trim() } 
                    foreach ($l in $lines) {
                        if ($l -match '^\d{1,3}(\.\d{1,3}){3}:\d+$') {
                            $ProxyPool.Add("http://$l") | Out-Null
                        } elseif ($l -match '^https?://\d{1,3}(\.\d{1,3}){3}:\d+$') {
                            $ProxyPool.Add($l) | Out-Null
                        }
                    }
                } elseif ($source.Format -eq "geonode") {
                    $json = $resp.Content | ConvertFrom-Json
                    foreach ($p in $json.data) {
                        $ProxyPool.Add("http://$($p.ip):$($p.port)") | Out-Null
                    }
                }
            } catch {
                Write-Warning "Failed to fetch from $($source.Name): $($_.Exception.Message)"
            }
        }
    }

    $total = $ProxyPool.Count
    $testPool = $ProxyPool
    if ($Limit -gt 0 -and $total -gt $Limit) {
        Write-Host "Limiting test pool to $Limit proxies for faster verification..." -ForegroundColor Gray
        $testPool = $ProxyPool | Select-Object -First $Limit
    }

    Write-Host "Testing $($testPool.Count) proxies against $($Domains.Count) domains in parallel..." -ForegroundColor Cyan

    $WorkingProxies = $testPool | ForEach-Object -Parallel {
        $p = $_
        $all = $using:Domains
        $dbg = $using:Debug

        function Test-Url($proxy, $url) {
            try {
                # Some proxies fail HEAD requests but allow GET. 
                # We also allow 404 because some API root endpoints return 404 instead of 200.
                $r = Invoke-WebRequest -Uri $url -Proxy $proxy -TimeoutSec 10 -ErrorAction Stop -Method Get
                return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500)
            } catch {
                if ($_.Exception.Response) {
                    $code = [int]$_.Exception.Response.StatusCode
                    return ($code -ge 200 -and $code -lt 500)
                }
                return $false 
            }
        }

        if ($p -eq "DIRECT") { return $null } # Handled separately

        $successful = @()
        foreach ($d in $all) {
            if (Test-Url $p $d) {
                $successful += $d
            }
        }

        if ($successful.Count -gt 0) {
            Write-Host "  [FOUND] $p ($($successful.Count)/$($all.Count) domains)" -ForegroundColor Green
            return [PSCustomObject]@{ Proxy = $p; Domains = $successful }
        }
        return $null
    } -ThrottleLimit 40

    $Results = [ordered]@{}
    # Always ensure DIRECT is first and works for all domains
    $Results["DIRECT"] = $Domains

    $foundCount = 0
    foreach ($w in $WorkingProxies) {
        if ($null -ne $w) {
            $foundCount++
            Write-Host "  DEBUG: Adding to results: $($w.Proxy) ($($w.Domains.Count) domains)" -ForegroundColor Gray
            $Results[$w.Proxy] = @($w.Domains)
        }
    }

    Write-Host "`nFound $($Results.Count) total working proxy profiles (including DIRECT)." -ForegroundColor Cyan
    Write-Host "Discovered $foundCount functional external proxies." -ForegroundColor Gray
    ConvertTo-Json -InputObject $Results -Depth 5 | Set-Content $ProxiesFile -Encoding utf8
    Write-Host "Updated $ProxiesFile" -ForegroundColor Green

} finally {
    Stop-Transcript | Out-Null
}
