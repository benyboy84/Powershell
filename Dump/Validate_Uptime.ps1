# **********************************************************************************
# Script to validate uptime of servers in Citrix Cloud.
#
# IMPORTANT : 
# This script have these requirements:
#  - Need Powershell SDK install on computer.
#  - Need Citrix Secure Client File.
#
# This script must be use in Windows Scheduled Task.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate log file in the same folder as the script.
#
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2021-12-28  Benoit Blais        Original version
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

# **********************************************************************************

####MANDATORY MANUAL CONFIGURATION

#File containing the secure client login information sur Citrix Cloud
$SecureClientFile = "Citrix\secureclient.csv"
#Citrix Admin Address
$CitrixAdminAddress = "asg-ctx-pr-001"
#Citrix Customer Id
$CustomerId = "CascadesCent"
#Citrix Profile Name
$ProfileName = "CitrixTask"

#Information about the email send at the end of the task
$smtpFrom = "NoReply@Cascades.com"
$smtpTo = "SRV_CTI_Train-EO_Transformers@Cascades.com"
$smtpServer = "smtp.cascades.com"
$smtpPort = "25"
#Define the team responsible of this scheduled task
$TeamName = "Transformers"

#URL for Microsoft Team Webhook connector
$URI = 'https://cascades.webhook.office.com/webhookb2/86f163cd-63f8-4778-9ef6-d1e19cd27ae9@a866874a-d0e3-4a03-a79d-4c893ab51296/IncomingWebhook/71898ed5d63d43af82395ce77d2151c4/1179fdcd-c5ae-43be-9d99-2b956169bd09'

#Maximum uptime for a server, if the uptime is more then that, an alert will be triggger.
$MaxUptime = 8

# **********************************************************************************

#Default action when an error occured
$ErrorActionPreference = "Stop"

#Log file
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"

#Find the task name running the script
$ScheduledTask = Get-ScheduledTask | Where {(($_.Actions).Arguments -match $ScriptName) -and ($_.State -eq "Running")}

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log {
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If($Error) {
        $Text = "ERROR | $Text"
    }
    ElseIf($Warning) {
        $Text = "WARNING | $Text"
    }
    Else {
        $Text = "INFO  | $Text"
    }
    If ($Debug) {
        If($Error) {
            Write-Host $Text -ForegroundColor Red
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }ElseIf($Warning) {
            Write-Host $Text -ForegroundColor Yellow
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }Else {
            Write-Host $Text -ForegroundColor Green
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }
    }
}

# **********************************************************************************

