<#
**************************************************************************************************
Script to create Palo Alto VM-Series in Microsoft Azure
**************************************************************************************************

.SYNOPSIS
Script to create Palo Alto VM-Series in Microsoft Azure.

Version 1.0 of this script.

.DESCRIPTION
This script is use to create create Palo Alto VM-Series in Microsoft Azure based on the Securing 
Applications in Azure - Deployment Guide of July 2022.

This script use Microsoft AZ PowerShell module.

This script need ARM Template and paramaters file.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./Microsoft_Azure_Palo_Alto_VM-Series_Deployment.ps1 
./Microsoft_Azure_Palo_Alto_VM-Series_Deployment.ps1  -debug
./Microsoft_Azure_Palo_Alto_VM-Series_Deployment.ps1  -output

.NOTES
Author: Benoit Blais

.LINK
https://

#>

Param(
    [Switch]$Debug = $True,
    [String]$Output = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

#Microsoft Azure region
$AzureRegion = "canadacentral"

#Microsoft Azure subscription
$Subscription = ""

#Ressource group name
$RGName = ""

#Virtual networks
$Vnets = @(
    New-Object PSObject -Property @{Name = ""; AddressPrefix = ""}
)

#Subnets
$Subnets = @(
    New-Object PSObject -Property @{Zone = "Public"; Name = ""; AddressPrefix = ""; VirtualNetwork = ""; NSG = ""}
    New-Object PSObject -Property @{Zone = "Private"; Name = ""; AddressPrefix = ""; VirtualNetwork = ""; NSG = ""}
    New-Object PSObject -Property @{Zone = "Management"; Name = ""; AddressPrefix = ""; VirtualNetwork = ""; NSG = ""}
)

#CIDR of management workstation from which Palo Alto will be managed
$MgntWorkstationCIDR = ""

#CIDR of Palo Alto Panorama
$PanoramaCIDR = ""

#Subnet for device from which Palo Alto will be managed
$ManagementDeviceSubnet = ""

#On-Premise public IPs addresses
$OnPremPublicIpsAddresses = @("")

#Name of the public IPs for management interface of VM-Series
$MgntPublicIPsNames = @(
    New-Object PSObject -Property @{Name = ""; Zone = "1"}
    New-Object PSObject -Property @{Name = ""; Zone = "2"}
)

#Name of the ARM template file
#This file needs to be in the same directory as the script
$ARMTemplate = "AzureDeployVM-Series.json"

#Name of the Palo Alto instances
#Name of the parameters file used to deploy Palo Alto instances
#This file needs to be in the same directory as the script
$Firewalls = @(
    New-Object PSObject -Property @{Name = ""; ARMTemplateProperties = "AzureDeployVM-Series1.parameters.json"}
    New-Object PSObject -Property @{Name = ""; ARMTemplateProperties = "AzureDeployVM-Series2.parameters.json"}
)

#Name of the public IPs for public interface of VM-Series
$PublicPublicIPsNames = @(
    New-Object PSObject -Property @{Name = ""; Zone = "1"; AssociatedTo = $FWName1}
    New-Object PSObject -Property @{Name = ""; Zone = "2"; AssociatedTo = $FWName2}
)

#Name of the internal load balancer
$LBName = ""

#Public IP of the internal load balancer
$LBIP = ""

#Name of the routing table for private subnet
$RTName = ""

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
Update-AzConfig -DisplayBreakingChangeWarning $False | Out-Null

Log -Text "Script begin."

#**************************************************************************************************
#Az PowerShell module installation
#************************************************************************************************** 

#Validating if Azure module is already installed.
Log -Text "Validating if Azure module is already installed."
$InstalledModule = Get-InstalledModule -Name Az -AllVersions -ErrorAction SilentlyContinue

If ($Null -eq $InstalledModule) {
    Try {
        #Microsoft Azure PowerShell module is not install. Installing PowerShell Module.
        Log -Text "Microsoft Azure PowerShell module is not install. Installing PowerShell Module."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
        Log -Text "Microsoft Azure PowerShell module successfully installed."
    }
    Catch {
        Log -Text "Unable to install Azure PowerShell module. Script will exit." -Error
        Exit 1 
    }
}
Else {
    Log -Text "Microsoft Azure PowerShell module is already installed."
}

#**************************************************************************************************
#Connecting to Microsoft Azure
#************************************************************************************************** 

Log -Text "Connecting to Azure."
Try {
    Connect-AzAccount -Subscription $Subscription | Out-Null
    Log -Text "Successfully connected to Microsoft Azure."
}
Catch{
    Log -Text "Unable to login into Microsoft Azure. Script will exit." -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error 
    Exit 1 
}

#**************************************************************************************************
#Creation of the ressource group
#**************************************************************************************************  
    
#Validating if ressource group already exist.
Log -Text "Validating if ressource group $($RGName) already exist."
$AzResourceGroup = Get-AzResourceGroup -Name $RGName -ErrorAction SilentlyContinue

If ($Null -eq $AzResourceGroup) {
    #Creating the ressource group.
    Log -Text "Creating ressourge group $($RGName)."
    Try {
        $RG = New-AzResourceGroup -Name $RGName -Location $AzureRegion
        Log -Text "Ressourge group $($RGName) successfully created."
    }
    Catch {
        Log -Text "Unable to create ressource group $($RGName) for network object. Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
    Log -Text "Ressourge group $($RGName) was successfully created."
}
Else {
    If ($AzResourceGroup.Location -ne $AzureRegion) {
        Log -Text "Ressourge group $($RGName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
        Exit 1
    }
    Else {
        Log -Text "Ressourge group $($RGName) already exist."
    }
}

#**************************************************************************************************
#Creation of the virtual network
#**************************************************************************************************

ForEach ($VNet in $VNets) {
    #Validating if virtual network already exist.
    Log -Text "Validating if virtual network $($VNet.Name) already exist."
    $AzVirtualNetwork = Get-AzVirtualNetwork -Name $VNet.Name -ErrorAction SilentlyContinue

    If ($Null -eq $AzVirtualNetwork) {
        #Creating Virtual network.
        Log -Text "Creating VNet $($Vnet.Name)."
        Try {
            New-AzVirtualNetwork -Name $Vnet.Name -ResourceGroupName $RGName -Location $AzureRegion -AddressPrefix $Vnet.AddressPrefix | Out-Null
            Log -Text "VNet $($Vnet.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of VNet $($Vnet.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        $Config = $True
        If ($AzVirtualNetwork.ResourceGroupName -ne $RGName) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) is not in the ressource group $($RGName). Script will exit." -Warning
        }
        If ($AzVirtualNetwork.Location -ne $AzureRegion) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
        }
        If ($AzVirtualNetwork.AddressSpace.AddressPrefixes -ne $VNet.AddressPrefix) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) does not have the address prefixes $($Vnet.AddressPrefix). Script will exit." -Warning
        }
        If ($Config) {
            Log -Text "Virtual network $($Vnet.Name) already exist."
        }
        Else {
            Exit 1
        }
    }
}

