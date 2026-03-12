# ── Common Configuration & Functions ──────────────────────────────────────────

function Get-ProfileDownloadUrl($profileId, $exeName) {
    if ($null -eq $exeName) { $exeName = $profileId }
    $cleanName = $exeName -replace '[^a-zA-Z0-9]', '_'
    # Target URL for the folder downloader pointing to the profile folder in the repo
    $repoUrl = "https://github.com/uevr-profiles/repo/tree/main/profiles/$($profileId)"
    $encodedUrl = [uri]::EscapeDataString($repoUrl)
    return "https://gitfolderdownloader.github.io/?url=$($encodedUrl)&name=$($cleanName)"
}

$RepoRoot    = Split-Path $PSScriptRoot -Parent
$ProfilesDir = Join-Path $RepoRoot "profiles"
$SchemaFile  = Join-Path $RepoRoot "schemas" "ProfileMeta.schema.json"

# Ensure essential directories exist
if (-not (Test-Path $ProfilesDir)) { New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null }

# ── Whitelist Pattern Definitions ────────────────────────────────────────────
function Get-WhitelistPatterns {
    return @(
        "^README\.md$",
        "^ProfileMeta\.json$",
        "^_interaction_profiles_oculus_touch_controller\.json$",
        "^actions\.json$",
        "^binding_rift\.json$",
        "^binding_vive\.json$",
        "^bindings_knuckles\.json$",
        "^bindings_oculus_touch\.json$",
        "^bindings_vive_controller\.json$",
        "^cameras\.txt$",
        "^config\.txt$",
        "^cvars_data\.txt$",
        "^cvars_standard\.txt$",
        "^uevr_nightly_build\.txt$",
        "^user_script\.txt$",
        "^scripts/.*\.lua$",
        "^plugins/.*\.(dll|so)$",
        "^uobjecthook/.*(_props|_mc_state)\.json$",
        "^(_EXTRAS|data|libs|paks)/.+"
    )
}

function Test-Whitelisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    $patterns = Get-WhitelistPatterns
    foreach ($p in $patterns) {
        if ($rel -match $p) { return $true }
    }
    return $false
}

function Is-ProfileFolder($path) {
    if (-not (Test-Path $path)) { return $false }
    # A profile root MUST contain at least one of these essential files
    $essentials = @("config.txt", "cameras.txt", "actions.json", "user_script.txt", "cvardump.json", "cvars_data.txt")
    
    $files = Get-ChildItem -Path $path -File
    foreach ($f in $files) {
        if ($essentials -contains $f.Name) { return $true }
        if ($f.Name -match "^bindings?_.*\.json$") { return $true }
        if ($f.Name -match "^_interaction_profiles_.*\.json$") { return $true }
    }
    return $false
}

function Get-BlacklistPatterns {
    return @(
        "^sdkdump/.*\.(cpp|hpp)$",
        "^plugins/.*\.pdb$",
        "\.bak$",
        "\.org$",
        "^cvardump\.json$"
    )
}

function Test-Blacklisted($relPath) {
    $rel = $relPath.Replace('\', '/').Trim('/')
    $patterns = Get-BlacklistPatterns
    foreach ($p in $patterns) {
        if ($rel -match $p) { return $true }
    }
    return $false
}

function Flatten-Folder($targetDir) {
    $items = Get-ChildItem -Path $targetDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $subDir = $items[0].FullName
        Write-Host "    Found single root directory, flattening: $($items[0].Name)" -ForegroundColor Gray
        Get-ChildItem -Path $subDir | Move-Item -Destination $targetDir -Force
        Remove-Item $subDir -Force
    }
}

function Get-Archive-Entries($path) {
    # Try generic 7z listing first as it handles almost everything
    $out = & 7z l $path -y 2>$null
    if ($LASTEXITCODE -eq 0) {
        # 7zip 'l' output typical line: "2024-03-12 16:35:46 ....        11116         7407  folder/file.txt"
        # We skip lines until we see the "----" separator or match the date pattern
        $names = @()
        $capture = $false
        foreach ($line in $out) {
            if ($line -match "^-+\s+-+") { $capture = $true; continue }
            if ($capture -and $line -match "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[D.][R.][H.][S.][A.]\s+\d+\s+\d+\s+(.*)$") {
                $names += $matches[1].Trim()
            }
        }
        if ($names.Count -gt 0) { return $names }
    }
    
    # Fallback to .NET for ZIPs if 7z fails or missing
    if ($path.EndsWith(".zip")) {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
            $names = $zip.Entries.FullName
            $zip.Dispose()
            return $names
        } catch { return @() }
    }
    return @()
}

