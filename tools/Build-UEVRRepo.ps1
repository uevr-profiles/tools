param(
    [string]$ProfilesDir = ".\profiles",
    [string]$SchemaFile  = ".\schemas\ProfileMeta.schema.json",
    [string]$OutputFile  = ".\repo.json"
)

$allMeta = @()
$errors  = 0

if (-not (Test-Path $ProfilesDir)) {
    Write-Error "Profiles directory not found: $ProfilesDir"
    exit 1
}

Get-ChildItem -Path $ProfilesDir -Directory | ForEach-Object {
    $metaFile = Join-Path $_.FullName "ProfileMeta.json"
    if (Test-Path $metaFile) {
        $jsonText = Get-Content $metaFile -Raw
        
        if (Test-Path $SchemaFile) {
            $isValid = Test-Json -Json $jsonText -SchemaFile $SchemaFile -ErrorAction SilentlyContinue
            if (-not $isValid) {
                Write-Host "[!] Schema validation failed for $($metaFile):" -ForegroundColor Red
                try {
                    $detailed = Test-Json -Json $jsonText -SchemaFile $SchemaFile -Detailed
                    foreach ($msg in $detailed.Errors) {
                        Write-Host "    - $msg" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "    - Invalid JSON format or schema." -ForegroundColor Yellow
                }
                $errors++
            }
        }

        try {
            $meta = $jsonText | ConvertFrom-Json
            
            # If exeName is an array, join it with commas for repo.json or handle it as a collection
            if ($meta.exeName -is [System.Collections.IEnumerable] -and $meta.exeName -isnot [string]) {
                $meta.exeName = ($meta.exeName | Sort-Object -Unique) -join ", "
            }

            $allMeta += $meta
        } catch {
            Write-Warning "Could not parse JSON in $metaFile"
            $errors++
        }
    }
}

$allMeta = $allMeta | Sort-Object gameName
$allMeta | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Encoding utf8
Write-Host "Done. repo.json contains $($allMeta.Count) profiles." -ForegroundColor Green
if ($errors -gt 0) {
    Write-Host "Encountered $errors validation/parse errors. Failing build." -ForegroundColor Red
    exit 1
}
