# Start transcript
Start-Transcript -Path C:\Temp\Add-ADUsers-Multi.log -Append

# Import AD Module
Import-Module ActiveDirectory

# Import the data from CSV file and assign it to variable
$List = Import-Csv "C:\Temp\Demo1.csv"

Foreach ($User in $List) {
    # Retrieve UserSamAccountName and ADGroup
    $UserName = $User.Name
    $Groups = $User.Group

    # Retrieve SamAccountName and ADGroup
    $ADSam = Get-ADUser -Filter "Name -eq ""$($UserName)""" | Select-Object SamAccountName
    $ADGroups = Get-ADGroup -Filter * | Select-Object Name

    # User does not exist in AD
    if ($null -eq $ADSam) {
        Write-Host "$UserName does not exist in AD" -ForegroundColor Red
        Continue
    }
    # User does not have a group specified in CSV file
    if ($null -eq $Groups) {
        Write-Host "$UserName has no group specified in CSV file" -ForegroundColor Yellow
        Continue
    }
    # Retrieve AD user group membership
    $ExistingGroups = Get-ADPrincipalGroupMembership $ADSam | Select-Object Name

    foreach ($Group in $Groups.Split(';')) {
        # Group does not exist in AD
        if ($ADGroups.Name -notcontains $Group) {
            Write-Host "$Group group does not exist in AD" -ForegroundColor Red
            Continue
        }
        # User already member of group
        if ($ExistingGroups.Name -eq $Group) {
            Write-Host "$UserName already exists in group $Group" -ForeGroundColor Yellow
        } 
        else {
            # Add user to group
            Add-ADGroupMember -Identity $Group -Members $ADSam -WhatIf
            Write-Host "Added $UserName to $Group" -ForeGroundColor Green
        }
    }
}
Stop-Transcript