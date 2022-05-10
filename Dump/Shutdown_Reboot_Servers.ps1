# **********************************************************************************
# Script to shutdown or reboot servers in Citrix Cloud.
#
# IMPORTANT : 
# This script have these requirements:
#  - Need Powershell SDK install on computer.
#  - Need Citrix Secure Client File.
#
# This script must be use in Windows Scheduled Task.
#
# The script use parameter to specified the action taken by the script:
#  DisableLogin
#    This action is to set Citrix server in maintenance mod to prevent new connection.
#  Notice
#    This action is to send a message to all Citrix session on server scheduled for
#    reboot or shutdown.
#  Shutdown
#    This action is to shutdown the Citrix server to save cost.
#  TurnOn
#    This action is to turn on Citrix server currently off.
#  Reboot
#    Citrix servers should be reboot once a week. This action is to reboot the servers.
#  EnableLogin
#    This action reboot the Citrix server in Windows and validate some informations
#    before turning off the maintenance mode.
#
# The script need the Citrix's Delivery Group passed in argument to know on which 
# servers it need to run. If you need to specify many Delivery Group, use a coma "," 
# between in each one.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate log file in the same folder as the script.
#
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2021-12-06  Benoit Blais        Original version
# 2021-12-21  Benoit Blais        Add reboot feature
# **********************************************************************************

