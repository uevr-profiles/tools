class UpdateSource {
    [string]$SourceName
    [string]$DownloadDir
    [string]$MetadataJson
    [int]$ProfileLimit
    [switch]$Whitelist
    [switch]$Blacklist
    [switch]$Silent
    [hashtable]$Headers

    UpdateSource([string]$name, [hashtable]$params) {
        $this.SourceName    = $name
        $this.ProfileLimit  = if ($null -ne $params.ProfileLimit) { $params.ProfileLimit } else { [int]::MaxValue }
        $this.Whitelist     = $params.Whitelist
        $this.Blacklist     = $params.Blacklist
        $this.Silent        = $params.Silent
        $this.DownloadDir   = Join-Path $Global:BaseTempDir $name
        $this.MetadataJson  = Join-Path $Global:MetaCacheDir "$($name).json"
        $this.Headers       = @{}
        
        # Ensure dirs exist
        foreach ($d in @($this.DownloadDir, $Global:MetaCacheDir)) {
            if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        }
    }

    [void] Fetch() { throw "Fetch() not implemented for $($this.SourceName)" }
    [void] Download() { throw "Download() not implemented for $($this.SourceName)" }
    [void] Extract() { throw "Extract() not implemented for $($this.SourceName)" }

    [void] ValidateFetch() {
        if (-not $this.Silent -and $this.ProfileLimit -ne [int]::MaxValue) {
             if (-not (Test-Path $this.MetadataJson)) { throw "Metadata not found at $($this.MetadataJson)" }
             $data = Get-Content $this.MetadataJson -Raw | ConvertFrom-Json
             if ($data.Count -lt $this.ProfileLimit) {
                 throw "Fatal: $($this.SourceName) fetch count mismatch. Expected at least $($this.ProfileLimit), got $($data.Count). Stopping because -Silent is not set."
             }
        }
    }

    [void] ValidateDownload() {
        if (-not $this.Silent -and $this.ProfileLimit -ne [int]::MaxValue) {
            $zips = @(Get-ChildItem -Path $this.DownloadDir -Filter "*.zip")
            if ($zips.Count -lt $this.ProfileLimit) {
                throw "Fatal: $($this.SourceName) download count mismatch. Expected at least $($this.ProfileLimit), got $($zips.Count). Stopping because -Silent is not set."
            }
        }
    }
}