#SendEmail function
#HTML code can be configure for the right needed.
#Variables are define at the top of the script.
Function SendEmail() {
    $body =  "<head>"
    $body += " <title>Error : $($ScheduledTask.TaskName)</title>"
    $body += " <meta content=""text/html; charset=utf-8"" http-equiv=""Content-Type"" />"
    $body += " <style type=""text/css"">"
    $body += " <!--"
    $body += "   p {font-family: Arial; font-size:12px; color:#111; background-color:#FFF; margin:0px;padding:0px;}"
    $body += "  -->"
    $body += " </style>"
    $body += "</head>"
    $body += "<body style=""margin: 0; padding: 10px;"">"
    $body += " <table cellspacing=""10"" align=""left"" width=""800"" style=""font-size: 11px; margin: 0px; border: 1px solid; background-color: #fff; font-family: Arial; color: #111;"" >"
    $body += "  <tr height=""25"" align=""top"">"
    $body += "   <td style=""vertical-align: bottom;"">"
    $body += "    <p style=""font-family: Arial; font-size:16px; font-weight:bold; color:#00543D; background-color:#FFF; margin:0px;padding:0px; vertical-align:bottom;"">"
    $body += "     $($ScheduledTask.TaskName)<br>"
    $body += "     $($ScheduledTask.Description)<br>"
    $body += "     Error : $($ErrorMessage)"
    $body += "    </p>"
    $body += "   </td>"
    $body += "  </tr>"
    $body += "  <tr height=""2"" style=""vertical-align: top;"">"
    $body += "   <td style=""border: 1px solid;border-top-color: #00543D;border-left-color: #fff;border-right-color: #fff;border-bottom-color: #fff;""></td>"
    $body += "  </tr>"
    $body += "  <tr style=""vertical-align: top;"">"
    $body += "   <td valign=""top"" style=""vertical-align: top;"">"
    $body += "    <p style=""font-size:13px;margin: 10px 0px 0px; padding: 0px;"">"
    $body += "     Ce courriel s&rsquo;adresse aux membres de l&rsquo;&eacute;quipe $($TeamName).<br><br>"
    $body += "     Une erreur s&rsquo;est produite lors de l&rsquo;&eacute;xecution du script $($ScriptNameAndExtension).<br><br>"
    $body += "     &#8226; T&acirc;che ex&eacute;cut&eacute; sur : <b> $env:computername </b><br>"
    $body += "     &#8226; Dossier : $($ScheduledTask.TaskPath)"
    $body += "    </p>"
    $body += "   </td>"
    $body += "  </tr>"
    $body += "  <tr style=""vertical-align: top;""><td valign=""top"" style=""vertical-align: top;"">"
    $body += "   <p style=""font-size:13px;margin: 10px 0px 0px; padding: 0px;color:#00543D;"">"
    $body += "    *****"
    $body += "   </p>"
    $body += "  </td>"
    $body += " </tr>"
    $body += " <tr style=""vertical-align: top;"">"
    $body += "  <td valign=""top"" style=""vertical-align: top;"">"
    $body += "   <p style=""font-size:13px;margin: 10px 0px 0px; padding: 0px;"">"
    $body += "     This email is intended for members of the $($TeamName) team.<br><br>"
    $body += "     An error occurred while executing the script $($ScriptNameAndExtension).<br><br>"
    $body += "     &#8226; Task execute on: <b> $env:computername </b><br>"
    $body += "     &#8226; Folder: $($ScheduledTask.TaskPath)"
    $body += "   </p>"
    $body += "  </td>"
    $body += " </tr>"
    $body += " <tr height=""20"" style=""vertical-align: top;"">"
    $body += "  <td valign=""top"" style=""vertical-align: top;"">"
    $body += "   <p style=""font-family: Arial; font-size:16px; font-weight:bold; color:#00543D; margin:0px; padding:0px; vertical-align:middle;"">"
    $body += "    ERROR"
    $body += "   </p>"
    $body += "  </td>"
    $body += " </tr>"
    $body += "</table>"
    $body += "</body>"
    Send-MailMessage -To $smtpTo -Subject $($ScheduledTask.TaskName) -Body $body -SmtpServer $smtpServer -From $smtpFrom -BodyAsHtml -Port $smtpPort
}

# **********************************************************************************

#Create session in Citrix Cloud
Try {
    #Adding Citrix Snapin
    Log -Text "Add PowerShell Citrix.* Snapin"
    #Try to add Citrix Snapin
    Add-PSSnapin Citrix.*
    #Validate if Secure Client File exist
    If (Test-Path -Path "C:\TASK_SCRIPT\CTX_Cloud\Citrix\secureclient.csv") {
        Log -Text "Open session with Citrix Cloud"
        #Try to open a session with Citrix Cloud
        Set-XDCredentials -CustomerId $CustomerId -SecureClientFile "C:\TASK_SCRIPT\CTX_Cloud\Citrix\secureclient.csv" -ProfileType CloudAPI –StoreAs $ProfileName
        Get-XDAuthentication –ProfileName $ProfileName
    }
    Else {
        #Secure Client File does not exist, ending script...
        $ErrorMessage = "Unable to find Secure Client File"
        Log -Text $ErrorMessage -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        SendEmail
        Exit 1
    }
}
Catch {
    #An error occured when opening Citrix Snapin, ending script...
    $ErrorMessage = "An error occured during the Citrix Cloud opening"
    Log -Text $ErrorMessage -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error
    SendEmail
    Exit 1
}

$Result = @()
$ErrorLogs = ""

#List all servers in Citrix Cloud
Try {
    Log -Text "List all servers in Citrix Cloud"
    $Servers = Get-BrokerMachine | Where-Object {($_.RegistrationState -eq "Registered") -and ($_.PowerState -eq "On")}
}
Catch {
    #An error occured during getting the server list
    $ErrorMessage = "An error occured during getting the server list"
    Log -Text $ErrorMessage -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error
    SendEmail
    Exit 1
}

