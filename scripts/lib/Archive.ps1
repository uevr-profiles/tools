#region Archive Utilities
function Compress-Files($FilePaths, $TargetArchive, $CompressionLevel = 9) {
    Debug-Log "[common.ps1] Compressing $($FilePaths.Count) files into $TargetArchive (Level: $CompressionLevel)"
    $TargetArchive = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetArchive)
    $parent = Split-Path $TargetArchive -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        # Using 7z 'a' to add files. -mx sets compression level (0-9).
        $args = @("a", "-mx$CompressionLevel", "-y", "`"$TargetArchive`"")
        foreach ($f in $FilePaths) { $args += "`"$f`"" }
        $process = Start-Process -FilePath "7z" -ArgumentList $args -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -ne 0) { throw "7z failed to compress files into $TargetArchive (ExitCode: $($process.ExitCode))" }
    } else {
        $level = "Optimal"
        if ($CompressionLevel -le 0) { $level = "NoCompression" }
        elseif ($CompressionLevel -le 1) { $level = "Fastest" }
        Compress-Archive -Path $FilePaths -DestinationPath $TargetArchive -CompressionLevel $level -Update -ErrorAction Stop
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
