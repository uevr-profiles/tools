using module ".\common.psm1"
using module ".\classes\UEVRDeluxeSource.psm1"

param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

$source = [UEVRDeluxeSource]::new($PSBoundParameters)

if ($Fetch)    { $source.Fetch(); $source.ValidateFetch() }
if ($Download) { $source.Download(); $source.ValidateDownload() }
if ($Extract)  { $source.Extract() }