#**************************************************************************************************
#Creation of the network security group
#**************************************************************************************************

#Creating network security group.
#Validating if network security group for private network already exist.
Log -Text "Validating if network security group for private network already exist."
$NSG = Get-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG) -ErrorAction SilentlyContinue
If ($Null -eq $NSG) {
    #Creating network security group for private network.
    Log -Text "Creating network security group for private network."
}
Else {
    Log -Text "Network security group for private network already exist. We will replace it." -Warning
}
Try {
    $NSG = New-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG) -ResourceGroupName $RGName -Location $AzureRegion -Force
}
Catch {
    Log -Text "An error occurred during the creation of the network security group $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG) for private network." -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error
}

#Validating if network security group for management network already exist.
Log -Text "Validating if network security group for management network already exist."
$NSG = Get-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Management"} | Select-Object -Property NSG -ExpandProperty NSG) -ErrorAction SilentlyContinue
If ($Null -eq $NSG) {
    #Creating network security group for management network.
    Log -Text "Creating network security group for management network."
}
Else {
    Log -Text "Network security group for management network already exist. We will replace it." -Warning
}
Try {
    $NSG = New-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Management"} | Select-Object -Property NSG -ExpandProperty NSG) -ResourceGroupName $RGName -Location $AzureRegion -Force
    #$NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternet" -Description "Allow Internet" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "Internet" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange (22,443) | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternet" -Description "Allow Internet" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix $OnPremPublicIpsAddresses -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange (22,443) | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowManagement" -Description "Allow Management" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1010 -SourceAddressPrefix $MgntWorkstationCIDR -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    #$NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowOnPremises" -Description "Allow On-Premises" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1020 -SourceAddressPrefix "10.5.0.0/16" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Set-AzNetworkSecurityGroup | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowWindows365" -Description "Allow Windows 365" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1030 -SourceAddressPrefix $ManagementDeviceSubnet -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowPanorama" -Description "Allow Panorama" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1040 -SourceAddressPrefix $PanoramaCIDR -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "DenyAllInbound" -Description "Deny All Inbound" -Access "Deny" -Protocol "*" -Direction "Inbound" -Priority 1500 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    $NSG | Set-AzNetworkSecurityGroup | Out-Null
}
Catch {
    Log -Text "An error occurred during the creation of the network security group $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG) for management network." -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error
}

