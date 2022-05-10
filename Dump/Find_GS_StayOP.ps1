# *******************************************************************************
# Script to to find GS_StayOP.ini and change a path in it.
#
# This script will list all user files under a specific root folder. 
#
# The repository structure should be:
# _ Root folder
#  |_ Company Folder
#    |_ Users
#      |_ %User Folder%
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2021-02-11  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$ProfilePath = "\\fs.cascades.com\FS-CASCADES"              # Root folder of the users folders

# *******************************************************************************

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Logs = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$Id = 1

# *******************************************************************************

# Log function will allow to write information to text file we will also display 
# colored information in the PowerShell window.
# Parameters:
# $Text : Text added to the text file.
# $Error and $Warning: These switch need to be use to specify something else then an information.
Function Log{
    Param (
        [Parameter(Mandatory=$true)][String]$Text,
        [Switch]$Error,
        [Switch]$Warning
    )
    If($Error){
        $Text = "ERROR   | $Text"
        Write-Host $Text -ForegroundColor Red
    }
    ElseIf($Warning){
        $Text = "WARNING | $Text"
        Write-Host $Text -ForegroundColor Yellow
    }
    Else{
        $Text = "INFO    | $Text"
        Write-Host $Text -ForegroundColor Green
    }
    Try{
        Add-Content $Logs "$(Get-Date) | $text"
    }Catch{$Null}
}

# *******************************************************************************

# Start script
Log -Text "SCRIPT BEGIN"

$ErrorActionPreference = "stop"

$Companies = $Null
# Validate the profile root folder exist.
If (Test-Path $ProfilePath) {

    # Because root folder exist, we can try to get the companies folder.
    Try {
        $Companies = Get-ChildItem -Path $ProfilePath -Directory | select Name,FullName | Sort-Object Name
        Log -Text "Successfully get company folder"
    }
    Catch {
        Log -Text "Unable to get company folder" -Error
        Log -Text "SCRIPT END" -Append
        Exit
    }
}

$Count1 = 0
#List each mills for each companies
ForEach($Company in $Companies){
    
    $Mills = $Null
    $Count1++
    Write-Progress -Id $Id -Activity "Company" -Status "Listing $($Count1) of $($Companies.count): Company - $($Company.Name)"  -PercentComplete ($Count1/$Companies.count*100)

    # Get mill folder for that company
    Try {
        $Mills = Get-ChildItem -Path "$($Company.FullName)" -Directory | select Name,FullName | Sort-Object Name
        Log -Text "Successfully get mills folders for company $($Company.Name)"
    }
    Catch {
        Log -Text "Unable to get mills folders for company $($Company.Name)" -Error
    }

    $UsersProfiles = $Null
    $Count2 = 0
    #List each mills of the company
    ForEach($Mill in $Mills) {
        
        $Count2++
        Write-Progress -Id ($Id + 1) -Activity "Mill" -Status "Listing $($Count2) of $($Mills.count): Mill - $($Mill.Name)"  -PercentComplete ($Count2/$Mills.count*100)

        # Get user folder for that mill.
        Try {
            $UsersProfiles = Get-ChildItem -Path "$($Mill.FullName)\Users" -ErrorAction SilentlyContinue | select FullName -ExpandProperty FullName | Sort-Object FullName
            Log -Text "Successfully get users folders for mill $($Mill.NAME)"
        }
        Catch {
            Log -Text "Unable to get users folders for mill $($Mill.NAME)" -Error
        }

        $Count3 = 0
        # List each user profil for that mill
        ForEach($UserProfile in $UsersProfiles) {
        
            $Count3++
            $Username = $UserProfile.Split("\") | Select-Object -Last 1
            Write-Progress -Id ($Id + 2) -Activity "User" -Status "Searching file in user $($Count3) of $($UsersProfiles.count): User - $($Username)"  -PercentComplete ($Count3/$UsersProfiles.count*100)

            If (Test-Path "$($UserProfile)\Guichet\GS_StayOP.ini") {
         
                If ((Get-Content "$($UserProfile)\Guichet\GS_StayOP.ini") -match "CONFORMIT76") {

                    Try {
                        Copy-Item -Path "$($UserProfile)\Guichet\GS_StayOP.ini" -Destination "$($UserProfile)\Guichet\GS_StayOP.bak" -force
                        Log -Text "Successfulle create backup file for $($Username)"
                    }
                    Catch {
                        Log -Text "Unable to create backup file GS_StayOP.bak" -Error
                    }
                    Try {
                        (Get-Content "$($UserProfile)\Guichet\GS_StayOP.ini") -replace '\\\\ad.cascades.com\\apps\\CTX-Apps\\CONFORMIT76', '\\amznfsxqdnyg5ab.ad.cascades.com\CTX-Apps\CONFORMIT76' | Set-Content "$($UserProfile)\Guichet\GS_StayOP.ini"
                        Log -Text "Successfulle replace file content"
                    }
                    Catch {
                        Log -Text "Unable to replace file content" -Error
                        Write-Host "$($PSItem.Exception.Message)" 
                    }
                    

                }

            }

        }

    }

}

