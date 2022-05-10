# **********************************************************************************
# Script to list user account in specefic OU
# IMPORTANT : Active Directory module for Windows Powershell.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2018-09-13  Benoit Blais        Cération initiale du script
# **********************************************************************************

# *****************************FONCTION SEND EMAIL**********************************
function SendEmail([string]$From, [string]$To, [string]$Subject, [string]$Error, [string]$Server, [string]$Port) {
  $body = "<HEAD>"
  $body = $body + "<title>Palo Alto - Liste d'exclusion AD / Palo Alto - AD exclusion list</title>"
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
  $body = $body + "<td style=""vertical-align: bottom;""><p style=""font-family: Arial; font-size:16px; font-weight:bold; color:#F0B530; background-color:#FFF; margin:0px;padding:0px; vertical-align:bottom;"">"
  $body = $body + "Palo Alto - Liste d'exclusion AD / Palo Alto - AD exclusion list"
  $body = $body + "</p></td><td align=""Right"">"
  $body = $body + "</td></tr><tr height=""2"" style=""vertical-align: top;""><td style=""border: 1px solid;border-top-color: #F0B530;border-left-color: #fff;border-right-color: #fff;border-bottom-color: #fff;""></td><td></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 10px 0px 0px; padding: 0px;"">"
  $body = $body + "Ce courriel s&rsquo;adresse au technicien responsable de la solution Palo Alto.<br><br>"
  $body = $body + "Afin de ne pas alourdir la liste de correspondance usager / adresse IP, une liste d'exclusion peut &ecirc;tre cr&eacute;&eacute;e pour les comptes de service. Cette liste doit &ecirc;tre enregistr&eacute;e dans le fichier C:\Program Files (x86)\Palo Alto Networks\User-ID Agent\ignore_user_list.txt.<br><br>"
  $body = $body + "&#8226; T&acirc;che ex&eacute;cut&eacute; sur : <b>" + $env:computername + "</b><br>"
  $body = $body + "&#8226; Droit minimum requis : <b>DnsAdmins, Administrators et  Server Operators</b><br><br>"
  $body = $body + "&#8226; Fr&eacute;quence : <b>Chaque samedi</b><br>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 10px 0px 0px; padding: 0px;color:#F0B530;"">"
  $body = $body + "*****"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""margin: 10px 0px 0px; padding: 0px;"">"
  $body = $body + "This email is for the person in charge of Palo Alto solution.<br><br>"
  $body = $body + "To not overload the user / IP address match list, an exclusion list can be created for service accounts. This list should be saved in the C:\Program Files (x86)\Palo Alto Networks\User-ID Agent\ignore_user_list.txt file.<br><br>"
  $body = $body + "&#8226; Task execute on: <b>" + $env:computername + "</b><br>"
  $body = $body + "&#8226; Minimum rights: <b>DnsAdmins, Administrators et  Server Operators</b><br>"
  $body = $body + "&#8226; Frequency : <b>Every Saturday</b><br>"
  $body = $body + "</p></td></tr>"
  $body = $body + "<tr height=""20"" style=""vertical-align: top;""><td valign=""top"" colspan=""2"" style=""vertical-align: top;"">"
  $body = $body + "<p style=""font-family: Arial; font-size:16px; font-weight:bold; color:#F0B530; margin:0px; padding:0px; vertical-align:middle;"">"
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
$smtpFrom = 'zPaloAlto@robert.ca'
$smtpTo = 'Firewall-Alerts@robert.ca'
$smtpServer = 'smtp.robert.ca'
$smtpPort = '25'
$messageSubject = "Palo Alto - Liste d'exclusion AD / Palo Alto - AD exclusion list"
$strFileName='C:\Program Files (x86)\Palo Alto Networks\User-ID Agent\ignore_user_list.txt'
$strServiceName = "UserIDService"
$aOU = @()
$aOU += "ou=Service_account,ou=Serveur,dc=robert,dc=ca"
$aOU += "ou=WPA2- Security,dc=robert,dc=ca"

# **********************************************************************************

# Set the error prefer action
$ErrorActionPreference = "Stop"

# Import Active Directory Module to use Get-ADUser command
Try{
    Import-Module ActiveDirectory
    } 
  Catch{
    $ErrorMessage = 'Unable to import Active Directory Module'
    SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
    }

# Clear file content to add new values
Try{
    Clear-Content -path $strFileName
    }
  Catch{
    $ErrorMessage = 'Unable to clear file content.'
    SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
    }

# List all user in specific OU and create logon name and pre windows 2000 logon name.
Try{
    Foreach($OU in $aOU){
        $ADUser = Get-ADUser -Filter * -SearchBase $OU |FT SamAccountName -HideTableHeaders | Out-String
        $ArrayUser = $ADUser.Split([environment]::NewLine)
        Foreach ($Row in $ArrayUser){
            if($row){
                $row.ToString().Trim() + "@robert.ca" | Out-File $strFileName -Append
                "robert.ca\" + $row.ToString().Trim() | Out-File $strFileName -Append
            }
        }
    }
   }
  Catch{
    $ErrorMessage = 'Unable get AD user list.'
    SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
    }

# Restart service to make the change available.
Try{
    Restart-Service -name $strServiceName
    }
  Catch {
    $ErrorMessage = 'Unable to restart service.'
    SendEmail $smtpFrom $smtpTo $messageSubject $ErrorMessage $smtpServer $smtpPort
    }