#Validating if network security group for public network already exist.
Log -Text "Validating if network security group for public network already exist."
$NSG = Get-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Public"} | Select-Object -Property NSG -ExpandProperty NSG) -ErrorAction SilentlyContinue
If ($Null -eq $NSG) {
    Log -Text "Creating network security group for public network."
}
Else {
    Log -Text "Network security group for public network already exist. We will replace it." -Warning
}
Try {
    $NSG = New-AzNetworkSecurityGroup -Name $($Subnets | Where-Object {$_.Zone -eq "Public"} | Select-Object -Property NSG -ExpandProperty NSG) -ResourceGroupName $RGName -Location $AzureRegion -Force
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternetInbound" -Description "Allow Internet Inbound" -Access "Allow" -Protocol "TCP" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "Internet" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange (80,443) | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowAzureLoadBalancer" -Description "Allow Azure Load Balancer" -Access "Allow" -Protocol "*" -Direction "Inbound" -Priority 1040 -SourceAddressPrefix "AzureLoadBalancer" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "DenyAllInbound" -Description "Deny All Inbound" -Access "Deny" -Protocol "*" -Direction "Inbound" -Priority 1500 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowInternetOutbound" -Description "Allow Internet Outbound" -Access "Allow" -Protocol "*" -Direction "Outbound" -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "Internet" -DestinationPortRange "*" | Out-Null
    #For application gateway scenario
    #$NSG | Add-AzNetworkSecurityRuleConfig -Name "AllowPublicToPublic" -Description "Allow Public To Public" -Access "Allow" -Protocol "*" -Direction "Outbound" -Priority 1010 -SourceAddressPrefix "10.128.0.0/23" -SourcePortRange "*" -DestinationAddressPrefix "10.128.0.0/23" -DestinationPortRange "*" | Out-Null
    $NSG | Add-AzNetworkSecurityRuleConfig -Name "DenyAllOutbound" -Description "DenyAllOutbound" -Access "Deny" -Protocol "*" -Direction "Outbound" -Priority 1500 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "*" | Out-Null
    $NSG | Set-AzNetworkSecurityGroup | Out-Null
}
Catch {
    Log -Text "An error occurred during the creation of the network security group $($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property NSG -ExpandProperty NSG) for public network." -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error
}

#**************************************************************************************************
#Creation of the subnet
#**************************************************************************************************

