pwsh -File Update-FromDiscord.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads
pwsh -File Update-FromUEVRDeluxe.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads
pwsh -File Update-FromUEVRProfiles.ps1 -Fetch -Download -Extract -Whitelist -CleanCache -CleanDownloads
pwsh -File Deduplicate-Profiles.ps1 -Delete
pwsh -File Build-UEVRRepo.ps1
