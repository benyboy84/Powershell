# **********************************************************************************
# Script to validate TAGS on Citrix servers in Citrix Cloud (AWS).
# IMPORTANT : 
# Need Powershell SDK install on computer.
# Need Citrix Secure Client File.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2021-12-06  Benoit Blais        Original version
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

# *******************************************************************************

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

# *******************************************************************************

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

# *******************************************************************************

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

# *******************************************************************************
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

# *******************************************************************************

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

#Validate Citrix's server tags
Try {
    #List all server in Citrix
    Log -Text "Get all server in Citrix"
    $AllCitrixServers = Get-BrokerMachine
    #Find all Citrix server with tag
    Log -Text "List all tag server"
    $TagServers = $AllCitrixServers | Where-Object {$_.Tags -ne $null} 
    $TagServersName = $AllCitrixServers | Where-Object {$_.Tags -ne $null} | Select MachineName -ExpandProperty MachineName
    #Find all Citrix server without tag
    Log -Text "List all server without tag"
    $UnTagServersName = $AllCitrixServers | Where-Object {$TagServersName -notcontains $_.MachineName} | Select MachineName -ExpandProperty MachineName
    #Find all Citrix server without a valid tag (reboot or shutdowm)
    Log -Text "List all server without a valid tag"
    $NoValidTagServersName = $TagServers | Where-Object {((@($_.Tags) -like 'Shutdown').count -eq 0) -and ((@($_.Tags) -like 'Reboot').count -eq 0) -and ((@($_.Tags) -like 'Sunday').count -eq 0) -and ((@($_.Tags) -like 'Monday').count -eq 0) -and ((@($_.Tags) -like 'Tuesday').count -eq 0) -and ((@($_.Tags) -like 'Wednesday').count -eq 0) -and ((@($_.Tags) -like 'Thursday').count -eq 0) -and ((@($_.Tags) -like 'Friday').count -eq 0) -and ((@($_.Tags) -like 'Saturday').count -eq 0) } | Select MachineName -ExpandProperty MachineName
}
Catch {
    $ErrorMessage = "An error occured during server list generation"
    Log -Text $ErrorMessage -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error
    SendEmail
    Exit 1
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
                    #List server without tag
                    If($UnTagServersName) {
                        [Ordered]@{
                            "type"  = "Container"
                            "style" = "default"
                            "items" = @(
                                @{
                                    "type"   = "TextBlock"
                                    "text"   = "Server without a tag in Citrix Cloud"
                                    "weight" = "Bolder"
                                    "wrap"   = $true
                                }
                            )
                        }
                        #We will use 3 column
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
                                                For ($i=0;$i -lt $UnTagServersName.Length;$i=$i+3) {
                                                    If ($UnTagServersName[$i]) {
                                                        @{
                                                            "value" = "$(($UnTagServersName[$i]).Split('\') | Select -Last 1)"
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
                                                For ($i=1;$i -lt $UnTagServersName.Length;$i=$i+3) {
                                                    If ($UnTagServersName[$i]) {
                                                        @{
                                                            "value" = "$(($UnTagServersName[$i]).Split('\') | Select -Last 1)"
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
                                                For ($i=2;$i -lt $UnTagServersName.Length;$i=$i+3) {
                                                    If ($UnTagServersName[$i]) {
                                                        @{
                                                            "value" = "$(($UnTagServersName[$i]).Split('\') | Select -Last 1)"
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
                    #List server without a valid tag
                    If($NoValidTagServersName) {
                        [Ordered]@{
                            "type"  = "Container"
                            "style" = "default"
                            "items" = @(
                                @{
                                    "type"   = "TextBlock"
                                    "text"   = "Server without a valid tag in Citrix Cloud"
                                    "weight" = "Bolder"
                                    "wrap"   = $true
                                }
                            )
                        }
                        #We will use 3 column
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
                                                For ($i=0;$i -lt $NoValidTagServersName.Length;$i=$i+3) {
                                                    If ($NoValidTagServersName[$i]) {
                                                        @{
                                                            "value" = "$(($NoValidTagServersName[$i]).Split('\') | Select -Last 1)"
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
                                                For ($i=1;$i -lt $NoValidTagServersName.Length;$i=$i+3) {
                                                    If ($NoValidTagServersName[$i]) {
                                                        @{
                                                          "value" = "$(($NoValidTagServersName[$i]).Split('\') | Select -Last 1)"
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
                                                For ($i=2;$i -lt $NoValidTagServersName.Length;$i=$i+3) {
                                                    If ($NoValidTagServersName[$i]) {
                                                        @{
                                                          "value" = "$(($NoValidTagServersName[$i]).Split('\') | Select -Last 1)"
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
                )
            }
        }
    )
} | ConvertTo-JSON -Depth 20

Log -Text "Send Microsoft Team Notification"
Invoke-RestMethod -URI $URI -Method 'POST' -Body $JSON -ContentType 'application/json' | Out-Null
