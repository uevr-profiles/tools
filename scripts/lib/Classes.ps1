#region Classes
class ProfileReadme {
    [object]$Metadata
    [string]$Content

    ProfileReadme([object]$meta, [string]$content) {
        $this.Metadata = $meta
        $this.Content = [ProfileReadme]::ExtractDescription($content)
    }

    static [string] ExtractDescription([string]$markdown) {
        if ($null -eq $markdown) { return "" }
        if ($markdown -match "(?si)##\s+Description\s+(.*)") {
            return $matches[1].Trim()
        }
        return $markdown.Trim()
    }

    [string] Generate() {
        $meta = $this.Metadata
        $sb = [System.Text.StringBuilder]::new()

        # Banner
        if ($meta.headerPictureUrl) {
            $sb.AppendLine("![$($meta.gameName)]($($meta.headerPictureUrl))")
            $sb.AppendLine()
        }

        # Header
        $head = "# UEVR Profile for "
        $game = $meta.gameName
        if ($meta.profileName -and $meta.profileName -ne "[Root]") { $game += " ($($meta.profileName))" }
        
        if ($meta.appID) {
            $head += "[$game](https://steamdb.info/app/$($meta.appID))"
        } else {
            $head += $game
        }
        
        if ($meta.authorName) {
            $head += " by $($meta.authorName)"
        }
        $sb.AppendLine($head)
        $sb.AppendLine()

        # Table
        $sb.AppendLine("| Property | Value |")
        $sb.AppendLine("| :--- | :--- |")
        $sb.AppendLine("| **Game EXE** | ``$($meta.exeName)`` |")
        if ($meta.gameVersion) { $sb.AppendLine("| **Game Version** | $($meta.gameVersion) |") }
        $sb.AppendLine("| **Source** | [$($meta.sourceName)]($($meta.sourceUrl)) |")
        if ($meta.createdDate) { $sb.AppendLine("| **Created** | $($meta.createdDate) |") }
        if ($meta.modifiedDate) { $sb.AppendLine("| **Modified** | $($meta.modifiedDate) |") }
        if ($meta.tags) {
            $tagStr = ($meta.tags | ForEach-Object { "$_" }) -join ", "
            $sb.AppendLine("| **Tags** | $tagStr |")
        }
        $sb.AppendLine()

        # Description
        if ($this.Content) {
            $sb.AppendLine("## Description")
            $sb.AppendLine()
            $sb.AppendLine($this.Content)
        }

        return $sb.ToString()
    }