function Expand-Archive-Smart($path, $destination) {
    if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
    # Try 7z first
    & 7z x $path "-o$destination" -y | Out-Null
    if ($LASTEXITCODE -ne 0 -and $path.EndsWith(".zip")) {
        Expand-Archive -Path $path -DestinationPath $destination -Force
    }
}

function Extract-And-Discover-Profiles($sourceArchive, $whitelist, $blacklist, $maxDepth = 5) {
    if ($maxDepth -le 0) { return @() }
    
    $tempBase = Join-Path $env:TEMP "uevr_extract_$(New-Guid)"
    Expand-Archive-Smart $sourceArchive $tempBase
    
    $profilesFound = @()
    
    # 1. Look for nested archives
    $archives = Get-ChildItem -Path $tempBase -Recurse -Include "*.zip", "*.7z", "*.rar", "*.tar", "*.gz", "*.bz2", "*.xz"
    foreach ($a in $archives) {
        $aFull = (Get-Item $a.FullName).FullName
        $tFull = (Get-Item $tempBase).FullName
        $relA = ""
        if ($aFull.Length -gt $tFull.Length) {
            $relA = $aFull.Substring($tFull.Length).TrimStart('\')
        }
        $baseName = $a.Name.Replace($a.Extension, "")
        $subContext = if ($relA -match "\\") { 
            ($relA.Substring(0, $relA.LastIndexOf('\')) + "\" + $baseName).Replace('\', ' / ')
        } else { 
            $baseName 
        }

        $subProfiles = Extract-And-Discover-Profiles $a.FullName $whitelist $blacklist ($maxDepth - 1)
        foreach ($sp in $subProfiles) {
            # Prepend the archive's path context to the sub-profile's variant
            if ($sp.Variant) {
                $sp.Variant = "$subContext / $($sp.Variant)"
            } else {
                $sp.Variant = $subContext
            }
            # Also update ProfileName if it was null/empty (meaning it was root in sub-archive)
            if (-not $sp.ProfileName) {
                $sp.ProfileName = $subContext.Split('/')[-1].Trim()
            }
            $profilesFound += $sp
        }
        Remove-Item $a.FullName -Force
    }

    # 2. Look for profile folders
    $candidateFolders = Get-ChildItem -Path $tempBase -Recurse -Directory | Where-Object { Is-ProfileFolder $_.FullName }
    if (Is-ProfileFolder $tempBase) { $candidateFolders += Get-Item $tempBase }

    $sortedCandidates = $candidateFolders | Sort-Object { $_.FullName.Length }
    Write-Host "    Found $($sortedCandidates.Count) candidate profile roots..." -ForegroundColor Gray
    
    $uniqueProfiles = @()
    foreach ($f in $sortedCandidates) {
        $alreadyFound = $false
        foreach ($found in $uniqueProfiles) {
            if ($f.FullName.StartsWith($found.FullName + "\")) { $alreadyFound = $true; break }
        }
        if (-not $alreadyFound) { $uniqueProfiles += $f }
    }

    foreach ($f in $uniqueProfiles) {
        $profileId = New-Guid
        $cleanTarget = Join-Path $env:TEMP "uevr_profile_$profileId"
        New-Item -ItemType Directory -Path $cleanTarget -Force | Out-Null
        
        $fFull = (Get-Item $f.FullName).FullName
        $tFull = (Get-Item $tempBase).FullName
        $relPath = ""
        if ($fFull.Length -gt $tFull.Length) {
            $relPath = $fFull.Substring($tFull.Length).TrimStart('\')
        }
        
        Write-Host "    Processing discovered profile root: $(if ($relPath) { $relPath } else { '[Root]' })" -ForegroundColor Gray
        Copy-Item -Path "$($fFull)\*" -Destination $cleanTarget -Recurse -Force
        
        $profileName = $null
        $variant = $relPath.Replace('\', ' / ')
        if ($relPath) {
            $profileName = $relPath.Split('\')[-1]
        }

        Remove-NonWhitelisted $cleanTarget -applyWhitelist:$whitelist -applyBlacklist:$blacklist
        
        $finalFiles = Get-ChildItem -Path $cleanTarget -Recurse | Where-Object { -not $_.PSIsContainer }
        if ($finalFiles.Count -gt 0) {
            $profilesFound += @{
                Path        = $cleanTarget
                Variant     = $variant
                ProfileName = $profileName
            }
        } else {
            Write-Host "    [!] Profile variant '$variant' was empty after filtering." -ForegroundColor Yellow
            Remove-Item $cleanTarget -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $profilesFound
}

function Remove-NonWhitelisted($targetDir, $applyWhitelist, $applyBlacklist) {
    if (-not (Test-Path $targetDir)) { return }
    Flatten-Folder $targetDir
    
    $basePath = (Get-Item $targetDir).FullName.TrimEnd('\')
    $allItems = Get-ChildItem -Path $basePath -Recurse
    foreach ($item in $allItems) {
        if (-not (Test-Path $item.FullName)) { continue }
        
        $rel = $item.FullName.Substring($basePath.Length).TrimStart('\').Replace('\', '/')
        if ($null -eq $rel -or $rel -eq "") { continue }
        
        $isDir = $item.PSIsContainer
        if ($applyBlacklist -and (Test-Blacklisted $rel)) {
            Write-Host "    Removed blacklist match: $rel" -ForegroundColor Gray
            Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
            continue
        }
        
        if ($applyWhitelist -and -not (Test-Whitelisted $rel)) {
            if (-not $isDir) {
                Write-Host "    Removed non-whitelisted: $rel" -ForegroundColor Gray
                Remove-Item $item.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    $foundEmpty = $true
    while ($foundEmpty) {
        $foundEmpty = $false
        $dirs = Get-ChildItem -Path $targetDir -Recurse -Directory
        foreach ($d in $dirs) {
            if ((Get-ChildItem $d.FullName).Count -eq 0) {
                Remove-Item $d.FullName -Force -ErrorAction SilentlyContinue
                $foundEmpty = $true
            }
        }
    }
}

function Get-OrCreateUUID($originalId) {
    if ($originalId -and $originalId -match '^[0-9a-fA-F]{8}-' -and $originalId -ne "00000000-0000-0000-0000-000000000000") { return $originalId }
    return [guid]::NewGuid().ToString()
}

function Find-ExistingProfileFolder($uuid) {
    $path = Join-Path $ProfilesDir $uuid
    if (Test-Path $path) { return $path }
    return $null
}

function Get-FileHashMD5($path) {
    if (-not (Test-Path $path)) { return $null }
    return (Get-FileHash -Path $path -Algorithm MD5).Hash
}

function Find-ProfileByHash($hash) {
    if (-not $hash) { return $null }
    $foundId = $null
    Get-ChildItem -Path $ProfilesDir -Filter "ProfileMeta.json" -Recurse | ForEach-Object {
        try {
            if ($null -ne $foundId) { return }
            $m = Get-Content $_.FullName -Raw | ConvertFrom-Json
            if ($m.zipHash -eq $hash) { $foundId = $m.ID }
        } catch {}
    }
    return $foundId
}

function Test-Metadata($json, $path) {
    if (-not (Test-Path $SchemaFile)) { return $true }
    return Test-Json -Json $json -SchemaFile $SchemaFile
}

function Remove-NullProperties($obj) {
    if ($null -eq $obj) { return $null }
    $newObj = [ordered]@{}
    $dateRegex = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"
    
    if ($obj -is [System.Collections.IDictionary]) {
        foreach ($key in $obj.Keys) {
            $val = $obj[$key]
            if ($null -ne $val) {
                if ($val -is [string]) { $val = $val.Trim() }
                if (($val -as [string]) -ne "") {
                    if ($key -match "Date$" -or ($val -match "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}")) {
                        try {
                            $dt = [DateTime]::Parse($val)
                            $val = $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                        } catch {}
                    }
                    $newObj[$key] = $val
                }
            }
        }
    } else {
        foreach ($prop in $obj.PSObject.Properties) {
            $val = $prop.Value
            if ($null -ne $val) {
                if ($val -is [string]) { $val = $val.Trim() }
                if (($val -as [string]) -ne "") {
                    if ($prop.Name -match "Date$" -and $val -match $dateRegex) {
                        try { $val = [DateTime]::Parse($val).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") } catch {}
                    }
                    $newObj[$prop.Name] = $val
                }
            }
        }
    }
    return [PSCustomObject]$newObj
}

function Get-CleanVariantName($variant, $currentExe) {
    if (-not $variant) { return $null }
    $segments = $variant.Split(@(" / "), [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    $validSegments = @()
    foreach ($s in $segments) {
        if ($s -ieq "Root") { continue }
        $cleanS = $s.Replace("-Win64-Shipping", "").Replace("-Win64-DebugGame", "").Replace(".zip", "").Trim()
        $cleanE = if ($currentExe) { $currentExe.Replace("-Win64-Shipping", "").Replace("-Win64-DebugGame", "").Trim() } else { "" }
        if ($cleanE -and $cleanS -ieq $cleanE) { continue }
        if ($s -match "-Win64-(Shipping|DebugGame|Development|Test)$") { continue }
        $validSegments += $s
    }
    if ($validSegments.Count -eq 0) { return $null }
    return $validSegments -join " / "
}

function Convert-MarkdownToText($md, $maxLen = 100) {
    if ($null -eq $md) { return "" }
    $txt = $md -replace '(?m)^#+\s+', ''
    $txt = $txt -replace '\*\*|__', ''
    $txt = $txt -replace '\*|_', ''
    $txt = $txt -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    $txt = $txt -replace '`', ''
    $txt = $txt -replace '(?m)^\s*>\s+', ''
    $txt = $txt -replace '(?m)^\s*[-*+]\s+', ''
    $txt = $txt -replace '\r?\n', ' '
    $txt = $txt.Trim()
    if ($txt.Length -gt $maxLen) {
        return $txt.Substring(0, $maxLen - 3) + "..."
    }
    return $txt
}

function Finalize-ProfileMetadata($targetDir, $meta, $profileName) {
    $readmeFile = Join-Path $targetDir "README.md"
    $legacyDesc = Join-Path $targetDir "ProfileDescription.md"
    $readmeText = if (Test-Path $readmeFile) { Get-Content $readmeFile -Raw } else { "" }
    $descText   = if (Test-Path $legacyDesc) { Get-Content $legacyDesc -Raw } else { "" }
    
    $rawDesc = if ($readmeText -and $descText) {
        $readmeText + "`n`n" + $descText
    } elseif ($readmeText) {
        $readmeText
    } else {
        $descText
    }
    
    if ($profileName) {
        $escapedName = [regex]::Escape($profileName)
        $rawDesc = $rawDesc -replace "(?m)^\s*#\s+$escapedName\s*", ""
    }
    $rawDesc = $rawDesc.Trim()

    $appLink = if ($meta.appID) { "https://steamdb.info/app/$($meta.appID)" } else { "" }
    $gamePart = if ($appLink) { "[$($meta.gameName)]($appLink)" } else { $meta.gameName }
    $pName = if ($profileName) { $profileName } else { "Profile" }
    
    $header = "# $pName by $($meta.authorName) for $gamePart"
    $banner = if ($meta.headerPictureUrl) { "![$($meta.gameName)]($($meta.headerPictureUrl))" } else { "" }

    $table = "| Prop | Value |`n| --- | --- |"
    $skipRows = @("description", "profileName", "appID", "authorName", "headerPictureUrl", "gameName", "sourceUrl", "sourceDownloadUrl")
    foreach ($key in $meta.Keys) {
        if ($skipRows -contains $key) { continue }
        $val = $meta[$key]
        if ($null -eq $val -or "$val" -eq "") { continue }
        $cleanVal = "$val".Replace('|', '\|')
        if ($key -eq "sourceName" -and $meta.sourceUrl) {
            $cleanVal = "[$cleanVal]($($meta.sourceUrl))"
        } elseif ($key -eq "zipHash" -and $meta.sourceDownloadUrl) {
            $cleanVal = "[$cleanVal]($($meta.sourceDownloadUrl))"
        }
        $table += "`n| **$key** | $cleanVal |"
    }

    $finalMd = @"
$header
$banner

$table
"@

    if ($rawDesc) {
        $finalMd += "`n`n## Description:`n$rawDesc"
    }

    $finalMd.Trim() | Set-Content $readmeFile -Encoding utf8
    if ($rawDesc) {
        $meta["description"] = Convert-MarkdownToText $rawDesc 100
    }
    if (Test-Path $legacyDesc) { Remove-Item $legacyDesc -Force }
    if ($profileName) { $meta["profileName"] = $profileName }
    return $meta
}

function Print-ProfileInfo($meta, $zipPath) {
    Write-Host "  - Profile $($meta.ID)" -ForegroundColor Cyan
    Write-Host "    - Game:       $($meta.gameName) ($($meta.exeName))" -ForegroundColor Gray
    Write-Host "    - Author:     $($meta.authorName)" -ForegroundColor Gray
    Write-Host "    - Source:     $($meta.sourceName) ($($meta.sourceUrl))" -ForegroundColor Gray
    Write-Host "    - ZIP:        $(if ($zipPath) { Split-Path $zipPath -Leaf } else { 'N/A' })" -ForegroundColor Gray
    Write-Host "    - Hash:   $($meta.zipHash)" -ForegroundColor Gray
    Write-Host "    - URL:   $($meta.sourceDownloadUrl)" -ForegroundColor Gray
    
    if ($zipPath -and (Test-Path $zipPath)) {
        Write-Host "  - ZIP Content List:" -ForegroundColor Cyan
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
            $zip.Entries | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor DarkGray }
            $zip.Dispose()
        } catch {
            Write-Host "    [!] Failed to list ZIP contents: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - [!] ZIP file not found at $zipPath" -ForegroundColor Red
    }
}
