Import-Module Sharegate	

$srcSite = Connect-Site -Url "https://ammc-portal.arcelormittal.com/Unit/TemplateOPR" -UserName AMERICAS\svcSP_Farm
$dstSite = Connect-Site -Url "https://ammc-portal-sp.arcelormittal.com/Unit/TemplateOPR" -UserName AMERICAS\svcSP_Farm

$srcSite = Connect-Site -Url "https://ammc-portal.arcelormittal.com/Unit/Template" -UserName AMERICAS\svcSP_Farm
$dstSite = Connect-Site -Url "https://ammc-portal-sp.arcelormittal.com/Unit/TemplateADM" -UserName AMERICAS\svcSP_Farm

$srcSite = Connect-Site -Url "https://ammc-portal.arcelormittal.com/app/CTHubFr" -UserName AMERICAS\svcSP_Farm
$dstSite = Connect-Site -Url "https://ammc-portal-sp.arcelormittal.com/app/CTHubFr" -UserName AMERICAS\svcSP_Farm


Copy-Site -Site $srcSite -DestinationSite $dstSite -Subsites -Merge

