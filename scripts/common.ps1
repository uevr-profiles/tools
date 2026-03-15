$LibPath = Join-Path $PSScriptRoot "lib"

# Load modules in linear dependency order to avoid circular issues
. "$LibPath\Config.ps1"     # No dependencies
. "$LibPath\IO.ps1"         # Depends on Config
. "$LibPath\Classes.ps1"    # Depends on IO/Config
. "$LibPath\Archive.ps1"    # Depends on IO/Config
. "$LibPath\Tracking.ps1"   # Depends on Config
. "$LibPath\Network.ps1"    # Depends on Config
. "$LibPath\Heuristics.ps1" # Depends on IO/Config
. "$LibPath\Profile.ps1"    # Depends on Classes/Heuristics/IO/Config
. "$LibPath\Extraction.ps1" # Depends on Profile/Classes/IO/Config
