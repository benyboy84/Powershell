# *******************************************************************************
# Script to import a cooke in Internet Explorer for WebClock Application.
#
# The WebClock application is a SaaS application and uses the geolocation of the 
# public IP address to select the appropriate time zone. However, since the users 
# are connected to a Citrix server, all of them have the same time zone. 
# 
# It is for this reason that a cookie must be used in order to solve this issue.
# The cookie contain the time zone to use in WebClock application.
#
# The script use the time zone in the Citrix session to import the appropriate 
# cookie in Internet Explorer.
# 
# If no cookie is import, the script generate an error and close. In that case, 
# the WebClock application will use the Citrix server time zone.
#
# This is the requirement of this script 
#
# 1. A network folder with the cookie 
#    To generate the cookie, you need to receive a valid URL from the WebClock
#    manager. This will create the cookie in your Internet Explorer. Then, you
#    have to export the cookie from Internet Explorer and save it into the 
#    network folder.
#    The file name need to be the time zone with underscore instead of space.
#    ex.: Central_Standard_Time.txt
# 
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2020-04-27  Benoit Blais        Creation
# *******************************************************************************

Param(
    [Switch]$Debug = $False
)

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$CookiesFolderServer = "\\ad.cascades.com\APPS\CTX-Apps\WebClock"
$LogFile = "$($env:APPDATA)\WebClock.txt"

# *******************************************************************************

#Default action when an error occured.
$ErrorActionPreference = "Stop"

#Get user's timezone. This will be use to copy the appropriate cookie file.
$Timezone = $($(Get-TimeZone).id)

#Replace whitespace in timezone by underscore and add the test file extension to it.
$CookieFile = "$($Timezone.Replace(' ','_')).txt"

#Generating the cookie's file path based on the cookie file name generated before.
$CookiePath = "$($CookiesFolderServer)\$($CookieFile)"

#File name for the export of Internet Explorer cookies.
$CookiesExportFileName = "CookiesExport.txt" 

# Get script name.
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1

# *******************************************************************************

#If debug is not $TRUE, we will hide the current PowerShell processus window.
If($Debug -eq $False){
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    Try{
        Add-Type -name win -member $t -namespace native
        [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
    }Catch{$Null}
}

# *******************************************************************************

#Log function will allow to write information to text file and if debug mode is $TRUE, 
#we will also display colored information in the PowerShell window.
#Parameters:
#$Text : Text added to the text file.
#$Error and $Warning: These switch need to be use to specify something else then an information.
Function Log{
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If($Error){
        $Text = "ERROR | $Text"
    }
    ElseIf($Warning){
        $Text = "WARNING | $Text"
    }
    Else{
        $Text = "INFO | $Text"
    }
    Try{
        Add-Content $LogFile "$(Get-Date) | $text"
    }Catch{$Null}
    If($Debug){
        If($Error){
            Write-Host $Text -ForegroundColor Red
        }ElseIf($Warning){
            Write-Host $Text -ForegroundColor Yellow
        }Else{
            Write-Host $Text -ForegroundColor Green
        }
    }
}

# *******************************************************************************

#Add general information to logfile.
Log -Text "*********************"
Log -Text "Script name: $($ScriptNameAndExtension)"
Log -Text "Date: $((Get-Date).ToString("MM/dd/yyyy HH:mm:ss tt"))"
Log -Text "Hostname: $($env:COMPUTERNAME)"
Log -Text "Username: $($env:USERNAME)"
Log -Text "Timezone: $($Timezone)"

#Copy cookie file locally to be able to import it into Internet Explorer.
Log -Text "Copy $($CookiePath) to $($env:APPDATA)"
Try {
    Copy-Item -Path $CookiePath -Destination $env:APPDATA -Force | Out-Null
}Catch{
    Log -Text $($PSItem.Exception.Message) -Error
    Log -Text "Script End" -Error
    Exit
}

#Importing file into Internet Explorer.
Log -Text "Import Cookie into Internet Explorer (ieframe.dll,ImportCookieFileByProcess)"
rundll32.exe ieframe.dll,ImportCookieFileByProcess "$($env:APPDATA)\$($CookieFile)"

sleep 1

#Exporting cookies from Internet Explorer to a temporary text file.
Log -Text "Export Cookies from Internet Explorer (ieframe.dll,ExportCookieFileByProcess)"
rundll32.exe ieframe.dll,ExportCookieFileByProcess "$($env:APPDATA)\$($CookiesExportFileName)"

sleep 1

#If the file containing the cookie exist, we will be able to validate if the import was successfull.
#Otherwise, we cannot validate the import and can confirm that the export doesn't work.
If(Test-Path "$($env:APPDATA)\$($CookiesExportFileName)"){
    Log -Text "Testing path '$($env:APPDATA)\$($CookiesExportFileName)"

    #Read the imported cookie's file to be able to find if it exist in the export.
    Log -Text "Read file '$($env:APPDATA)\$($CookiesExportFileName)"
    Try{
        $OriginalCookieFile = Get-Content "$($env:APPDATA)\$($CookieFile)"
    }Catch{
        Log -Text $($PSItem.Exception.Message) -Error
        Log -Text "Script End" -Error
        Exit
    }
    $OriginalCookieContent=@()
    ForEach ($Line in $OriginalCookieFile){
        If ($Line -ne ""){
            If($Line.SubString(0,1) -ne "#"){
                $OriginalCookieContent += $Line
            }
        }
    }
    
    #Validate if imported cookie exist in the export file.
    #If yes, cookie was import succesfully. Otherwhise, cookie was not import.
    ForEach($Cookie in $OriginalCookieContent){
        If (Get-Content "$($env:APPDATA)\$($CookiesExportFileName)" | Select-String -Pattern $Cookie){
            Log -Text "Cookie $($Cookie.split() | Select-Object -First 1) import succesfully"
        }Else{
            Log -Text "Cookie was not import into Internet Explorer" -Error
        }
    }

    #Delete temporary file generated by the export of Internet Explorer cookies.
    Try{
        Remove-Item "$($env:APPDATA)\$($CookiesExportFileName)" -Force | Out-Null
        Log -Text "Successfully delete temporary exported cookie file"
    }Catch{
        Log -Text $($PSItem.Exception.Message) -Error
    }

}Else{

    Log -Text "Unable to export Internet Explorer Cookies" -Error
    Log -Text "Unable to validate cookie's import into Internet Explorer" -Warning

}

#Delete local cookie file in user profile.
Try{
    Remove-Item "$($env:APPDATA)\$($CookieFile)" -Force | Out-Null
    Log -Text "Successfully delete local cookie file"
}Catch{
    Log -Text $($PSItem.Exception.Message) -Error
}