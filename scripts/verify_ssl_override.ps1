. ./common.ps1
$url = "https://cdn.discordapp.com/attachments/1267831700772356116/1280187670731034695/VisionsofMana-Win64-Shipping.zip?ex=69b821ad&is=69b6d02d&hm=24f29b2b0cca15051913f057551160c141df0dbea40da41669bba143bcf09b2e&"

Write-Host "Testing SSL override to ignore errors..." -ForegroundColor Cyan

try {
    # Check if the global callback is set
    $callback = [Net.ServicePointManager]::ServerCertificateValidationCallback
    if ($null -ne $callback) {
        Write-Host "[OK] Global Certificate Validation Callback is set." -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Global Certificate Validation Callback is NOT set." -ForegroundColor Red
    }

    # Attempt a quick head request
    Invoke-WebRequestWithRetry -url $url -Silent:$false -retries 1 -TimeoutSec 5
    Write-Host "[OK] SSL connection successful with global override!" -ForegroundColor Green
} catch {
    Write-Host "[FAILED] Error during SSL override test: $($_.Exception.Message)" -ForegroundColor Red
}
