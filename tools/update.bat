pwsh -File tools\Update-FromDiscord.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads
pwsh -File tools\Update-FromUEVRDeluxe.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads
pwsh -File tools\Update-FromUEVRProfiles.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads
pwsh -File tools\Deduplicate-Profiles.ps1 -Delete
pwsh -File tools\Build-UEVRRepo.ps1
