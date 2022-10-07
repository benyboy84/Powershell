<#
**************************************************************************************************
Script to create Microsoft Azure virtual networks and subnets required for Palo Alto transit VNet
**************************************************************************************************

.SYNOPSIS
Script to create Microsoft Azure virtual networks and subnets required for Palo Alto transit VNet.

Version 1.0 of this script.

.DESCRIPTION
This script is use to create create Microsoft Azure virtual networks and subnets required for 
Palo Alto transit VNet based on the Securing Applications in Azure - Deployment Guide of July 
2022.

This script use Microsoft AZ PowerShell module.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./PaloAltoAzureTransitVNet.ps1 
./PaloAltoAzureTransitVNet.ps1  -debug
./PaloAltoAzureTransitVNet.ps1  -output

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
$Subscription = "Abonnement"

#Ressource group name
$RGName = "rg-net-cac-001"

#Virtual networks
$Vnets = @(
    New-Object PSObject -Property @{Name = "Transit"; AddressPrefix = "10.110.0.0/16"}
)

#Subnets
$Subnets = @(
    New-Object PSObject -Property @{Zone = "Public"; Name = "Public"; AddressPrefix = "10.110.129.0/24"; VirtualNetwork = "Transit"; NSG = "nsg-nvapub-cac-001"}
    New-Object PSObject -Property @{Zone = "Private"; Name = "Private"; AddressPrefix = "10.110.0.0/24"; VirtualNetwork = "Transit"; NSG = "nsg-nvapriv-cac-001"}
    New-Object PSObject -Property @{Zone = "Management"; Name = "Management"; AddressPrefix = "10.110.255.0/24"; VirtualNetwork = "Transit"; NSG = "nsg-nvamgnt-cac-001"}
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

#Change diaplay behavior to avoid warning for changes.
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
$Account = Connect-AzAccount -Subscription $Subscription
If ($Null -eq $Account) {
    Log -Text "Unable to login into Microsoft Azure. Script will exit." -Error
    Exit 1 
}
Log -Text "Successfully connected to Microsoft Azure."
    

#Validating if ressource group already exist.
Log -Text "Validating if ressource group already exist."
$AzResourceGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -eq $RGName}

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
    Log -Text "Ressourge group $($RGName) already exist."  -Warning
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

#Creating network security group
#Validating if network security group for private network already exist.
Log -Text "Validating if network security group for private network already exist."
$NSG = Get-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG)
If ($Null -eq $NSG) {
    Log -Text "Creating network security group for private network."
    Try {
        $NSG = New-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG) -ResourceGroupName $RGName -Location $AzureRegion | Out-Null
    }
    Catch {
        Log -Text "An error occurred during the creation of the private NSG $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
    }
}
Else {
    Log -Text "Network security group for private network already exist." -Warning
}

Log -Text "Validating if network security group for management network already exist."
$NSG = Get-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Management"} | Select-Object -Property NSG -ExpandProperty NSG)
If ($Null -eq $NSG) {
    Log -Text "Creating network security group for management network."
    Try {
        $NSG = New-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Management"} | Select-Object -Property NSG -ExpandProperty NSG) -ResourceGroupName $RGName -Location $AzureRegion | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternet" -Description "Allow Internet" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "Internet" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "22,443" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowManagement" -Description "Allow Management" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1010 -SourceAddressPrefix "10.255.0.0/24" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowOnPremises" -Description "Allow On-Premises" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1020 -SourceAddressPrefix "10.5.0.0/16" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "DenyAllInbound" -Description "Deny All Inbound" -Access "Deny" -Protocol "*" -Direction "Inbound" -Priority 1500 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
        $NSG | Set-AzNetworkSecurityGroup
    }
    Catch {
        Log -Text "An error occurred during the creation of the management NSG $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
    }
}
Else {
    Log -Text "Network security group for management network already exist." -Warning
}

Log -Text "Validating if network security group for public network already exist."
$NSG = Get-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Public"} | Select-Object -Property NSG -ExpandProperty NSG)
If ($Null -eq $NSG) {
    Log -Text "Creating network security group for public network."
    Try {
        $NSG = New-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Public"} | Select-Object -Property NSG -ExpandProperty NSG) -ResourceGroupName $RGName -Location $AzureRegion | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternet" -Description "Allow Internet" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "Internet" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "80,443" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowAzureLoadBalancer" -Description "Allow Azure Load Balancer" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1040 -SourceAddressPrefix "AzureLoadBalancer" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "DenyAllInbound" -Description "Deny All Inbound" -Access "Deny" -Protocol "*" -Direction "Inbound" -Priority 1500 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternet" -Description "Allow Internet" -Access "Allow" -Protocol "*" -Direction "Outbound" -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "Internet" -DestinationPortRange "*" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowPublicToPublic" -Description "Allow Public To Public" -Access "Allow" -Protocol "*" -Direction "Outbound" -Priority 1010 -SourceAddressPrefix "10.128.0.0/23" -SourcePortRange "*" -DestinationAddressPrefix "10.128.0.0/23" -DestinationPortRange "*" | Out-Null
        $NSG | Add-AzNetworkSecurityRuleConfig -Name "DenyAllOutbound" -Description "DenyAllOutbound" -Access "Deny" -Protocol "*" -Direction "Outbound" -Priority 1500 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
        $NSG | Set-AzNetworkSecurityGroup
    }
    Catch {
        Log -Text "An error occurred during the creation of the public NSG $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
    }
}
Else {
    Log -Text "Network security group for public network already exist." -Warning
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
            $NSG = Get-AzNetworkSecurityGroup -Name $Subnet.NSG
            Add-AzVirtualNetworkSubnetConfig -Name $Subnet.Name -AddressPrefix $Subnet.AddressPrefix -VirtualNetwork $VirtualNetwork -NetworkSecurityGroup $NSG | Out-Null
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