#Creating subnets
ForEach ($Subnet in $Subnets) {
    #Getting the virtual network for this subnet.
    Log -Text "Getting the virtual network for subnet $($Subnet.Name)."
    Try {
        $VirtualNetwork = Get-AzVirtualNetwork -Name $Subnet.VirtualNetwork
    }
    Catch {
        Log -Test "Unable to get the virtual network for subnet $($Subnet.Name). Script will exit." -Error
        Exit 1
    }
    #Validating if subnet with the same name already exist.
    Log -Text "Validating if subnet $($Subnet.Name) already exist."
    $AzVirtualNetworkSubnetConfig = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VirtualNetwork -Name $Subnet.Name -ErrorAction SilentlyContinue
    If ($Null -eq $AzVirtualNetworkSubnetConfig) {
        #Creating subnet.
        Log -Text "Creating subnet $($Subnet.Name)."
        Try {
            Add-AzVirtualNetworkSubnetConfig -Name $Subnet.Name -AddressPrefix $Subnet.AddressPrefix -VirtualNetwork $VirtualNetwork | Out-Null
            $VirtualNetwork | Set-AzVirtualNetwork | Out-Null
            Log -Text "Subnet $($Subnet.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of subnet $($Subnet.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        If ($AzVirtualNetworkSubnetConfig.AddressPrefix -ne $Subnet.AddressPrefix) {
            $Config = $False
            Log -Text "Subnet $($Subnet.Name) does not have the address prefix $($Vnet.AddressPrefix). Script will exit." -Warning
            Exit 1
        }
        Else {
            Log -Text "Subnet $($Subnet.Name) already exist."
        }
    }
}

#**************************************************************************************************
#Creation of the management public IPs
#**************************************************************************************************  

ForEach ($MgntPublicIPName in $MgntPublicIPsNames) {
    #Validating if the public IP address already exist.
    Log -Text "Validating if the public IP address $($MgntPublicIPName.Name) already exist."
    $PIP = Get-AzPublicIpAddress -Name $MgntPublicIPName.Name -ErrorAction SilentlyContinue
    If ($Null -eq $PIP) {
        #Creating public IP.
        Log -Text "Creating public IP address $($MgntPublicIPName.Name)."
        Try {
            $PIP = New-AzPublicIpAddress -Name $MgntPublicIPName.Name -ResourceGroupName $RGName -Location $AzureRegion -IpAddressVersion IPv4 -Sku Standard -AllocationMethod Static -Zone $MgntPublicIPName.Zone
            Log -Text "Public IP address $($MgntPublicIPName.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of the public IP address $($MgntPublicIPName.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        $Config = $True
        If ($PIP.ResourceGroupName -ne $RGName) {
            $Config = $False
            Log -Text "Public IP address $($MgntPublicIPName.Name) is not in the ressource group $($RGName). Script will exit." -Warning
        }
        If ($PIP.Location -ne $AzureRegion) {
            $Config = $False
            Log -Text "Public IP address $($MgntPublicIPName.Name) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
        }
        If ($PIP.PublicIpAddressVersion -ne "IPv4") {
            $Config = $False
            Log -Text "Public IP address $($MgntPublicIPName.Name) version is not IPv4. Script will exit." -Warning
        }
        If ($PIP.Sku.Name -ne "Standard") {
            $Config = $False
            Log -Text "Public IP address $($MgntPublicIPName.Name) sku is not standard. Script will exit." -Warning
        }
        If ($PIP.PublicIpAllocationMethod -ne "Static") {
            $Config = $False
            Log -Text "Public IP address $($MgntPublicIPName.Name) allocation method is not static. Script will exit." -Warning
        }
        If ($PIP.Zones -ne $MgntPublicIPName.Zone) {
            $Config = $False
            Log -Text "Public IP address $($MgntPublicIPName.Name) is not in zone $($MgntPublicIPName.Zone). Script will exit." -Warning
        }
        If ($Config) {
            Log -Text "Public IP address $($MgntPublicIPName.Name) already exist."
        }
        Else {
            Exit 1
        }
    }
}

#**************************************************************************************************
#Deploy Palo Alto VM-Series with ARM Template
#**************************************************************************************************  

ForEach ($Firewall in $Firewalls) {
    #Validating if a virtual machine instance already exist.
    Log -Text "Validating if a virtual machine instance $($Firewall.Name) already exist."
    $VM = Get-AzVM -ResourceGroupName $RGName -Name $Firewall.Name -ErrorAction SilentlyContinue
    If ($Null -eq $VM) {
        Try {
            $Output = New-AzResourceGroupDeployment -Name "$($Firewall.Name)_deployment" -ResourceGroupName $RGName -TemplateFile "$($ScriptPath)\$($ARMTemplate)" -TemplateParameterFile "$($ScriptPath)\$($Firewall.ARMTemplateProperties)"
            Log -Text "Virtual Machine $($Firewall.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of the virtual machine $($Firewall.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        Log -Text "Virtual Machine $($Firewall.Name) already exist."
    }
}

#**************************************************************************************************
#Creation of the untrust public IPs and assignment to eth1
#**************************************************************************************************  

ForEach ($PublicPublicIPName in $PublicPublicIPsNames) {

    #Validating if the public IP address already exist.
    Log -Text "Validating if the public IP address $($PublicPublicIPName.Name) already exist."
    $PIP = Get-AzPublicIpAddress -Name $PublicPublicIPName.Name -ErrorAction SilentlyContinue
    If ($Null -eq $PIP) {
        #Creating public IP.
        Log -Text "Creating public IP address $($PublicPublicIPName.Name)."
        Try {
            $PIP = New-AzPublicIpAddress -Name $PublicPublicIPName.Name -ResourceGroupName $RGName -Location $AzureRegion -IpAddressVersion IPv4 -Sku Standard -AllocationMethod Static -Zone $PublicPublicIPName.Zone
            $VNet = Get-AzVirtualNetwork -Name "$($Subnets | Where-Object {$_.Zone -eq "Public"} | Select-Object -Property VirtualNetwork -ExpandProperty VirtualNetwork)" -ResourceGroupName $RGName
            $Subnet = Get-AzVirtualNetworkSubnetConfig -Name "$($Subnets | Where-Object {$_.Zone -eq "Public"} | Select-Object -Property Name -ExpandProperty Name)" -VirtualNetwork $VNet
            $NIC = Get-AzNetworkInterface -Name "$($PublicPublicIPName.AssociatedTo)-eth1" -ResourceGroupName $RGName
            $NIC | Set-AzNetworkInterfaceIpConfig -Name $NIC.IpConfigurations.Name -PublicIPAddress $PIP -Subnet $Subnet | Out-Null
            $NIC | Set-AzNetworkInterface | Out-Null
            Log -Text "Public IP address $($PublicPublicIPName.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of the public IP address $($PublicPublicIPName.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        $Config = $True
        If ($PIP.ResourceGroupName -ne $RGName) {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) is not in the ressource group $($RGName). Script will exit." -Warning
        }
        If ($PIP.Location -ne $AzureRegion) {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
        }
        If ($PIP.PublicIpAddressVersion -ne "IPv4") {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) version is not IPv4. Script will exit." -Warning
        }
        If ($PIP.Sku.Name -ne "Standard") {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) sku is not standard. Script will exit." -Warning
        }
        If ($PIP.PublicIpAllocationMethod -ne "Static") {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) allocation method is not static. Script will exit." -Warning
        }
        If ($PIP.Zones -ne $PublicPublicIPName.Zone) {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) is not in zone $($PublicPublicIPName.Zone). Script will exit." -Warning
        }
        If ($PIP.IpConfiguration.Id -notmatch $PublicPublicIPName.AssociatedTo) {
            $Config = $False
            Log -Text "Public IP address $($PublicPublicIPName.Name) is not associate with the proper interface. Script will exit." -Warning
        }
        If ($Config) {
            Log -Text "Public IP address $($PublicPublicIPName.Name) already exist."
        }
        Else {
            Exit 1
        }
    }
}