    [void] Save([string]$path) {
        $this.Generate() | Set-Content $path -Encoding utf8
    }
}

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
        if ($obj -is [System.Collections.IDictionary]) {
            $props = $obj.Keys
        } else {
            $props = $obj.PSObject.Properties.Name
        }
        foreach ($p in $props) {
            if ($obj -is [System.Collections.IDictionary]) {
                $val = $obj[$p]
            } else {
                $val = $obj.$p
            }
            if ($null -ne $val -and "$val" -ne "") {
                try { 
                    if ($p -ieq "ID") { $meta.ID = [string]$val }
                    elseif ($p -match "Date$") { $meta.$p = Format-DateISO8601 $val }
                    else { $meta.$p = $val }
                } catch {
                    Debug-Log "[ProfileMetadata] Failed to map property ${p}: $($_.Exception.Message)"
                }
            }
        }
        return $meta
    }

    static [bool] Validate($jsonPath) {
        return [ProfileMetadata]::Validate($jsonPath, $null)
    }

    static [bool] Validate($jsonPath, $jsonText) {
        if (-not $Global:SchemaContent) { return $true }
        
        $content = $jsonText
        if ($jsonPath -and (Test-Path $jsonPath)) {
            $content = Get-Content $jsonPath -Raw
        }

        if ([string]::IsNullOrEmpty($content)) {
            Debug-Log "[ProfileMetadata] Validate: No content to validate"
            return $false
        }

        $jsonErr = $null
        $res = Test-Json -Json $content -Schema $Global:SchemaContent -ErrorAction SilentlyContinue -ErrorVariable jsonErr
        
        if (-not $res -and $jsonErr) {
            Debug-Log "[ProfileMetadata] JSON Validation FAILED for content:"
            Debug-Log "$content"
            foreach ($err in $jsonErr) {
                Write-Host "        - $($err.Exception.Message)" -ForegroundColor Red
            }
        }
        return $res
    }

    [bool] ValidateSelf() {
        return [ProfileMetadata]::Validate($null, $this.ToJson())
    }

    [void] Finalize([string]$targetDir, [string]$profile) {
        $readmeFile = Join-Path $targetDir "README.md"
        if ($profile -and $profile -ne "[Root]") { $this.profileName = $profile }
        if (Test-Path $readmeFile) {
            $readmeText = Get-Content $readmeFile -Raw
        } else {
            $readmeText = ""
        }
        if ($readmeText) {
            $masterDesc = [ProfileReadme]::ExtractDescription($readmeText)
        } else {
            if ($this.description) {
                $masterDesc = $this.description
            } else {
                $masterDesc = ""
            }
        }
        if ($masterDesc) {
            $readme = [ProfileReadme]::new($this, $masterDesc)
            $readme.Save($readmeFile)
            $this.description = Convert-MarkdownToText $masterDesc 100
        }
    }

    [PSCustomObject] GetCleanObject() {
        $newObj = [ordered]@{}
        foreach ($name in $this.PSObject.Properties.Name) {
            $val = $this.$name
            if ($null -ne $val -and "$val" -ne "") {
                if ($name -eq "tags") { $newObj[$name] = @($val) }
                else { $newObj[$name] = $val }
            }
        }
        return [PSCustomObject]$newObj
    }

    [string] ToJson() { return ConvertTo-Json -InputObject ($this.GetCleanObject()) -Depth 5 }

    [void] Save([string]$targetDir, [string]$archivePath, [string]$profile) {
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        $this.Finalize($targetDir, $profile)
        Update-GlobalPropsJson $archivePath $profile ($this.GetCleanObject())
        $jsonFile = Join-Path $targetDir "ProfileMeta.json"
        $this.ToJson() | Set-Content $jsonFile -Encoding utf8
        if (-not [ProfileMetadata]::Validate($jsonFile, $null)) { throw "JSON Schema validation failed for $($this.gameName) ($($this.ID))." }
    }
}

class ProfileArchive {
    [string]$Path
    [string[]]$Extensions

    ProfileArchive([string]$path) { $this.Path = $path }

    static [string[]] GetSupportedArchiveExtensions() { return Get-SupportedArchiveExtensions }
    static [string[]] List([string]$path) { return ([ProfileArchive]::new($path)).GetContent() }
    static [void] Extract([string]$path, [string]$destination) { ([ProfileArchive]::new($path)).ExtractTo($destination) }

    [string[]] GetContent() {
        if (-not (Test-Path $this.Path)) { return @() }
        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            $out = & 7z l $this.Path -y 2>$null
            if ($LASTEXITCODE -eq 0) {
                $names = @(); $capture = $false
                foreach ($line in $out) {
                    if ($line -match "^-+\s+-+") { $capture = $true; continue }
                    if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[\.DRHSA]{5}\s+\d+\s+\d+\s+(.*)$") {
                        $names += $matches[1].Trim()
                    }
                }
                if ($names.Count -gt 0) { return $names }
            }
        }
        if ($this.Path -like "*.zip") {
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                $zip = [System.IO.Compression.ZipFile]::OpenRead($this.Path)
                $names = $zip.Entries.FullName; $zip.Dispose(); return $names
            } catch { return @() }
        }
        return @()
    }

    [void] ExtractTo([string]$destination) {
        if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
        $extracted = $false
        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            $process = Start-Process -FilePath "7z" -ArgumentList "x", "`"$($this.Path)`"", "-o$destination", "-y" -PassThru -NoNewWindow
            if ($null -ne $process -and $process.WaitForExit(60000)) { # 60 second timeout
                if ($process.ExitCode -eq 0) { $extracted = $true }
            } elseif ($null -ne $process) {
                Debug-Log "[common.ps1] 7z extraction timed out for $($this.Path). Killing process."
                $process | Stop-Process -Force -ErrorAction SilentlyContinue
                throw "Extraction timed out after 30 seconds: $($this.Path)"
            }
        }
        if (-not $extracted -and ($this.Path -like "*.zip")) {
            try { Expand-Archive -Path $this.Path -DestinationPath $destination -Force -ErrorAction SilentlyContinue; $extracted = $true } catch {}
        }
        if (-not $extracted) { throw "Failed to extract archive: $($this.Path) (7z not found, failed, or timed out)" }
    }
}
#endregion
