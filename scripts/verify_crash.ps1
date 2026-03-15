. ./common.ps1
$url = "https://cdn.discordapp.com/attachments/1085961489778737182/1458540062294671442/Stray-Win64-Shipping.zip?ex=69b85749&is=69b705c9&hm=61dcb4e9072dc4b0924b334212e7e06ec398023af784fcd5f6be72844f445ba8&"
$target = Join-Path $env:TEMP "stray_test.zip"

Write-Host "Running dangerous web request test..."
try {
    Invoke-WebRequestWithRetry -url $url -targetFile $target -Silent:$false -retries 1
    Write-Host "[OK] Success!"
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
}
Write-Host "End of script."
