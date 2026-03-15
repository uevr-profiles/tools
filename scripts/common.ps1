$LibPath = Join-Path $PSScriptRoot "lib"

# Load modules in linear dependency order to avoid circular issues
. "$LibPath\Config.ps1"     # No dependencies
. "$LibPath\IO.ps1"         # Depends on Config
. "$LibPath\Proxy.ps1"      # Depends on Config/IO
. "$LibPath\Tailscale.ps1"  # Depends on Config/Network
. "$LibPath\Network.ps1"    # Depends on Config/Proxy/Tailscale
. "$LibPath\Classes.ps1"    # Depends on IO/Config/Network
. "$LibPath\Archive.ps1"    # Depends on IO/Config
. "$LibPath\Tracking.ps1"   # Depends on Config
. "$LibPath\Heuristics.ps1" # Depends on IO/Config
. "$LibPath\Profile.ps1"    # Depends on Classes/Heuristics/IO/Config
. "$LibPath\Extraction.ps1" # Depends on Profile/Classes/IO/Config
