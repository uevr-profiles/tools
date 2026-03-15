$url = "https://cdn.discordapp.com/attachments/1267831700772356116/1280187670731034695/VisionsofMana-Win64-Shipping.zip?ex=69b821ad&is=69b6d02d&hm=24f29b2b0cca15051913f057551160c141df0dbea40da41669bba143bcf09b2e&"

Write-Host "Detailed SSL Diagnosis..." -ForegroundColor Cyan

# Protocols
Write-Host "Supported Security Protocols: $([Net.ServicePointManager]::SecurityProtocol)"
Write-Host "Available Protocols in Enum:"
[Enum]::GetValues([Net.SecurityProtocolType]) | ForEach-Object { Write-Host "  - $_ ($([int]$_))" }

try {
    Write-Host "`nAttempting Invoke-WebRequest..."
    Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -SkipCertificateCheck -ErrorAction Stop
    Write-Host "[OK] Success!" -ForegroundColor Green
} catch {
    Write-Host "[FAILED]" -ForegroundColor Red
    $err = $_.Exception
    while ($null -ne $err) {
        Write-Host "Exception: $($err.GetType().FullName)" -ForegroundColor Yellow
        Write-Host "Message: $($err.Message)" -ForegroundColor Gray
        if ($err -is [System.Net.Http.HttpRequestException] -and $null -ne $err.StatusCode) {
            Write-Host "HTTP Status: $($err.StatusCode)"
        }
        $err = $err.InnerException
    }
}
