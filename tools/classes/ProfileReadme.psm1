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
        $title = $meta.gameName
        if ($meta.profileName -and $meta.profileName -ne "[Root]") { $title += " ($($meta.profileName))" }
        $sb.AppendLine("# $title")
        $sb.AppendLine()

        # Table
        $sb.AppendLine("| Property | Value |")
        $sb.AppendLine("| :--- | :--- |")
        $sb.AppendLine("| **Author** | $($meta.authorName) |")
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
