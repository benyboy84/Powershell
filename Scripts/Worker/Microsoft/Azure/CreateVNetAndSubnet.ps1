<#
**********************************************************************************
Script to create Microsoft Azure virtual networks and subnets
**********************************************************************************

.SYNOPSIS
Script to create Microsoft Azure virtual networks and subnets.

Version 1.0 of this script.

.DESCRIPTION
This script is use to create Microsoft Azurevirtual networks and subnets. 
This script use Microsoft AZ PowerShell module.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./CreateVNetAndSubnet.ps1 
./CreateVNetAndSubnet.ps1  -debug
./CreateVNetAndSubnet.ps1  -output

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $True,
    [String]$Output = $True
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

#Microsoft Azure Region
$AzureRegion = "canadacentral"

#Microsoft Azure Subscription
$Subscription = "Abonnement1"

#Ressource group name
$RGName = "rg-net-cac-001"

#Virtual networks
$Vnets = @(
    New-Object PSObject -Property @{Name = "vnet-mgmnt-cac-001"; AddressPrefix = "10.0.0.0/16"}
)

#Subnets
$Subnets = @(
    New-Object PSObject -Property @{Name = "Data"; AddressPrefix = "10.0.0.0/24"; VirtualNetwork = "vnet-mgmnt-cac-001"}
    New-Object PSObject -Property @{Name = "web"; AddressPrefix = "10.0.1.0/24"; VirtualNetwork = "vnet-mgmnt-cac-001"}
)

# *******************************************************************************

#Log function will allow to display colored information in the PowerShell window if 
#debug mode is $TRUE. It will create a log file with the information related to the 
#script execution if output contain a path.
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
        $Text = "ERROR   | $Text"
    }
    ElseIf($Warning) {
        $Text = "WARNING | $Text"
    }
    Else {
        $Text = "INFO    | $Text"
    }
    If ($Debug) {
        If($Error) {
            Write-Host $Text -ForegroundColor Red
        }ElseIf($Warning) {
            Write-Host $Text -ForegroundColor Yellow
        }Else {
            Write-Host $Text -ForegroundColor Green
        }
    }
    If ($Output) {
        Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
    }
}

# **********************************************************************************

#Log file
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"

Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null

Log -Text "Script begin."

#Validating if Azure module is already installed.
Log -Text "Validating if Azure module is already installed."
$InstalledModule = Get-InstalledModule -Name Az -AllVersions 

If ($Null -eq $InstalledModule) {
    Try {
        #Microsoft Azure PowerShell module is not install. Installing PowerShell Module.
        Log -Text "Microsoft Azure PowerShell module is not install. Installing PowerShell Module."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    }
    Catch {
        Log -Text "Unable to install Azure PowerShell module. Script will exit." -Error
        Exit 1 
    }
}
Log -Text "Microsoft Azure PowerShell module is currently installed."

#Connecting to Microsoft Azure.
Log -Text "Connecting to Azure."
$Account = Connect-AzAccount
If ($Null -eq $Account) {
    Log -Text "Unable to login into Microsoft Azure. Script will exit." -Error
    Exit 1 
}
Log -Text "Successfully connected to Microsoft Azure."
    
#Validating if subscription exist.
Log -Text "Validating if subscription exist."
$AzSubscription = Get-AzSubscription | Where-Object {$_.Name -eq $Subscription}
If ($Null -eq $AzSubscription) {
    Log -Text "Unable to find the appropriate subscription. Script will exit." -Error
    Exit 1
}
Log -Text "Subscription $($Subscription) exists."

#Selecting the appropriate subscription.
Log -Text "Selecting the subscription $($Subscription)."
Try {
    Select-AzSubscription -Subscription $Subscription | Out-Null
}
Catch {
    Log -Text "Unable to select the appropriate subscription. Script will exit."
    Exit 1
}
Log -Text "Subscription $($Subscription) is currently selected."

#Validating if ressource group already exist.
Log -Text "Validating if ressource group already exist."
$AzResourceGroup = Get-AzResourceGroup | Where-Object {$_.Name -eq $RGName}

If ($Null -eq $AzResourceGroup) {
    #Creating the ressource group for network object.
    Log -Text "Creating ressourge group for network object."
    Try {
        $RG = New-AzResourceGroup -Name $RGName -Location $AzureRegion
    }
    Catch {
        Log -Text "Unable to create ressource group for network object. Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
    Log -Text "Ressourge group $($RGName) was successfully created."
}
Else {
    Log -Text "Ressourge group $($RGName) already exist."
}

#Creating Virtual networks.
ForEach ($VNet in $VNets) {

    #Validating if virtual network with the same name or address prefixes already exist.
    Log -Text "Validating if virtual network with the same name or address prefixe already exist."
    $AzVirtualNetwork = Get-AzVirtualNetwork | Where-Object {$_.Name -eq $VNet.Name -or $_.AddressSpace.AddressPrefixes -eq $VNet.AddressPrefix}

    If ($Null -eq $AzVirtualNetwork) {
        #Creating Virtual network.
        Log -Text "Creating VNet $($Vnet.Name)."
        Try {
            New-AzVirtualNetwork -Name $Vnet.Name -ResourceGroupName $RGName -Location $AzureRegion -AddressPrefix $Vnet.AddressPrefix | Out-Null
        }
        Catch {
            Log -Text "An error occurred during the creation of VNet $($Vnet.Name)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        Log -Text "Virtual network with the same name of address prefixe already exist." -Warning
    }
}


#Creating subnets
ForEach ($Subnet in $Subnets) {
    
    #Getting the virtual network for this subnet.
    Log -Text "Getting the virtual network for subnet $($Subnet.Name)."
    Try {
        $VirtualNetwork = Get-AzVirtualNetwork -Name $Subnet.VirtualNetwork
    }
    Catch {
        Log -Test "Unable to get the virtual network for subnet $($Subnet.Name)."
        Continue
    }

    #Validating if subnet with the same name or address prefixes already exist.
    Log -Text "Validating if subnet with the same name or address prefixes already exist."
    $AzVirtualNetworkSubnetConfig = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VirtualNetwork | Where-Object {$_.Name -eq $Subnet.Name -or $_.AddressPrefix -eq $Subnet.AddressPrefix}

    If ($Null -eq $AzVirtualNetworkSubnetConfig) {
        #Creating subnet.
        Log -Text "Creating subnet $($Subnet.Name)."
        Try {
            Add-AzVirtualNetworkSubnetConfig -Name $Subnet.Name -AddressPrefix $Subnet.AddressPrefix -VirtualNetwork $VirtualNetwork | Out-Null
            $VirtualNetwork | Set-AzVirtualNetwork | Out-Null
        }
        Catch {
            Log -Text "An error occurred during the creation of subnet $($Subnet.Name)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        Log -Text "Subnet with the same name of address prefixe already exist." -Warning
    }

}