#**************************************************************************************************
#Creation of the internal Load Balancer
#**************************************************************************************************

#Validating if the internal load balancer already exist.
Log -Text "Validating if the internal load balancer $($LBName) already exist."
$LB = Get-AzLoadBalancer -Name $LBName -ResourceGroupName $RGName -ErrorAction SilentlyContinue
#Getting the subnet for internal load balancer.
Log -Text "Getting the subnet for internal load balancer."
Try {
    $VNet = Get-AzVirtualNetwork -Name "$($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property VirtualNetwork -ExpandProperty VirtualNetwork)" -ResourceGroupName $RGName
    $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "$($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property Name -ExpandProperty Name)"
}
Catch {
    Log -Test "Unable to get the subnet for internal load balancer. Script will exit." -Error
    Exit 1
}
If ($Null -eq $LB) {
    #Creating all the component of the internal load balancer.
    Log -Text "Creating internal load balancer $($LBName)."
    Try {
        #Creating load balancer frontend configuration.
        $FEIP = New-AzLoadBalancerFrontendIpConfig -Name "$($LBName)-frontend" -PrivateIpAddress $LBIP -SubnetId $Subnet.id
        #Creating the backend pool onfiguration.
        $BEPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "$($LBName)-backend"
        #Associating the Palo Alto trust interface to backend pool.
        ForEach ($Firewall in $Firewalls) {
            $NIC = Get-AzNetworkInterface -Name "$($Firewall.Name)-eth2" -ResourceGroupName $RGName
            $NIC | Set-AzNetworkInterfaceIpConfig -Name $NIC.IpConfigurations.Name -LoadBalancerBackendAddressPool $BEPool | Out-Null
            $NIC | Set-AzNetworkInterface | Out-Null
        }
        #Creating the health probe to monitor login page of Palo Alto appliances.
        $Probe = New-AzLoadBalancerProbeConfig -name "$($LBName)-probe" -Port 443 -Protocol Https -RequestPath /php/login.php -IntervalInSeconds 5 -ProbeCount 5
        #Creating rule to redirect all ports to Palo Alto appliances.
        $Rule = New-AzLoadBalancerRuleConfig -Name "$($LBName)-rule" -FrontendIpConfiguration $FEIP -BackendAddressPool $BEPool -Probe $Probe -Protocol All -BackendPort 0 -FrontendPort 0
        #Creating the internal load balancer with all the configuration done previously.
        $LB = New-AzLoadBalancer -Name $LBName -ResourceGroupName $RGName -Location $AzureRegion -Sku Standard -FrontendIpConfiguration $FEIP -BackendAddressPool $BEPool -LoadBalancingRule $Rule -Probe $Probe
        Log -Text "Internal load balancer $($LBName) successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the internal load balancer $($LBName). Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
}
Else {
    $Config = $True
    #Validating general properties of internal load balancer.
    If ($LB.ResourceGroupName -ne $RGName) {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) is not in the ressource group $($RGName). Script will exit." -Warning
    }
    If ($LB.Location -ne $AzureRegion) {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
    }
    If ($LB.Sku.Name -ne "Standard") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) sku is not standard. Script will exit." -Warning
    }
    #Validating frontend IP configuration.
    If ($LB.FrontendIpConfigurations.Name -ne "$($LBName)-frontend") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) frontend configuration name is not $($LBName)-frontend. Script will exit." -Warning
    }
    If ($LB.FrontendIpConfigurations.PrivateIpAddress -ne $LBIP) {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) frontend IP address is not $($LBIP). Script will exit." -Warning
    }
    If ($LB.FrontendIpConfigurations.Subnet.Id -ne $Subnet.id) {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) frontend IP subnet ID does not match. Script will exit." -Warning
    }
    #Validating backend configuration
    If ($LB.BackendAddressPools.Name -ne "$($LBName)-backend") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) backend configuration name is not $($LBName)-backend. Script will exit." -Warning
    }
    If ($LB.BackendAddressPools.LoadBalancerBackendAddresses.Count -ne $Firewalls.Count) {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) backend configuration contain too much destination addresses. Script will exit." -Warning
    }
    Else {
        ForEach ($Firewall in $Firewalls) {
            If (($LB.BackendAddressPools.LoadBalancerBackendAddresses | Select-Object Name -ExpandProperty Name) -notcontains "$($RGname)_$($Firewall.Name)-eth2ipconfig-trust") {
                $Config = $False
                Log -Text "Internal load balancer $($LBName) backend configuration does not contain $($Firewall.Name)-eth2. Script will exit." -Warning
            }
        }
    }
    #Validating probe
    If ($LB.Probes.Name -ne "$($LBName)-probe") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) probe configuration name is not $($LBName)-probe. Script will exit." -Warning
    }
    If ($LB.Probes.Port -ne "443") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) probe port is not 443. Script will exit." -Warning
    }
    If ($LB.Probes.Protocol -ne "Https") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) probe protocol is not HTTPS. Script will exit." -Warning
    }
    If ($LB.Probes.RequestPath -ne "/php/login.php") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) probe request path is not /php/login.php. Script will exit." -Warning
    }
    If ($LB.Probes.IntervalInSeconds -ne "5") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) probe interval in seconds is not 5. Script will exit." -Warning
    }
    If ($LB.Probes.NumberOfProbes -ne "5") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) probe number Of probes is not 5. Script will exit." -Warning
    }
    #validating rule
    If ($LB.LoadBalancingRules.Name -ne "$($LBName)-rule") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) rule configuration name is not $($LBName)-rule. Script will exit." -Warning
    }
    If ($LB.LoadBalancingRules.FrontendIPConfiguration.Id -notmatch "$($LBName)-frontend") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) rule frontend configuration name is not $($LBName)-frontend. Script will exit." -Warning
    }
    If ($LB.LoadBalancingRules.BackendAddressPool.Id -notmatch "$($LBName)-backend") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) rule backend configuration name is not $($LBName)-backend. Script will exit." -Warning
    }
    If ($LB.LoadBalancingRules.Probe.Id -notmatch "$($LBName)-probe") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) rule probe configuration name is not $($LBName)-probe. Script will exit." -Warning
    }
    If ($LB.LoadBalancingRules.Protocol -ne "All") {
        $Config = $False
        Log -Text "Internal load balancer $($LBName) rule protocol is not all. Script will exit." -Warning
    }
    If ($Config) {
        Log -Text "Public IP address $($PublicPublicIPName.Name) already exist."
    }
    Else {
        Exit 1
    }
    Log -Text "Internal load balancer $($LBName) already exist."
}