#Loop in each server to get the last system boot
ForEach ($Server in $Servers) {

    #Get the last system boot for server
    Try {
        Log -Text "Get last system boot for $($Server.MachineName)"
        $LastBoot = Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ScriptBlock {Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime -ExpandProperty lastbootuptime}
        $Uptime = NEW-TIMESPAN –Start $LastBoot –End (Get-Date)
    }
    Catch{
        $ErrorMessage = "An error occured during getting the server system boot"
        Log -Text $ErrorMessage -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
    }

    #If Uptime is higher then, we will log it
    If ($Uptime.Days -ge $MaxUptime){
        $Status = "" |  Select-Object MachineName,
                                      Uptime
        $Status.MachineName = $Server.MachineName
        $Status.Uptime = $Uptime.Days
        $Result += $Status
    }

}

#Webhooksend Microsoft Team Notification
#type - Must be set to `message`.
#attachments - This is the container for the adaptive card itself.
#contentType - Must be of the type `application/vnd.microsoft.card.adaptive`.
#content - The header and content of the adaptive card.
#$schema - Must have a value of [`http://adaptivecards.io/schemas/adaptive-card.json`](<http://adaptivecards.io/schemas/adaptive-card.json>) to import the proper schema for validation.
#type - Set to the type of `AdaptiveCard`.
#version - Currently set to version `1.0`.
#body - The content of the card itself to display.

$JSON = $Null
$JSON = [Ordered]@{
    "type"       = "message"
    "attachments" = @(
        @{
            "contentType" = 'application/vnd.microsoft.card.adaptive'
            "content"     = [Ordered]@{
                '$schema' = "<http://adaptivecards.io/schemas/adaptive-card.json>"
                "type"    = "AdaptiveCard"
                "version" = "1.0"
                "body"    = @(
                    [Ordered]@{
                        "type"  = "Container"
                        "items" = @(
                            @{
                                "type"   = "TextBlock"
                                "text"   = "$($ScheduledTask.TaskName)"
                                "wrap"   = $true 
                                "weight" = "Bolder"
                                "size"   = "Large"
                            }
                        )
                    }
                    [Ordered]@{
                        "type"  = "Container"
                        "style" = "emphasis"
                        "items" = @(
                            If ($ScheduledTask.Description) {
                                @{
                                    "type"   = "TextBlock"
                                    "text"   = "$($ScheduledTask.Description)"
                                    "wrap"   = $true 
                                }
                            }
                            @{
                                "type"   = "TextBlock"
                                "text"   = "Task run on $($env:COMPUTERNAME)"
                                "wrap"   = $true
                            }
                        )
                    }
                     #List result
                    If($Result) {
                        [Ordered]@{
                            "type"  = "Container"
                            "style" = "default"
                            "items" = @(
                                @{
                                    "type"   = "TextBlock"
                                    "text"   = "Servers with uptime higher then $($MaxUptime) days"
                                    "weight" = "Bolder"
                                    "wrap"   = $true
                                }
                            )
                        }
                        #We will use 2 column
                        [Ordered]@{
                            "type"    = "ColumnSet"
                            "columns" = @(
                                @{
                                    "type"  = "Column"
                                    "width" = "stretch"
                                    "items" = @(
                                        @{
                                            "type"  = "FactSet"
                                            "facts" = @(            
                                                For ($i=0;$i -lt $Result.Length;$i=$i+2) {
                                                    If ($Result[$i]) {
                                                        @{
                                                            "title" = "$(($Result[$i].MachineName).Split('\') | Select -Last 1)"
                                                            "value" = "$($Result[$i].Uptime) days"
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    "type"  = "Column"
                                    "width" = "stretch"
                                    "items" = @(
                                        @{
                                            "type"  = "FactSet"
                                            "facts" = @(            
                                                For ($i=1;$i -lt $Result.Length;$i=$i+2) {
                                                    If ($Result[$i]) {
                                                        @{
                                                            "title" = "$(($Result[$i].MachineName).Split('\') | Select -Last 1)"
                                                            "value" = "$($Result[$i].Uptime) days"
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    }
                    If ($ErrorLogs) {
                        [Ordered]@{
                            "type"  = "Container"
                            "style" = "default"
                            "items" = @(
                                @{
                                    "type"   = "TextBlock"
                                    "text"   = "$($ErrorLogs)"
                                    "wrap"   = $true
                                }
                            )
                        }
                    }

                )
            }
        }
    )
} | ConvertTo-JSON -Depth 20

Log -Text "Send Microsoft Team Notification"
Invoke-RestMethod -URI $URI -Method 'POST' -Body $JSON -ContentType 'application/json' 