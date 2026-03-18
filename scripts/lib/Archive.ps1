#region Archive Utilities
function Compress-Files($FilePaths, $TargetArchive, $CompressionLevel = 9, $BaseDir = $null) {
    if ($null -eq $FilePaths -or $FilePaths.Count -eq 0) { return }
    Debug-Log "[common.ps1] Compressing $($FilePaths.Count) files into $TargetArchive (Level: $CompressionLevel, BaseDir: $BaseDir)"
    $TargetArchive = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetArchive)
    $parent = Split-Path $TargetArchive -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    # If BaseDir is provided, convert all paths to relative to avoid duplicate filename errors in 7z
    $finalPaths = $FilePaths
    $listFile = Join-Path $env:TEMP "7z_list_$([Guid]::NewGuid().Guid).txt"
    try {
        if ($null -ne $BaseDir) {
            $BaseDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BaseDir)
            $oldLocation = Get-Location
            Set-Location $BaseDir
            $finalPaths = $FilePaths | ForEach-Object { [IO.Path]::GetRelativePath($BaseDir, $_) }
        }

        if (Get-Command 7z -ErrorAction SilentlyContinue) {
            # Use a list file to avoid 'The filename or extension is too long' (Windows CLI limit)
            $finalPaths | Out-File -FilePath $listFile -Encoding utf8 -Force
            # Using 7z 'a' with @listfile. -mx sets compression level (0-9).
            $args = @("a", "-mx$CompressionLevel", "-y", "`"$TargetArchive`"", "`"@$listFile`"")
            $process = Start-Process -FilePath "7z" -ArgumentList $args -PassThru -NoNewWindow -Wait
            if ($process.ExitCode -ne 0) { throw "7z failed to compress files into $TargetArchive (ExitCode: $($process.ExitCode))" }
        } else {
            $level = "Optimal"
            if ($CompressionLevel -le 0) { $level = "NoCompression" }
            elseif ($CompressionLevel -le 1) { $level = "Fastest" }
            Compress-Archive -Path $finalPaths -DestinationPath $TargetArchive -CompressionLevel $level -Update -ErrorAction Stop
        }
    } finally {
        if ($null -ne $BaseDir) { Set-Location $oldLocation }
        if (Test-Path $listFile) { Remove-Item $listFile -Force -ErrorAction SilentlyContinue }
    }
}

function Compress-Folder($FolderPath, $TargetArchive, $CompressionLevel = 9) {
    Debug-Log "[common.ps1] Compressing folder $FolderPath into $TargetArchive (Level: $CompressionLevel)"
    $TargetArchive = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetArchive)
    $FolderPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FolderPath)
    
    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        $process = Start-Process -FilePath "7z" -ArgumentList "a", "-mx$CompressionLevel", "-y", "`"$TargetArchive`"", "`"$FolderPath\*`"" -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -ne 0) { throw "7z failed to compress folder $FolderPath (ExitCode: $($process.ExitCode))" }
    } else {
        Compress-Archive -Path "$FolderPath\*" -DestinationPath $TargetArchive -CompressionLevel "Optimal" -Update -ErrorAction Stop
    }
}
#endregion
