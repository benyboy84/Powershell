<#

.SYNOPSIS
This Powershell script updates the security descriptor for scheduled tasks so that any user can run the task. 

Version 1.0 of this script only displays tasks in the root folder. I want to make sure that works first. 

.DESCRIPTION
Earlier versions of Windows apparently used file permissions on C:\Windows\System32\Tasks files to manage security.
Windows now uses the SD value on tasks under HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree to accomplish that. 

By default, this script will display the SDDL on all tasks. If a taskname is passed as a parameter, this script will grant Authenticated users read and execute permissions to the task. 

This script accepts 2 parameters.
-taskname   The name of a scheduled task. 
-SID        The SID of the user or the group who need access to execute the task

.EXAMPLE
./UnlockScheduledTask.ps1 
./UnlockScheduledTask.ps1 -taskname "My task" -SID "S-1-5-21-2805552735-2756301465-993970405-1008" 

.NOTES
Author: Dave K. aka MotoX80 on the MS Technet forums. (I do not profess to be an expert in anything. I do claim to be dangerous with everything.)



.LINK
http://www.google.com

#>

Param (
    [string]$TaskName="Citrix - Update Elemos - VAT",
    [string]$SID="S-1-5-21-382205161-1785277870-2884483717-616100"
    )

 Write-Host "UnlockScheduledTask.ps1  Version 1.0"
 If ($taskname -eq '') {
    Write-Host "No task name specified."
    Write-Host "SDDL for all tasks will be displayed."
 } 
 Else {
    $RegFile = "$($env:TEMP)\Set-A-Task-Free.reg"           # if you don't like my names, you can change them here. 
    $UpdateTaskName = "Set-A-Task-Free"
    Write-Host "SDDL for $taskname will be updated via $batfile"
 }

 $wmisdh = new-object system.management.ManagementClass Win32_SecurityDescriptorHelper 
 $SubKeys = Get-childitem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree" -Recurse

 ForEach ($Key in $SubKeys) {
     If ($TaskName -eq '') {              # if blank, show SDDL for all tasks 
        $Key.PSChildName
        $Task = Get-ItemProperty $($Key.name).replace("HKEY_LOCAL_MACHINE","HKLM:")
        $SDDL = $wmisdh.BinarySDToSDDL( $Task.SD ) 
        Write-Host "$($SDDL['SDDL'])"
     }
     Else {
        If ($Key.PSChildName -eq $TaskName) {
            Write-Host "$($Key.PSChildName)"
            $Task = Get-ItemProperty $($Key.name).replace("HKEY_LOCAL_MACHINE","HKLM:")
            $SDDL = $wmisdh.BinarySDToSDDL( $Task.SD ) 
            Write-Host "$($SDDL['SDDL'])"
            If ($SID -ne "") {
                $NewSD = $SDDL['SDDL'] +  "(A;;FX;;;$($SID))(A;ID;FR;;;$($SID))"          # add SID execute access
            }
            Else {
                $NewSD = $SDDL['SDDL'] +  "(A;;FX;;;AU)(A;ID;FR;;;AU)"          # add authenticated execute access
            }
            Write-Host "$($NewSD)"
            $NewBin = $wmisdh.SDDLToBinarySD( $NewSD )
            [string]$NewBinStr =  $([System.BitConverter]::ToString($NewBin['BinarySD'])).replace('-',',') 
            
            # Administrators only have read permissions to the registry vlaue that needs to be updated.
            # We will create reg file  to set the new SD.
            # The reg file will be invoked by a scheduled task that runs as the system account.
            "Windows Registry Editor Version 5.00" | out-file -Encoding ascii $RegFile
            "" | out-file -Encoding ascii $RegFile -Append 
            "[$($key.name)]" | out-file -Encoding ascii $RegFile -Append
            """SD""=hex:$($NewBinStr)" | out-file -Encoding ascii $RegFile -Append
            
            SCHTASKS /Create /f /tn "$updateTaskName" /sc onstart  /tr "regedit.exe /s /s $RegFile" /ru system | Out-Null
            SCHTASKS /run /tn "$updateTaskName" | Out-Null
            $count = 0
            while ($count -lt 5) {
                Start-Sleep 5
                $count++
                If ($(Get-ScheduledTask -TaskName $UpdateTaskName).State -eq 'Ready') {
                    $count = 99            # it's ok to procees
                }
            }
            if ($count -ne 99) {
                Write-Host "Error! The $updateTaskName task is still running. "
                Write-Host "It should have ended by now."
                Write-Host "Please investigate."
                return
            }
            SCHTASKS /delete /f /tn "$UpdateTaskName"
            Write-Host "Security has been updated. Test it."
        
        }
    }      
 }
 