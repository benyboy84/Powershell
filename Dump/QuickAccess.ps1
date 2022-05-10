# *******************************************************************************
# Script to edit Quick Access.
#
# This script will remove Desktop from Quick Access bar in Windows Explorer and
# add every quick access needed based on Active Directory group.
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2020-05-28  Benoit Blais        Creation
# *******************************************************************************

Param(
    [Switch]$Debug = $False
)

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION
$Recent = "$($env:APPDATA)\Microsoft\Windows\Recent\AutomaticDestinations"

#Quick Access Shortcut
#If many group give access, you need to seperate it with a comma ","
$QuickAccessShortcut = @(
    New-Object PSObject -Property @{Group = "GCAS-APP-MsOffice_SAP_EPM_IBP_Addon_CX_FR,GCAS-APP-MsOffice_SAP_EPM_IBP_Addon_CX_EN"; Path = "U:\Citrix Folder\Documents\SAP_IBP"}
    New-Object PSObject -Property @{Group = "GCAS-APP-SAPLumira_CX_FR,GCAS-APP-SAPLumira_CX_EN,G362-APP-SQP_QACEE_CX_EN"; Path = "U:\Citrix Folder\Documents\SAP Lumira Documents"}
    New-Object PSObject -Property @{Group = "GCRI-APP-TruxHaul-It_CX5_EN,GCRI-APP-TruxHaul-It_GBN_CX5_EN,GCRI-APP-TruxWeigh-It_CX5_EN,GCRI-APP-TruxWeigh-It_GBN_CX5_EN,G309-App-TruxExtract_GBN_CX_EN,GCRI-APP-TruxExtract_Prod_CX_EN,GCRI-APP-TRUXP&L_CX_EN"; Path = "U:\TRUXSCREEN"}
)

# *******************************************************************************

#Default action when an error occured.
$ErrorActionPreference = "Stop"

# *******************************************************************************

#If debug is not $TRUE, we will hide the current PowerShell processus window.
If($Debug -eq $False) {
    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    Try {
        Add-Type -name win -member $t -namespace native
        [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)
    } Catch {$Null}
}

# *******************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
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

#Retreive operating system language
$SystemLocal = Get-WinSystemLocale
Log -Text "System Local is $($SystemLocal.DisplayName)"

#Create the ComObject with the Shell.Application
Try {
    $QuickAccess = New-Object -ComObject shell.application 
    Log -Text "Create the ComObject shell.application"
}
Catch {
    Log -Test "Unable to ComObject shell.application" -Error
    Exit
}

#Based on OS language, remove the desktop from Quick Access
Switch ($SystemLocal.LCID) {
    "3084" {
        #Validate if Bureau exist in Quick Access
        If (($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Name -eq "Bureau"}) -ne $Null) {
            Try{
                #To enable the change, we need to delete the file in the AutomaticDestinations folder
                If (Test-Path $Recent) {
                    Get-ChildItem -Path $Recent | ForEach-Object {Remove-Item $_.FullName -Force | Out-Null}
                }
                Log -Text "Files deleted in $($Recent)"
                #Remove Bureau from Quick Access
                ($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Name -eq "Bureau"}).InvokeVerb("unpinfromhome")
                Log -Text "Remove Bureau from Quick Access"
            }
            Catch {
                Log -Text "Unable to remove Bureau from Quick Access" -Error
            }
        }
        Else {
            Log -Text "Bureau not pin to Quick Access"
        }
    }
    "1033" {
        #Validate if Desktop exist in Quick Access
        If (($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Name -eq "Desktop"}) -ne $Null) {
            Try{
                #To enable the change, we need to delete the file in the AutomaticDestinations folder
                If (Test-Path $Recent) {
                    Get-ChildItem -Path $Recent | ForEach-Object {Remove-Item $_.FullName -Force}
                }
                Log -Text "Successfully delete files in $($Recent)"
                #Remove Desktop from Quick Access
                ($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Name -eq "Desktop"}).InvokeVerb("unpinfromhome")
                Log -Text "Remove Desktop from Quick Access"
            }
            Catch {
                Log -Text "Unable to remove Desktop from Quick Access" -Error
            }
        }
        Else {
            Log -Text "Desktop not pin to Quick Access"
        }
    }

}

#Retreive group membership of the current user
Try {
    $MemberOf = ([ADSISEARCHER]"samaccountname=$($env:USERNAME)").Findone().Properties.memberof -replace '^CN=([^,]+).+$','$1'
    Log -Text "Get Active Directory group members for the current user"
}
Catch {
    Log -Text "Unable to get Active Directory group members for the current user" -Error
    Exit
}

#Loop through each Quick Access shorcut to see if we need to configure it or remove it
ForEach ($Item in $QuickAccessShortcut) {

    #Loop through each group that gives access to the application to see if the current user is member of
    $CheckMemberOf = $Null
    $QuickAccessGroups = ($Item.group).Split(",")
    ForEach ($QuickAccessGroup in $QuickAccessGroups) {

        #If user is member of one group, we change the $CheckMemberOf variable to true        
        If ($MemberOf -contains $QuickAccessGroup) {
            $CheckMemberOf = $True
        }

    }

    # If user is member of a group for which we need to configure the Quick Access, try to add it
    If ($CheckMemberOf) {

        #Validate if Quick Access exist
        If (($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Path -eq $Item.Path}) -eq $Null) {
            Try{
                #Validate if the path where the Quick Access point exist
                If (Test-Path $Item.Path) {
                    #Because the destination path exist, try to add the Quick Access
                    $QuickAccess.Namespace($Item.Path).Self.InvokeVerb(“pintohome”)
                    Log -Text "Pin $($Item.Path)"
                }
                Else {
                    Log -Text "$($Item.Path) does not exist" -Error
                }
            }
            Catch {
                Log -Text "Unable to pin $($Item.Path)" -Error
            }
        }
        Else {
            Log -Text "$($Item.Path) already pin to Quick Access"
        }

    }
    Else {

        #Because the user is not a member of any group that give access to that Quick Access, we will validate if the user have it and try to remove it
        #Validate if Quick Access exist
        If (($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Path -eq $Item.Path}) -ne $Null) {
            Try{
                #Because the Quick Access exist, we will try to remove it
                ($QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() | where {$_.Path -eq $Item.Path}).InvokeVerb("unpinfromhome")
                Log -Text "Remove $($Item.Path) from Quick Access"
            }
            Catch {
                Log -Text "Unable to remove $($Item.Path) from Quick Access" -Error
            }
        }
        Else {
            Log -Text "$($Item.Path) not pin to Quick Access"
        }

    }

}
