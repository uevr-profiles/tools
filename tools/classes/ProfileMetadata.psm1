using module "..\common.psm1"
using module ".\ProfileReadme.psm1"

class ProfileMetadata {
    [string]$ID
    [string]$exeName
    [string]$gameName
    [string]$gameVersion
    [string]$authorName
    [string]$modifiedDate
    [string]$createdDate
    [string]$downloadDate
    [string]$sourceName
    [string]$sourceUrl
    [string]$zipHash
    [string]$downloadUrl
    [string]$sourceDownloadUrl
    [string]$donateURL
    [string]$appID
    [string]$headerPictureUrl
    [Nullable[int]]$minUEVRNightlyNumber
    [Nullable[int]]$maxUEVRNightlyNumber
    [Nullable[bool]]$nullifyPlugins
    [Nullable[bool]]$lateInjection
    [string]$description
    [string]$profileName
    [object[]]$fileCopies
    [string[]]$tags

    ProfileMetadata() {}

    static [ProfileMetadata] FromObject($obj) {
        $meta = [ProfileMetadata]::new()
        if ($null -eq $obj) { return $meta }
        $props = if ($obj -is [System.Collections.IDictionary]) { $obj.Keys } else { $obj.PSObject.Properties.Name }
        foreach ($p in $props) {
            $val = if ($obj -is [System.Collections.IDictionary]) { $obj[$p] } else { $obj.$p }
            if ($null -ne $val -and "$val" -ne "") {
                try { 
                    if ($p -ieq "ID") { $meta.ID = [string]$val }
                    else { $meta.$p = $val }
                } catch {}
            }
        }
        return $meta
    }

    [PSCustomObject] GetCleanObject() {
        $newObj = [ordered]@{}
        $names = $this.PSObject.Properties.Name
        foreach ($name in $names) {
            $val = $this.$name
            if ($null -ne $val -and "$val" -ne "") {
                if ($name -eq "tags") { $newObj[$name] = @($val) }
                else { $newObj[$name] = $val }
            }
        }
        return [PSCustomObject]$newObj
    }

    [string] ToJson() {
        return ConvertTo-Json -InputObject ($this.GetCleanObject()) -Depth 5
    }

    [bool] Validate([string]$jsonPath) {
        if (-not $Global:SchemaContent) { return $true }
        $jsonErr = $null
        $res = if ($jsonPath) {
            Test-Json -Path $jsonPath -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        } else {
            Test-Json -Json ($this.ToJson()) -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        }
        if (-not $res -and $jsonErr) {
            foreach ($err in $jsonErr) {
                Write-Host "        - $($err.Exception.Message)" -ForegroundColor Red
            }
        }
        return $res
    }

    [void] Save([string]$targetDir, [string]$archivePath, [string]$profile) {
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        
        $readmeFile = Join-Path $targetDir "README.md"
        
        if ($profile -and $profile -ne "[Root]") {
            $this.profileName = $profile
        }

        $readmeText = if (Test-Path $readmeFile) { Get-Content $readmeFile -Raw } else { "" }
        $masterDesc = $null
        
        if ($readmeText) { 
            $masterDesc = [ProfileReadme]::ExtractDescription($readmeText)
        } elseif ($this.description) {
            $masterDesc = $this.description
        }

        if ($masterDesc) {
            $readme = [ProfileReadme]::new($this, $masterDesc)
            $readme.Save($readmeFile)
            $this.description = Convert-MarkdownToText $masterDesc 100
        }
        
        Update-GlobalPropsJson $archivePath $profile ($this.GetCleanObject())
        
        $jsonFile = Join-Path $targetDir "ProfileMeta.json"
        try {
            $this.ToJson() | Set-Content $jsonFile -Encoding utf8
        } catch {
            Write-Error "Failed to write ${jsonFile}: $($_.Exception.Message)"
            throw
        }
        
        if (-not $this.Validate($jsonFile)) {
             Write-Warning "    [!] Metadata validation failed for $($this.gameName) ($jsonFile)"
             throw "JSON Schema validation failed for $($this.gameName) ($($this.ID))."
        }
    }
}