#**************************************************************************************************
#Creation of the routing table for trust subnet
#**************************************************************************************************

#Validating if the routing table already exist.
Log -Text "Validating if the routing table $($RTName) already exist."
$RT = Get-AzRouteTable -ResourceGroupName $RGName -Name $RTName -ErrorAction SilentlyContinue
#Getting the subnet for route table.
Log -Text "Getting the subnet for the route table."
Try {
    $VNet = Get-AzVirtualNetwork -Name "$($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property VirtualNetwork -ExpandProperty VirtualNetwork)" -ResourceGroupName $RGName
    $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "$($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property Name -ExpandProperty Name)"
}
Catch {
    Log -Test "Unable to get the subnet for route table. Script will exit." -Error
    Exit 1
}
If ($Null -eq $RT) {
    #Creating routing table for trust subnet.
    Log -Text "Creating routing table $($RTName) for trust subnet."
    Try {
        $Route = New-AzRouteConfig -Name "Default" -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $LBIP
        $RT = New-AzRouteTable -Name $RTName -ResourceGroupName $RGName -Location $AzureRegion -Route $Route

        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -AddressPrefix "$($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property AddressPrefix -ExpandProperty AddressPrefix)" -Name "$($Subnets | Where-Object {$_.Zone -eq "Private"} | Select-Object -Property Name -ExpandProperty Name)" -RouteTable $RT | Out-Null
        $VNet | Set-AzVirtualNetwork | Out-Null
        Log -Text "Routing table $($RTName) for trust subnet successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the routing table $($RTName) for trust subnet. Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        #Exit 1
    }

}
Else {
    $Config = $True
    If ($RT.ResourceGroupName -ne $RGName) {
        $Config = $False
        Log -Text "Route table $($RTName) is not in the ressource group $($RGName). Script will exit." -Warning
    }
    If ($RT.Location -ne $AzureRegion) {
        $Config = $False
        Log -Text "Route table $($RTName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
    }
    $RouteExist = $False
    ForEach ($Routes in $RT.Routes) {
        If ($Routes.AddressPrefix -eq "0.0.0.0/0" -and $Route.NextHopType -eq "VirtualAppliance" -and $Route.NextHopIpAddress -eq $LBIP) {
            $RouteExist = $True
        }
    }
    If (!($RouteExist)) {
        $Config = $False
        Log -Text "Route table $($RTName) does not contain the appropriate route. Script will exit." -Warning
    }
    If ($Subnet.RouteTable.Id -notmatch $RT.Name) {
        $Config = $False
        Log -Text "Route table $($RTName) is not associate to $($Subnet.Name). Script will exit." -Warning
    }
    If ($Config) {
         Log -Text "Routing table $($RTName) for trust subnet already exist."
    }
    Else {
        Exit 1
    }
}

