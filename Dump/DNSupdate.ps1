# **********************************************************************************
# Script to update DNS
# IMPORTANT : Need DNS Server Tools.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2015-11-10  Benoit Blais        Cération initiale du script
# **********************************************************************************

# *****************************FONCTION SEND EMAIL**********************************
function SendEmail([string]$From, [string]$To, [string]$Subject, [string]$Error, [string]$Server, [string]$Port) {
  $body = "<HEAD>"
  $body = $body + "<title>Mise &agrave; jour DNS - VMware SRM / DNS Update - VMware SRM</title>"
  $body = $body + "<meta content=""text/html; charset=utf-8"" http-equiv=""Content-Type"" />"
  $body = $body + "<style type=""text/css"">"
  $body = $body + "<!--"
  $body = $body + "p {font-family: Arial; font-size:12px; color:#5e5f62; background-color:#FFF; margin:0px;padding:0px;}"
  $body = $body + "-->"
  $body = $body + "</style>"
  $body = $body + "</head>"
  $body = $body + "<body style=""margin: 0; padding: 10px;"">"
  $body = $body + "<table cellspacing=""10"" align=""left"" width=""800"" style=""font-size: 11px; margin: 0px; border: 1px solid; background-color: #fff; font-family: Arial; color: #5e5f62;"" >"
  $body = $body + "<tr height=""25"" Align=""top"">"
  $body = $body + "<td style=""vertical-align: bottom;""><p style=""font-family: Arial; font-size:16px; font-weight:bold; color:#6388A1; background-color:#FFF; margin:0px;padding:0px; vertical-align:bottom;"">"
  $body = $body + "Log du script permettant de mettre &agrave; jour les enregistrements DNS suite &agrave; une action du plan de recouvrement SRM /<BR>Log of the script to update the DNS record following an action of the SRM recovery plan"
  $body = $body + "</p></td><td align=""Right"">"
  $body = $body + "<img src=""http://www.bba.ca/themes/cgp/images/site/bba_entete.jpg"" alt=""BBA inc."" style=""border: 0px none; vertical-align:bottom;""/>"
  $body = $body + "</td></tr><tr height=""2"" style=""vertical-align: top;""><td style=""border: 1px solid;border-top-color: #6388A1;border-left-color: #fff;border-right-color: #fff;border-bottom-color: #fff;""></td><td></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 10px 0px 0px; padding: 0px;"">"
  $body = $body + "Ce courriel s&rsquo;adresse au technicien responsable de la solution VMware SRM.<br><br>"
  $body = $body + "Lorsqu&rsquo;un serveur d&eacute;marre dans un site de recouvrement, les enregistrements DNS doivent &ecirc;tre mis &agrave; jour manuellement afin de r&eacute;duire le temps de la panne au minimum.<br><br>"
  $body = $body + "&#8226; T&acirc;che ex&eacute;cut&eacute; sur : <b>" + $env:computername + "</b><br>"
  $body = $body + "&#8226; Droit minimum requis : <b>DnsAdmins, Administrators et  Server Operators</b><br><br>"
  $body = $body + "&#8226; Mode de recouvrement : <b>" + $env:VMware_RecoveryMode + "</b><br>"
  $body = $body + "&#8226; Serveur vCenter de destination : <b>" + $env:VMware_VC_Host + "</b><br>"
  $body = $body + "&#8226; Nom du serveur recouvert : <b>" + $env:VMware_VM_Name + "</b><br>"
  $body = $body + "&#8226; Adresse IP du serveur recouvert : <b>" + $env:VMware_VM_GuestIp + "</b><br>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 10px 0px 0px; padding: 0px;color:#6388A1;"">"
  $body = $body + "*****"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 10px 0px 0px; padding: 0px;"">"
  $body = $body + "This email is for the person in charge of VMware SRM solution.<br><br>"
  $body = $body + "When a server starts in a recovery site, the DNS records must be manually updated to reduce the time of the failure to a minimum.<br><br>"
  $body = $body + "&#8226; Task execute on: <b>" + $env:computername + "</b><br>"
  $body = $body + "&#8226; Minimum rights: <b>DnsAdmins, Administrators et  Server Operators</b><br>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""20"" style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""font-family: Arial; font-size:16px; font-weight:bold; color:#6388A1; margin:0px; padding:0px; vertical-align:middle;"">"
  $body = $body + "Log"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""4"" style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 0px; padding: 0px;"">"
  $body = $body + $Error
  $body = $body + "</p></td></tr>"
  $body = $body + "</table>"
  $body = $body + "</body>"
  $body = $body + "</html>"
  Send-MailMessage -To $smtpTo -Subject $messageSubject -Body $body -SmtpServer $smtpServer -From $smtpFrom -BodyAsHtml -Port $smtpPort
  exit 0
}
# **********************************************************************************

