#Import certificate
$Cert = Import-PfxCertificate -FilePath "C:\Install\asg-mbox-dv-001.pfx" -Password (ConvertTo-SecureString -String 'Cascades' -AsPlainText -Force) -CertStoreLocation Cert:\LocalMachine\My 

#Change website bingind for https
$Binding = Get-WebBinding -Name "CTIWebApps"
New-WebBinding -name "CTIWebApps" -Protocol https -Port 443 
$certPath = "cert:\LocalMachine\MY\$($Cert.Thumbprint)"
$providerPath = 'IIS:\SSLBindings\0.0.0.0!443'
Get-Item $certPath | new-Item $providerPath
                                    
#Install URL Rewrite module
Start-Process -FilePath msiexec.exe -ArgumentList "/I C:\install\rewrite_amd64_en-US.msi /qn" -Wait

#Create URL Rewite rule
$site = "iis:\sites\CTIWebApps"
$filterRoot = "system.webServer/rewrite/rules/rule[@name='HTTP to HTTPS$_']"
Clear-WebConfiguration -pspath $site -filter $filterRoot
Add-WebConfigurationProperty -pspath $site -filter "system.webServer/rewrite/rules" -name "." -value @{name='HTTP to HTTPS' + $_ ;patternSyntax='Regular Expressions';stopProcessing='True'}
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/match" -name "url" -value "(.*)"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/conditions" -name "logicalGrouping" -value "MatchAll"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/conditions" -name "." -value @{input = '{HTTPS}';matchType ='0';pattern ='off';ignoreCase ='True';negate ='False'},@{input = '{SERVER_ADDR}';matchType ='0';pattern ='::1';ignoreCase ='True';negate ='True'},@{input = '{SERVER_ADDR}';matchType ='0';pattern ='127.0.0.1';ignoreCase ='True';negate ='True'}
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/action" -name "type" -value "Redirect"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/action" -name "url" -value "https://asg-mbox-dv-001.ad.cascades.com/{R:1}"
Set-WebConfigurationProperty -pspath $site -filter "$filterRoot/action" -name "redirectType" -value "Found" 
invoke-command -scriptblock {iisreset}
