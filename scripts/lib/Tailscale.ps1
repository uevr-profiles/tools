#region Tailscale & Mullvad
function Get-MullvadExitNodes {
    if ($Global:TailscaleNodeCache.Count -gt 0) { return $Global:TailscaleNodeCache }
    
    Debug-Log "[Tailscale.ps1] Fetching Mullvad exit nodes..."
    try {
        $out = & tailscale exit-node list | Out-String
        # Pattern: 100.x.x.x  hostname.mullvad.ts.net  Country  City
        # Fixed regex to allow leading whitespace and capture country/city correctly
        $nodeMatches = [regex]::Matches($out, '(?m)^\s*(\d{1,3}(?:\.\d{1,3}){3})\s+([^\s]+mullvad\.ts\.net)\s+(\S+)\s+([^\s-]+(?:\s+[^\s-]+)*)')
        $nodes = foreach ($m in $nodeMatches) {
            [PSCustomObject]@{ 
                IP = $m.Groups[1].Value; 
                Hostname = $m.Groups[2].Value;
                Country = $m.Groups[3].Value;
                City = $m.Groups[4].Value
            }
        }
        $Global:TailscaleNodeCache = $nodes
        Debug-Log "[Tailscale.ps1] Found $($nodes.Count) Mullvad exit nodes."
        return $nodes
    } catch {
        Write-Warning "[Tailscale.ps1] Failed to list tailscale exit nodes: $($_.Exception.Message)"
        return @()
    }
}

function Set-TailscaleExitNode($node) {
    if ($null -eq $node) {
        Debug-Log "[Tailscale.ps1] Resetting exit node"
        & tailscale set --exit-node= | Out-Null
        return
    }

    if ($node.Hostname) {
        $identifier = $node.Hostname
    } else {
        $identifier = $node.IP
    }
    
    $locationInfo = ""
    if ($node.Country) {
        $locationInfo = " ($($node.Country)"
        if ($node.City) {
            $locationInfo += ", $($node.City)"
        }
        $locationInfo += ")"
    }
    
    Write-Host "Setting Tailscale exit node to $identifier$locationInfo..." -ForegroundColor Cyan
    & tailscale set --exit-node="$identifier" | Out-Null

    # User Request: Sufficient delay and double check
    $maxAttempts = 5
    for ($i = 1; $i -le $maxAttempts; $i++) {
        Debug-Log "[Tailscale.ps1] Waiting for VPN establishment (Attempt $i/$maxAttempts)..."
        Debug-Log "Waiting 2s..."
        Start-Sleep -Seconds 2
        
        $status = & tailscale status --json | ConvertFrom-Json
        if ($status.ExitNodeStatus -and $status.ExitNodeStatus.Online) {
             # Double check internet connectivity via the exit node
             # We try a quick head request to a reliable service
             try {
                $check = Invoke-WebRequest -Uri "http://1.1.1.1" -Method Head -TimeoutSec 3 -ErrorAction SilentlyContinue 2>$null
                if ($null -ne $check) {
                    Write-Host "  [OK] Tailscale VPN established and verified." -ForegroundColor Green
                    return $true
                }
             } catch { }
        }
    }
    
    Write-Warning "[Tailscale.ps1] Failed to verify Tailscale connection after switching to $identifier"
    return $false
}

function Reset-TailscaleExitNode {
    Set-TailscaleExitNode $null
}
#endregion