# Environment Setup 
$DNSZone = 'bba.ca'
$smtpFrom = 'NoReply@bba.ca'
$smtpTo = 'ServiceInformatique@bba.ca'
$smtpServer = 'intmail.bba.ca'
$smtpPort = '25'
$messageSubject = 'Mise a jour DNS - VMware SRM / DNS Update - VMware SRM'
$strFileName="C:\Script\Logs.txt"

# **********************************************************************************

# Get server name and ip address to update
$RecoveryMode = $env:VMware_RecoveryMode 
if (!$RecoveryMode) {
  $ErrorMessage = 'ERROR : No Recovery Mode'
  SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
  }
if ($RecoveryMode -eq "test") {
  exit 0
  }
$Server = $env:VMware_VM_Name
if (!$RecoveryMode) {
  $ErrorMessage = 'ERROR : No server name'
  SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
  }
$IPaddress = $env:VMware_VM_GuestIp
if (!$RecoveryMode) {
  $ErrorMessage = 'ERROR : No IP Address'
  SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
  }

# Set the error prefer action
$ErrorActionPreference = "SilentlyContinue"

# Find your DNS server
$DNS = cmd /c nltest /dclist:$DNSZone | select-string -pattern '(?im)BBADC.+?(?=\.)' -AllMatches | foreach {$_.Matches} | forEach-Object {$_.Value}
$writableDNS = cmd /c nltest /dnsgetdc:$DNSZone | select-string -pattern '(?im)BBADC.+?(?=\.)' -AllMatches | foreach {$_.Matches} | forEach-Object {$_.Value}
$writableDNS = $writableDNS.ToUpper()
$rodcDNS = @()
foreach ($DNSvalue in $DNS) {
  $Find = 'False'
  foreach ($writableDNSvalue in $writableDNS) {
    if ($DNSvalue -like $writableDNSvalue) {$Find = 'True'}
    }
  if ($Find -like 'False') {$rodcDNS = $rodcDNS + $DNSvalue}
  }  

# Update Writable DNS server
foreach ($DNSServer in $writableDNS) {

  # Build our DNSCMD DELETE command syntax 
  $cmdDelete = "dnscmd $DNSServer /nodedelete $DNSZone $Server /f"

  # Build our DNSCMD ADD command syntax
  $cmdAdd = "dnscmd $DNSServer /RecordAdd $DNSZone $Server /aging 1200 A $IPaddress" 

  # Now we execute the command 
  Try{
    $er = Invoke-Expression $cmdDelete
    if ($lastexitcode) {throw $er}
    } 
  Catch{
    $ErrorMessage = $ErrorMessage + 'Command : ' + $cmdDelete + '<br>'
    $ErrorMessage = $ErrorMessage + 'Error code ' + $lastexitcode + '<br>'
    $ErrorMessage = $ErrorMessage + 'Error description : ' + $er + '<br>'
    }
  Try{
    $er = Invoke-Expression $cmdAdd
    if ($lastexitcode) {throw $er}
    } 
  Catch{  
    $ErrorMessage = $ErrorMessage + 'Command : ' + $cmdcmdAdd + '<br>'
    $ErrorMessage = $ErrorMessage + 'Error code ' + $lastexitcode + '<br>'
    $ErrorMessage = $ErrorMessage + 'Error description : ' + $er + '<br>'
    }
  }

foreach ($DNSServer in $rodcDNS) {
  
  # Build our DNSCMD ZONEUPDATE command syntax 
  $cmdUpdate = "dnscmd $DNSServer /zoneupdatefromds $DNSZone"

  # Now we execute the command
  Try{
    $er = Invoke-Expression $cmdUpdate
    if ($lastexitcode) {throw $er}
    } 
  Catch{  
    $ErrorMessage = $ErrorMessage + 'Command : ' + $cmdUpdate + '<br>'
    $ErrorMessage = $ErrorMessage + 'Error code : ' + $lastexitcode + '<br>'
    $ErrorMessage = $ErrorMessage + 'Error description : ' + $er + '<br>'
    } 
  }

# Send email message
if (!$ErrorMessage) {
  $ErrorMessage = 'No error'
  }
SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort