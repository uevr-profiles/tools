#region Heuristics & Text
function Get-HeuristicTags($profileDir, $meta, $profile) {
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $hasMC = $false; $hasUObject = $false
    if (Test-Path $profileDir) {
        $uDir = Join-Path $profileDir "uobjecthook"
        if (Test-Path $uDir) {
            $hasUObject = $true
            if (Get-ChildItem -Path $uDir -Filter "*_mc_state.json" -Recurse) { $hasMC = $true }
        }
    }
    if ($hasMC) { $tagSet.Add("6DOF") | Out-Null; $tagSet.Add("Motion Controls") | Out-Null }
    elseif ($hasUObject) { $tagSet.Add("3DOF") | Out-Null }
    $textSources = @()
    if ($meta.description) { $textSources += $meta.description }
    if ($meta.gameName) { $textSources += $meta.gameName }
    if ($profile) { $textSources += $profile }
    if (Test-Path $profileDir) {
        Get-ChildItem -Path $profileDir -File | Where-Object { $_.Extension -match "txt|md|json|lua" } | ForEach-Object { try { $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue; if ($c) { $textSources += $c } } catch {} }
    }
    $allText = $textSources -join "`n"
    $is3DOF = $profile -match "3\s*dof"; $is6DOF = $profile -match "6\s*dof"
    if ($allText -match "motion\s+controls" -and (-not $is3DOF -or $profile -match "motion")) { $tagSet.Add("Motion Controls") | Out-Null }
    if ($allText -match "6\s*dof" -and -not $is3DOF) { $tagSet.Add("6DoF") | Out-Null }
    if ($allText -match "3\s*dof" -and -not $is6DOF) { $tagSet.Add("3DoF") | Out-Null }
    $finalTags = [System.Collections.Generic.List[string]]::new($tagSet)
    if ($is3DOF) { for ($i = $finalTags.Count - 1; $i -ge 0; $i--) { if ($finalTags[$i] -match "6\s*dof") { $finalTags.RemoveAt($i) } } }
    if ($is6DOF) { for ($i = $finalTags.Count - 1; $i -ge 0; $i--) { if ($finalTags[$i] -match "3\s*dof") { $finalTags.RemoveAt($i) } } }
    return @($finalTags | Sort-Object | Select-Object -Unique)
}

function Convert-MarkdownToText($md, $maxLen = 100) {
    if ($null -eq $md) { return "" }
    $txt = $md -replace '(?m)^#+\s+', '' -replace '\*\*|__', '' -replace '\*|_', '' -replace '\[([^\]]+)\]\([^\)]+\)', '$1' -replace '`', '' -replace '(?m)^\s*>\s+', '' -replace '(?m)^\s*[-*+]\s+', '' -replace '\r?\n', ' '
    $txt = $txt.Trim()
    
    $res = $txt
    if ($txt.Length -gt $maxLen) {
        $res = $txt.Substring(0, $maxLen - 3) + "..."
    }
    return $res
}
#endregion