Param(
    [ValidateSet("DisableLogin","Notice","Shutdown","Reboot","Rebootbox","TurnOn","EnableLogin")]
    [String]$Action,
    [String]$DeliveryGroups,
    [Switch]$Debug = $True
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

#Title of the message send to the user for shutdown
$ShutdownTitle = "Avis d'extinction - Shutdown warning"
#Message send to the user when session is disable
$ShutdownDisableMessage = "Le serveur Citrix va s'éteindre à $($(Get-Date).AddHours(5).ToString('HH'))h45 ce soir heure de l'Est. SVP, sauvegardez votre travail en cours, fermez toutes vos applications Citrix et reconnectez-vous sur le portail citrix.cascades.com, afin de continuer à travailler sans interruption. / The Citrix server will shutdown tonight at $($(Get-Date).AddHours(5).ToString('hh')):45pm Eastern Time. Please save all your current work, close all your Citrix applications and reconnect by visiting citrix.cascades.com portal to continue working without interruption."
#Message send to the user as reminder
$ShutdownNoticeMessage = "Le serveur Citrix va s'éteindre à $($(Get-Date).ToString('HH'))h45 ce soir heure de l'Est. SVP, sauvegardez votre travail en cours, fermez toutes vos applications Citrix et reconnectez-vous sur le portail citrix.cascades.com, afin de continuer à travailler sans interruption. / The Citrix server will shutdown tonight at $($(Get-Date).ToString('hh'))h45:45pm Eastern Time. Please save all your current work, close all your Citrix applications and reconnect by visiting citrix.cascades.com portal to continue working without interruption."
#Message send just before the action is taken
$ShutdownActionMessage = "Le serveur Citrix va s'éteindre dans 10 minutes / The Citrix server will shutdown in 10 minutes"

#Title of the message send to the user for reboot
$RebootTitle = "Avis de redémarrage - Reboot warning"
#Message send to the user when session is disable
$RebootDisableMessage = "Le serveur Citrix sur lequel vous êtes connecté sera redemarré demain 5h55 heure de l'Est. SVP n'oubliez pas de fermer vos sessions avant de quitter. / The Citrix server that you are connected will be rebooted tomorrow 5h55am Eastern Time. Please, don't forget to close sessions before leaving."
#Message send to the user as reminder
$RebootNoticeMessage = "Le serveur Citrix sur lequel vous êtes connecté sera redemarré à 5h55 heure de l'Est. SVP n'oubliez pas de fermer vos sessions avant de quitter. / The Citrix server that you are connected will be rebooted at 5h55am Eastern Time. Please, don't forget to close sessions before leaving"
#Message send just before the action is taken
$RebootActionMessage = "Le serveur Citrix va redemarrer dans 10 minutes. / The Citrix server will restart in 10 minutes."

#Tag on Citrix server for shutdown
$ShutdownTag = "Shutdown" 
#Tag on Citrix server for reboot
$RebootTag = "Reboot"

#Variables used to determine if the Citrix Profile Service is running or not and attemps to restart it
$CitrixProfileService = "ctxProfile"
$CitrixProfileServiceName = "Citrix Profile Management"

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
$ScheduledTask = Get-ScheduledTask | Where {(($_.Actions).Arguments -match $ScriptName) -and (($_.Actions).Arguments -match $Action) -and ($_.State -eq "Running")}

#Split $DeliveryGroups into array
$Groups = $DeliveryGroups.Split(",")

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
    If (Test-Path -Path "$($ScriptPath)\$($SecureClientFile)") {
        Log -Text "Open session with Citrix Cloud"
        #Try to open a session with Citrix Cloud
        Set-XDCredentials -CustomerId $CustomerId -SecureClientFile "$($ScriptPath)\$($SecureClientFile)" -ProfileType CloudAPI –StoreAs $ProfileName
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

Switch ($Action) {
    "DisableLogin"  {

        $Result = @()
        $ErrorLogs = ""

        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {
    
            Try {
                #List all servers on which the maintenance mode will be set and a notification will be send
                Log -Text "List all server to set in maintenance mode and send a notification for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match (Get-Date).DayOfWeek)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }
    
            #Looping all the servers to disable servers and send a notification
            ForEach ($Server in $Servers) {

                $Status = "" |  Select-Object MachineName,
                                              Status
                $Status.MachineName = $Server.MachineName 

                Try {
                    #Get all session on that Citrix server
                    Log -Text "Get all connected session on the server $($Server.MachineName)"
                    $Sessions = $null
                    $Sessions = Get-BrokerSession -AdminAddress $CitrixAdminAddress -MachineName $Server.MachineName
                }
                Catch {
                    #An error occured during getting the session on this Citrix server
                    $ErrorLogs += "An error occured during getting the session on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during getting the session on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                }

                #Validate if users are currently connected on the server. Without session, SendMessage will not work.
                If ($Sessions) {

                    #Validate if notification needs to be send for Shutdown or Reboot
                    If ($Server.Tags -match $ShutdownTag) {

                        Try {
                            #Send notificaiton message
                            Log -Text "Send message on the server $($Server.MachineName)"
                            Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $Sessions -MessageStyle Information -Title $ShutdownTitle -Text $ShutdownDisableMessage
                        }
                        Catch {
                            #An error occured during sending a notification message this Citrix server
                            $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                            Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                            Log -Text "Error:$($PSItem.Exception.Message)" -Error
                        }

                    }

                    ElseIf ($Server.Tags -match $RebootTag) {

                        Try {
                            #Send notificaiton message
                            Log -Text "Send message on the server $($Server.MachineName)"
                            Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $Sessions -MessageStyle Information -Title $RebootTitle -Text $RebootDisableMessage
                        }
                        Catch {
                            #An error occured during sending a notification message this Citrix server
                            $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                            Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                            Log -Text "Error:$($PSItem.Exception.Message)" -Error
                        }

                    }

                }

                Try {
                    #Set maintenante mode to ON
                    Log -Text "Set maintenance mode to On for server $($Server.MachineName)"
                    Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress -inputobject $Server.MachineName $true
                    If (Get-BrokerMachine -MachineName $Server.MachineName | Select InMaintenanceMode -ExpandProperty InMaintenanceMode) {
                        $Status.Status = "Success"
                    }
                    Else {
                        $Status.Status = "Error"
                    }
                }
                Catch {
                    #An error occured during turning maintenance mode to ON on this Citrix server
                    $ErrorLogs += "An error occured during turning maintenance mode to ON on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during turning maintenance mode to ON on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    $Status.Status = "Error"
                }

                $Result += $Status

            }

        }

    }
    "Notice"{

        $Result = @()
        $ErrorLogs = ""

        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {
 
            #Find all server to notice for shutdown
            Try {
                #List all server on which the notification will be send
                Log -Text "List all server to send a shutdown notification for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $ShutdownTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to send a notification
            ForEach ($Server in $Servers) {

                Try {
                    #Get all session on that Citrix server
                    Log -Text "Get all connected session on the Citrix server $($Server.MachineName)"
                    $Session = $null
                    $Sessions = Get-BrokerSession -AdminAddress $CitrixAdminAddress -MachineName $Server.MachineName
                }
                Catch {
                    #An error occured during getting the session on this Citrix server
                    $ErrorLogs += "An error occured during getting the session on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during getting the session on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                }

                $Status = "" |  Select-Object MachineName,
                                                Status
                $Status.MachineName = $Server.MachineName

                If ($Sessions) {

                    Try {
                            #Send notificaiton message
                            Log -Text "Send message on the Citrix server $($Server.MachineName)"
                            Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $sessions -MessageStyle Information -Title $ShutdownTitle -Text $ShutdownNoticeMessage
                            $Status.Status = "Success"
                        }
                    Catch {
                            #An error occured during sending a notification message this Citrix server
                            $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                            Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                            Log -Text "Error:$($PSItem.Exception.Message)" -Error
                            $Status.Status = "Error"
                        }

                }
                Else {

                    Log -Text "No session on the server $($Server.MachineName)"
                    $Status.Status = "No Session"
                    
                }

                $Result += $Status

            }

            #Find all server to notice for Reboot
            Try {
                #List all server on which the notification will be send
                Log -Text "List all server to send a reboot notification for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match ((Get-Date).AddDays(-1)).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to send a notification
            ForEach ($Server in $Servers) {

                Try {
                    #Get all session on that Citrix server
                    Log -Text "Get all connected session on the Citrix server $($Server.MachineName)"
                    $Session = $null
                    $Sessions = Get-BrokerSession -AdminAddress $CitrixAdminAddress -MachineName $Server.MachineName
                }
                Catch {
                    #An error occured during getting the session on this Citrix server
                    $ErrorLogs += "An error occured during getting the session on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during getting the session on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                }

                $Status = "" |  Select-Object MachineName,
                                                Status
                $Status.MachineName = $Server.MachineName

                If ($Sessions) {

                    Try {
                            #Send notificaiton message
                            Log -Text "Send message on the Citrix server $($Server.MachineName)"
                            Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $sessions -MessageStyle Information -Title $RebootTitle -Text $RebootNoticeMessage
                            $Status.Status = "Success"
                        }
                    Catch {
                            #An error occured during sending a notification message this Citrix server
                            $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                            Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                            Log -Text "Error:$($PSItem.Exception.Message)" -Error
                            $Status.Status = "Error"
                        }

                }
                Else {

                    Log -Text "No session on the server $($Server.MachineName)"
                    $Status.Status = "No Session"
                    
                }

                $Result += $Status

            }

        }

    }
    "Shutdown"{

        $Result = @()
        $ErrorLogs = ""
    
        #Loop for each Delivery Group passed in argument to send a final notice
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server to send a final notice
                Log -Text "List all server to send a final notification before shutdown for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $ShutdownTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to send a final notice
            ForEach ($Server in $Servers) {

                Try {
                    #Get all session on that Citrix server
                    Log -Text "Get all connected session on the server $($Server.MachineName)"
                    $Session = $null
                    $Sessions = Get-BrokerSession -AdminAddress $CitrixAdminAddress -MachineName $Server.MachineName
                }
                Catch {
                    #An error occured during getting the session on this Citrix server
                    $ErrorLogs += "An error occured during getting the session on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during getting the session on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                }

                If ($Sessions) {

                    Try {
                        #Send notificaiton message
                        Log -Text "Send message on the Citrix server $($Server.MachineName)"
                        Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $sessions -MessageStyle Information -Title $ShutdownTitle -Text $ShutdownActionMessage
                    }
                    Catch {
                        #An error occured during sending a notification message this Citrix server
                        $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                        Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                        Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    }

                }

                If (!((Get-BrokerMachine -MachineName $Server.MachineName).InMaintenanceMode)) {
                    Try {
                        #Maintenance is not set to on. We will turn on maintenance.
                        Log -Text "Set maintenance mode to On for server $($Server.MachineName)"
                        Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress -inputobject $Server.MachineName $true
                    }
                    Catch {
                        #An error occured during turning maintenance mode to ON on this Citrix server
                        $ErrorLogs += "An error occured during turning maintenance mode to ON on Citrix server $($Server.MachineName)"
                        Log -Text "An error occured during turning maintenance mode to ON on Citrix server $($Server.MachineName)" -Error
                        Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    }
                }

            }

        }

        #Wait 10 minutes
        Log -Text "Sleep 10 minutes"
        Start-Sleep -s 600  
        
        #Loop for each Delivery Group passed in argument to shudown server
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server to be shutdown
                Log -Text "List all server to be shutdown for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $ShutdownTag) -and ($_.PowerState -eq "On")}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to shutdown
            ForEach ($Server in $Servers) {

                Try {

                    #Shutdown Citrix Server
                    Log -Text "Shutting down Citrix server $($Server.MachineName)"
                    New-BrokerHostingPowerAction -AdminAddress $CitrixAdminAddress -Action ShutDown $Server.MachineName
                    
                    $Count = 0
                    #Loop until the status change in Citrix Cloud
                    While (((Get-BrokerMachine | Where-Object {$_.MachineName -eq $Server.MachineName} | Select PowerState -ExpandProperty PowerState) -eq "On") -and ($Count -lt 6)) {
                        Start-Sleep -s 5
                        $Count++
                    }
                    
                    $Status = "" |  Select-Object MachineName,
                                                  Status
                    $Status.MachineName = $Server.MachineName
                    
                    If ((Get-BrokerMachine | Where-Object {$_.MachineName -eq $Server.MachineName} | Select PowerState -ExpandProperty PowerState) -eq "On") {
                    
                        $Status.Status = "Error"
                    
                    }
                    Else {
                    
                        $Status.Status = "Success"
                    
                    }
                    
                    $Result += $Status

                    If ($Server.MachineName -match "-dv-") {

                        Add-Content -Path "$($ScriptPath)\Shutdown_Dev_Servers.txt" "$(Get-Date) | $($Server.MachineName)"

                    }

                }
                Catch {

                    #An error occured during shutting down this Citrix server
                    $ErrorLogs += "An error occured during shutting down Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during shutting down Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error

                }

            }

        }

    }
    "Reboot"{

        $Result = @()
        $ErrorLogs = ""
    
        #Loop for each Delivery Group passed in argument to send a final notice
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server to send a final notice
                Log -Text "List all server to send a final notification before rerboot for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode) -and ($_.Tags -match ((Get-Date).AddDays(-1)).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to send a final notice
            ForEach ($Server in $Servers) {

                Try {
                    #Get all session on that Citrix server
                    Log -Text "Get all connected session on the server $($Server.MachineName)"
                    $Session = $null
                    $Sessions = Get-BrokerSession -AdminAddress $CitrixAdminAddress -MachineName $Server.MachineName
                }
                Catch {
                    #An error occured during getting the session on this Citrix server
                    $ErrorLogs += "An error occured during getting the session on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during getting the session on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                }

                If ($Sessions) {

                    Try {
                        #Send notificaiton message
                        Log -Text "Send message on the Citrix server $($Server.MachineName)"
                        Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $sessions -MessageStyle Information -Title $RebootTitle -Text $RebootActionMessage
                    }
                    Catch {
                        #An error occured during sending a notification message this Citrix server
                        $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                        Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                        Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    }

                }

            }

        }

        #Wait 10 minutes
        Log -Text "Sleep 10 minutes"
        Start-Sleep -s 600  
        
        #Loop for each Delivery Group passed in argument to shudown server
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server to be shutdown
                Log -Text "List all server to be reboot for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode) -and ($_.Tags -match ((Get-Date).AddDays(-1)).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to reboot
            ForEach ($Server in $Servers) {

                Try {

                    #Reboot Citrix Server
                    Log -Text "Rebooting Citrix server $($Server.MachineName)"
                    New-BrokerHostingPowerAction -AdminAddress $CitrixAdminAddress -Action Restart $Server.MachineName
                    
                    #Validate if server is not at off in Citrix Cloud console
                    $Count = 0
                    While (((Get-BrokerMachine | Where-Object {$_.MachineName -eq $Server.MachineName} | Select PowerState -ExpandProperty PowerState) -eq "On") -and ($Count -lt 20)) {
                    
                        $Count++
                        Start-Sleep 2
                    
                    }
                    
                    $Status = "" |  Select-Object MachineName,
                                                  Status
                    $Status.MachineName = $Server.MachineName

                    If ($Count -eq 20) {
                    
                        $Status.Status = "Error"
                    
                    }
                    Else {
                    
                        $Status.Status = "Success"
                    
                    }
                    
                    $Result += $Status 

                }
                Catch {

                    #An error occured during shutting down this Citrix server
                    $ErrorLogs += "An error occured during shutting down Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during shutting down Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error

                }
            }

        }

    }
    "RebootBox"{

        $Result = @()
        $ErrorLogs = ""

        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {
    
            Try {
                #List all servers on which notification will be send
                Log -Text "List all server to set send a notification for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }
    
            #Looping all the servers to send a notification
            ForEach ($Server in $Servers) {

                Try {
                    #Get all session on that Citrix server
                    Log -Text "Get all connected session on the server $($Server.MachineName)"
                    $Sessions = $null
                    $Sessions = Get-BrokerSession -AdminAddress $CitrixAdminAddress -MachineName $Server.MachineName
                }
                Catch {
                    #An error occured during getting the session on this Citrix server
                    $ErrorLogs += "An error occured during getting the session on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during getting the session on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                }

                #Validate if users are currently connected on the server. Without session, SendMessage will not work.
                If ($Sessions) {

                    Try {
                        #Send notificaiton message
                        Log -Text "Send message on the server $($Server.MachineName)"
                        Send-BrokerSessionMessage -AdminAddress $CitrixAdminAddress $Sessions -MessageStyle Information -Title $RebootTitle -Text $RebootActionMessage
                    }
                    Catch {
                        #An error occured during sending a notification message this Citrix server
                        $ErrorLogs += "An error occured during sending a notification message on Citrix server $($Server.MachineName)"
                        Log -Text "An error occured during sending a notification message on Citrix server $($Server.MachineName)" -Error
                        Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    }

                }

            }

        }

        #Wait 10 minutes
        Log -Text "Sleep 10 minutes"
        Start-Sleep -s 600  

        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all servers to set in maintenance mode and reboot
                Log -Text "List all server to set in maintenance mode for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to restart
            ForEach ($Server in $Servers) {

                Try {
                    #Set maintenante mode to ON
                    Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress -inputobject $Server.MachineName $true
                    #Reboot Citrix Server
                    Log -Text "Rebooting Citrix server $($Server.MachineName)"
                    New-BrokerHostingPowerAction -AdminAddress $CitrixAdminAddress -Action Restart $Server.MachineName
                }
                Catch {
                    #An error occured during turning maintenance mode to ON on this Citrix server
                    $ErrorLogs += "An error occured during turning maintenance mode to ON on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during turning maintenance mode to ON on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error

                }
            }
        }

        #Wait 10 minutes
        Log -Text "Sleep 10 minutes"
        Start-Sleep -s 600  

        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server on which the maintenance mode needs to be turn off
                Log -Text "List all server on which the maintenance mode needs to be turn off for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }
            
            #Looping all the servers to reboot in Windows
            ForEach ($Server in $Servers) {
                
                #Validate if server is on and registered in Citrix Cloud console
                $Count = 0
                While ((!($Server.PowerState -eq "On")) -and (!($Server.RegistrationState -eq "Registered")) -and ($Count -lt 12)) {
                    
                    $Count++
                    Start-Sleep 10
                    
                }                
                
                If (($Server.PowerState -eq "On") -and ($Server.RegistrationState -eq "Registered")) {


                    Try {
                        #Reboot the Citrix server in Windows
                        Log -Text "Reboot Citrix server $($Server.MachineName)"
                        Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ScriptBlock {Restart-Computer -Force}
                    }
                    Catch {
                        #An error occured during rebooting this Citrix server
                        $ErrorLogs += "An error occured during rebooting Citrix server $($Server.MachineName)"
                        Log -Text "An error occured during rebooting Citrix server $($Server.MachineName)" -Error
                        Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    }

                }
                Else {
                
                    $ErrorLogs += "Citrix server $($Server.MachineName) is not On or not Registered"
                    Log -Text "Citrix server $($Server.MachineName) is not On or not Registered" -Error
                
                }

            }

        }

        #Wait 2 minutes
        Log -Text "Sleep 2 minutes"
        Start-Sleep -s 120   
         
        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server on which the maintenance mode needs to be turn off
                Log -Text "List all server on which the maintenance mode needs to be turn off for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode) -and ($_.Tags -match (Get-Date).DayOfWeek) -and ($_.Tags -match $RebootTag)}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to Exit maintenance mode
            ForEach ($Server in $Servers) {  

                $Status = "" |  Select-Object MachineName,
                                              Status
                $Status.MachineName = $Server.MachineName

                #Validate if server is on and registered in Citrix Cloud console
                $Count = 0
                While ((!($Server.PowerState -eq "On")) -and (!($Server.RegistrationState -eq "Registered")) -and ($Count -lt 12)) {
                    
                    $Count++
                    Start-Sleep 10
                    
                }                
                
                If (($Server.PowerState -eq "On") -and ($Server.RegistrationState -eq "Registered")) {
               
                    #Validate if SAP is install on the server.
                    If (Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -scriptblock {Test-Path 'HKLM:\SOFTWARE\SAP'}) {

                        #Validate if SAP SSO key is present on the server
                        If (!(Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -scriptblock {Test-Path 'HKLM:\SOFTWARE\Policies\SAP'})) {
                    
                            $ErrorLogs += "SSO Registry key not exist on Citrix server $($Server.MachineName)"
                            Log -Text "SSO Registry key not exist on Citrix server $($Server.MachineName)" -Error
                            $Status.Status = "Error"
                            $Result += $Status
                            Continue

                        }

                    }
                
                    #Get service status from citrix server
                    Try {
                        Log -Text "Get service status on Citrix server $($Server.MachineName)"
                        $Service = $Null
                        $Service = Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ArgumentList $CitrixProfileService -ScriptBlock {Get-Service -Name $args[0]}
                        Log -Text "$($Service.Status)"
                    }
                    Catch {
                        $ErrorLogs += "An error occured when getting service status for Citrix server $($Server.MachineName)"
                        Log -Text "An error occured when getting service status for Citrix server $($Server.MachineName)"
                        $Status.Status = "Error"
                        $Result += $Status
                        Continue
                    }


                    #If the server maintenance is TRUE - AND - the status of the Citrix Profile service is RUNNING - AND - the REGKEY for SAP SSO EXISTS on server -> set the maintenance to FALSE, skip for next server
                    If ($Service.Status -eq 'Running') {

                        Try {
                            #Turn off maintenance mode
                            Log -Text "Set maintenance mode to off for Citrix server $($Server.MachineName)"
                            Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress $Server.MachineName $false
                        
                            If (Get-BrokerMachine -MachineName $Server.MachineName | Select InMaintenanceMode -ExpandProperty InMaintenanceMode) {
                                $Status.Status = "Error"
                            }
                            Else {
                                $Status.Status = "Success"
                            }
                            $Result += $Status
                            Continue
                        }
                        Catch {
                            #An error occured during turning off maintenance mode for this server
                            $ErrorLogs += "An error occured during turning maintenance mode to off for Citrix server $($Server.MachineName)"
                            Log -Text "An error occured during turning maintenance mode to off for Citrix server $($Server.MachineName)" -Error
                            $Status.Status = "Error"
                            $Result += $Status
                        }

                    }
                    Else {

                        $Count = 0
                        #Try to restart Citrix Profile Management service 3 times
                        While (($Service.Status -ne 'Running') -and ($Count -lt 3)) {

                            $Count++
                            Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ArgumentList $CitrixProfileServiceName -ScriptBlock {Restart-Service $args[0]}
                            Start-Sleep -seconds 10
                            $Service = Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ArgumentList $CitrixProfileService -ScriptBlock {Get-Service -Name $args[0] }
                        
                            #If the server maintenance is TRUE - AND - the status of the Citrix Profile service is RUNNING - AND - the REGKEY for SAP SSO EXISTS on server -> set the maintenance to FALSE, skip for next server
                            If ($Service.Status -eq 'Running'){

                                #Turn off maintenance mode
                                Log -Text "Set maintenance mode to off for Citrix server $($Server.MachineName)"
                                Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress $Server.MachineName $false
                                If (Get-BrokerMachine -MachineName $Server.MachineName | Select InMaintenanceMode -ExpandProperty InMaintenanceMode) {
                                    $Status.Status = "Error"
                                }
                                Else {
                                    $Status.Status = "Success"
                                }
                                $Result += $Status
                                break
                        
                            }

                        }

                    }

                }
                Else {
                
                    $ErrorLogs += "Citrix server $($Server.MachineName) is not On or not Registered"
                    Log -Text "Citrix server $($Server.MachineName) is not On or not Registered" -Error
                
                }

            }

        }

    }
    "TurnOn"{

        $Result = @()
        $ErrorLogs = ""

        #Loop for each Delivery Group passed in argument to TurnOn server
        ForEach ($DeliveryGroup in $Groups) {

            Try {
                #List all server to be turn on
                Log -Text "List all server to be turn on for Delivery Group $($DeliveryGroup)"
                $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.Tags -match $ShutdownTag) -and ($_.PowerState -match "Off")}
            }
            Catch {
                #An error occured during getting the server list
                $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                Log -Text $ErrorMessage -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                SendEmail
                Exit 1
            }

            #Looping all the servers to Turn On
            ForEach ($Server in $Servers) {

                Try {
                    #TurnOn Citrix Server
                    Log -Text "TurnOn server $($Server.MachineName)"
                    New-BrokerHostingPowerAction -AdminAddress $CitrixAdminAddress -Action TurnOn $Server.MachineName

                }
                Catch {

                    #An error occured during turning on this Citrix server
                    $ErrorLogs += "An error occured during turning on Citrix server $($Server.MachineName)"
                    Log -Text "An error occured during turning on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                
                }

            }

            #Looping all the servers to validate if server is booting
            ForEach ($Server in $Servers) {

                Try {

                    $Status = "" |  Select-Object MachineName,
                                                  Status
                    $Status.MachineName = $Server.MachineName
                    
                    #Validate if server is not at off in Citrix Cloud console
                    $Count = 0
                    While (((Get-BrokerMachine | Where-Object {$_.MachineName -eq $Server.MachineName} | Select PowerState -ExpandProperty PowerState) -eq "Off") -and ($Count -lt 20)) {
                    
                        $Count++
                        Start-Sleep 2
                    
                    }  

                    If ((Get-BrokerMachine | Where-Object {$_.MachineName -eq $Server.MachineName} | Select PowerState -ExpandProperty PowerState) -eq "Off") {
                    
                        $Status.Status = "Error"
                    
                    }
                    Else {
                    
                        $Status.Status = "Success"
                    
                    }
                    
                    $Result += $Status
                
                }
                Catch {

                    #An error occured during turning on this Citrix server
                    $ErrorLogs += "An error occured during validating Citrix server $($Server.MachineName) status"
                    Log -Text "An error occured during turning on Citrix server $($Server.MachineName)" -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                
                }

            }

        }

    }
    "EnableLogin" {
        
        $Result = @()
        $ErrorLogs = ""

        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {

            #No shutdown server are powerOn during the weekend. 
            If (((Get-Date).DayOfWeek -match "Sunday") -or ((Get-Date).DayOfWeek -match "Saturday")){

                Try {
                    #List all server on which the maintenance mode needs to be turn off
                    Log -Text "List all server on which the maintenance mode needs to be turn off for Delivery Group $($DeliveryGroup)"
                    $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode) -and ($_.Tags -match $RebootTag)}
                }
                Catch {
                    #An error occured during getting the server list
                    $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                    Log -Text $ErrorMessage -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    SendEmail
                    Exit 1
                }

            }
            Else {

                Try {
                    #List all server on which the maintenance mode needs to be turn off
                    Log -Text "List all server on which the maintenance mode needs to be turn off for Delivery Group $($DeliveryGroup)"
                    $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode)}
                }
                Catch {
                    #An error occured during getting the server list
                    $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                    Log -Text $ErrorMessage -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    SendEmail
                    Exit 1
                }

            }

            #Looping all the servers to reboot in Windows
            ForEach ($Server in $Servers) {
                
                #Validate if server is on and registered in Citrix Cloud console
                $Count = 0
                While ((!($Server.PowerState -eq "On")) -and (!($Server.RegistrationState -eq "Registered")) -and ($Count -lt 60)) {
                    
                    $Count++
                    Start-Sleep 2
                    
                }                
                
                If (($Server.PowerState -eq "On") -and ($Server.RegistrationState -eq "Registered")) {


                    Try {
                        #Reboot the Citrix server in Windows
                        Log -Text "Reboot Citrix server $($Server.MachineName)"
                        Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ScriptBlock {Restart-Computer -Force}
                    }
                    Catch {
                        #An error occured during rebooting this Citrix server
                        $ErrorLogs += "An error occured during rebooting Citrix server $($Server.MachineName)"
                        Log -Text "An error occured during rebooting Citrix server $($Server.MachineName)" -Error
                        Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    }

                }
                Else {
                
                    $ErrorLogs += "Citrix server $($Server.MachineName) is not On or not Registered"
                    Log -Text "Citrix server $($Server.MachineName) is not On or not Registered" -Error
                
                }

            }

        }

        #Wait 2 minutes
        Log -Text "Sleep 2 minutes"
        Start-Sleep -s 120   
         
        #Loop for each Delivery Group passed in argument
        ForEach ($DeliveryGroup in $Groups) {

            #No shutdown server are powerOn during the weekend. 
            If (((Get-Date).DayOfWeek -match "Sunday") -or ((Get-Date).DayOfWeek -match "Saturday")){

                Try {
                    #List all server on which the maintenance mode needs to be turn off
                    Log -Text "List all server on which the maintenance mode needs to be turn off for Delivery Group $($DeliveryGroup)"
                    $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode) -and ($_.Tags -match $RebootTag)}
                }
                Catch {
                    #An error occured during getting the server list
                    $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                    Log -Text $ErrorMessage -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    SendEmail
                    Exit 1
                }

            }
            Else {

                Try {
                    #List all server on which the maintenance mode needs to be turn off
                    Log -Text "List all server on which the maintenance mode needs to be turn off for Delivery Group $($DeliveryGroup)"
                    $Servers = Get-BrokerMachine | Where-Object {($_.DesktopGroupName -eq $DeliveryGroup) -and ($_.InMaintenanceMode)}
                }
                Catch {
                    #An error occured during getting the server list
                    $ErrorMessage = "An error occured during getting the server list for Delivery Group $($DeliveryGroup)"
                    Log -Text $ErrorMessage -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    SendEmail
                    Exit 1
                }

            }

            #Looping all the servers to Exit maintenance mode
            ForEach ($Server in $Servers) {  

                $Status = "" |  Select-Object MachineName,
                                              Status
                $Status.MachineName = $Server.MachineName

                #Validate if server is on and registered in Citrix Cloud console
                $Count = 0
                While ((!($Server.PowerState -eq "On")) -and (!($Server.RegistrationState -eq "Registered")) -and ($Count -lt 12)) {
                    
                    $Count++
                    Start-Sleep 10
                    
                }                
                
                If (($Server.PowerState -eq "On") -and ($Server.RegistrationState -eq "Registered")) {
               
                    #Validate if SAP is install on the server.
                    If (Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -scriptblock {Test-Path 'HKLM:\SOFTWARE\SAP'}) {

                        #Validate if SAP SSO key is present on the server
                        If (!(Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -scriptblock {Test-Path 'HKLM:\SOFTWARE\Policies\SAP'})) {
                    
                            $ErrorLogs += "SSO Registry key not exist on Citrix server $($Server.MachineName)"
                            Log -Text "SSO Registry key not exist on Citrix server $($Server.MachineName)" -Error
                            $Status.Status = "Error"
                            $Result += $Status
                            Continue

                        }

                    }
                
                    #Get service status from citrix server
                    Try {
                        Log -Text "Get service status on Citrix server $($Server.MachineName)"
                        $Service = $Null
                        $Service = Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ArgumentList $CitrixProfileService -ScriptBlock {Get-Service -Name $args[0]}
                    }
                    Catch {
                        $ErrorLogs += "An error occured when getting service status for Citrix server $($Server.MachineName)"
                        Log -Text "An error occured when getting service status for Citrix server $($Server.MachineName)"
                        $Status.Status = "Error"
                        $Result += $Status
                        Continue
                    }


                    #If the status of the Citrix Profile service is RUNNING, set the maintenance to FALSE, skip for next server
                    If ($Service.Status -eq 'Running') {

                        Try {
                            #Turn off maintenance mode
                            Log -Text "Set maintenance mode to off for Citrix server $($Server.MachineName)"
                            Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress $Server.MachineName $false
                        
                            If (Get-BrokerMachine -MachineName $Server.MachineName | Select InMaintenanceMode -ExpandProperty InMaintenanceMode) {
                                $Status.Status = "Error"
                            }
                            Else {
                                $Status.Status = "Success"
                            }
                            $Result += $Status
                            Continue
                        }
                        Catch {
                            #An error occured during turning off maintenance mode for this server
                            $ErrorLogs += "An error occured during turning maintenance mode to off for Citrix server $($Server.MachineName)"
                            Log -Text "An error occured during turning maintenance mode to off for Citrix server $($Server.MachineName)" -Error
                            $Status.Status = "Error"
                            $Result += $Status
                        }

                    }
                    Else {

                        $Count = 0
                        #Try to restart Citrix Profile Management service 3 times
                        While (($Service.Status -ne 'Running') -and ($Count -lt 3)) {

                            $Count++
                            Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ArgumentList $CitrixProfileServiceName -ScriptBlock {Restart-Service $args[0]}
                            Start-Sleep -seconds 10
                            $Service = Invoke-Command -ComputerName (($Server.MachineName).Split("\") | Select -last 1) -ArgumentList $CitrixProfileService -ScriptBlock {Get-Service -Name $args[0] }
                        
                            #If the server maintenance is TRUE - AND - the status of the Citrix Profile service is RUNNING - AND - the REGKEY for SAP SSO EXISTS on server -> set the maintenance to FALSE, skip for next server
                            If ($Service.Status -eq 'Running'){

                                #Turn off maintenance mode
                                Log -Text "Set maintenance mode to off for Citrix server $($Server.MachineName)"
                                Set-BrokerMachineMaintenanceMode -AdminAddress $CitrixAdminAddress $Server.MachineName $false
                                If (Get-BrokerMachine -MachineName $Server.MachineName | Select InMaintenanceMode -ExpandProperty InMaintenanceMode) {
                                    $Status.Status = "Error"
                                }
                                Else {
                                    $Status.Status = "Success"
                                }
                                $Result += $Status
                                break
                        
                            }

                        }

                    }

                }
                Else {
                
                    $ErrorLogs += "Citrix server $($Server.MachineName) is not On or not Registered"
                    Log -Text "Citrix server $($Server.MachineName) is not On or not Registered" -Error
                
                }

            }

        }

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
                                    "text"   = "Result of the scheduled task"
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
                                                            "value" = "$($Result[$i].Status)"
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
                                                            "value" = "$($Result[$i].Status)"
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