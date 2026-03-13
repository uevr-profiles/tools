using module ".\common.psm1"
using module ".\classes\UEVRProfilesSource.psm1"

param(
    [switch]$Fetch,
    [switch]$Download,
    [switch]$Extract,
    [int]$ProfileLimit = [int]::MaxValue,
    [switch]$Whitelist,
    [switch]$Blacklist,
    [switch]$Silent
)

$source = [UEVRProfilesSource]::new($PSBoundParameters)

if ($Fetch)    { $source.Fetch(); $source.ValidateFetch() }
if ($Download) { $source.Download(); $source.ValidateDownload() }
if ($Extract)  { $source.Extract() }
