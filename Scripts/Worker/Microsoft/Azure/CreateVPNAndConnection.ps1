<#
**********************************************************************************
Script to create Microsoft Azure VPN and connection
**********************************************************************************

.SYNOPSIS
Script to create Microsoft Azure VPN and connection.

Version 1.0 of this script.

.DESCRIPTION
This script is use to create Microsoft VPN and connection. 

This script use Microsoft AZ PowerShell module.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./CreateVPNAndConnection.ps1 
./CreateVPNAndConnection.ps1  -debug
./CreateVPNAndConnection.ps1  -output
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

#Microsoft Azure Region
$AzureRegion = "canadacentral"

#Microsoft Azure Subscription
$Subscription = "Abonnement"

#Ressource group name
$RGName = "rg-hub-cac-001"

#Virtual networks
$Vnets = @(
    New-Object PSObject -Property @{Name = "net-hub-cac-001"; AddressPrefix = "10.1.0.0/16"}
)

#Subnets
#Name must be GatewaySubnet.
$Subnets = @(
    New-Object PSObject -Property @{Name = "GatewaySubnet"; AddressPrefix = "10.1.0.0/27"; VirtualNetwork = "net-hub-cac-001"}
)

#Name of the public IP
$PIPName = "pip-vpng-cac-001"

#VPN Gateway Name
$GatewayName = "vpng--cac-001"

#VPN Gateway Sku
$GatewaySku = "VpnGw2AZ"

#VPN Gateway Generation
$VpnGatewayGeneration = "Generation2" 

#BGP ASN number
$ASN = ""



#Local gateway name
$LocalGatewayName = "lgw--cac-001"

#Local gateway IP address
$LocalGatewayIP = ""

#Local address prefix
$AddressPrefix = ""



#VPN connexion name
$VPNConnexion = "vnc--cac-001"

#Shared Key
$SharedKey = ""

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

#The Update-AzConfig cmdlet is used to disable the survey message.
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null

Log -Text "Script begin."

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

#Connecting to Microsoft Azure.
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
    
#Validating if ressource group already exist.
Log -Text "Validating if ressource group already exist."
$AzResourceGroup = Get-AzResourceGroup -Name $RGName -ErrorAction SilentlyContinue

If ($Null -eq $AzResourceGroup) {
    #Creating the ressource group for network object.
    Log -Text "Creating ressourge group for network object."
    Try {
        $RG = New-AzResourceGroup -Name $RGName -Location $AzureRegion
        Log -Text "Ressourge group $($RGName) successfully created."
    }
    Catch {
        Log -Text "Unable to create ressource group for network object. Script will exit." -Error
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

#Creating Virtual networks.
ForEach ($VNet in $VNets) {
    #Validating if virtual network with the same name already exist.
    Log -Text "Validating if virtual network with the same name already exist."
    $AzVirtualNetwork = Get-AzVirtualNetwork -Name $VNet.Name -ErrorAction SilentlyContinue

    If ($Null -eq $AzVirtualNetwork) {
        #Creating Virtual network.
        Log -Text "Creating VNet $($Vnet.Name)."
        Try {
            New-AzVirtualNetwork -Name $Vnet.Name -ResourceGroupName $RGName -Location $AzureRegion -AddressPrefix $Vnet.AddressPrefix | Out-Null
            Log -Text "VNet $($Vnet.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of VNet $($Vnet.Name)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        $Config = $True
        If ($AzVirtualNetwork.AddressSpace.AddressPrefixes -ne $VNet.AddressPrefix) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) does not have the address prefixes $($Vnet.AddressPrefix). Script will exit." -Warning
        }
        If ($AzVirtualNetwork.Location -ne $AzureRegion) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
        }
        If ($Config) {
            Log -Text "Virtual network $($Vnet.Name) already exist."
        }
        Else {
            Exit 1
        }
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
        Log -Test "Unable to get the virtual network for subnet $($Subnet.Name)." -Error
        Continue
    }
    #Validating if subnet with the same name already exist.
    Log -Text "Validating if subnet with the same name already exist."
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
            Log -Text "An error occurred during the creation of subnet $($Subnet.Name)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
        }
    }
    Else {
        If ($AzVirtualNetworkSubnetConfig.AddressPrefix -ne $Subnet.AddressPrefix) {
            $Config = $False
            Log -Text "Subnet $($Subnet.Name) does not have the address prefix $($Vnet.AddressPrefix)." -Warning
        }
        Else {
            Log -Text "Subnet $($Subnet.Name) already exist."
        }
    }
}


  

#Creating the public IP address
#Validating if the public IP address already exist.
Log -Text "Validating if the public IP address already exist."
$PIP = Get-AzPublicIpAddress -Name $PIPName -ErrorAction SilentlyContinue
If ($Null -eq $PIP) {
    #Creating public IP.
    Log -Text "Creating public IP $($PIPName)."
    Try {
        If ($GatewaySku -match "VpnGw[0-9]AZ") {
            $PIP = New-AzPublicIpAddress -Name $PIPName -ResourceGroupName $RGName -Location $AzureRegion -IpAddressVersion IPv4 -Sku Standard -AllocationMethod Static -Zone 2
        }
        Else {
            $PIP = New-AzPublicIpAddress -Name $PIPName -ResourceGroupName $RGName -Location $AzureRegion -IpAddressVersion IPv4 -Sku Standard -AllocationMethod Static
        }
        Log -Text "Public IP $($PIPName) successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the public IP $($NVALBName)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
    }
}
Else {
    Log -Text "A public IP with the same name already exist." -Warning
}


$VNet = Get-AzVirtualNetwork -Name $Vnets[0].Name
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $Subnets[0].Name -VirtualNetwork $VNet
$IPConfig = New-AzVirtualNetworkGatewayIpConfig -Name "GatewayIPConfig" -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
$VPNGateway = New-AzVirtualNetworkGateway -Name $GatewayName -ResourceGroupName $RGName -Location $AzureRegion -IpConfigurations $IPConfig  -GatewayType "Vpn" -VpnType "RouteBased" -GatewaySku $GatewaySku -ASN $ASN -VpnGatewayGeneration Generation2

$LocalGateway = New-AzLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $RGName -Location $AzureRegion -GatewayIpAddress $LocalGatewayIP -AddressPrefix $AddressPrefix

$GATEWAY = Get-AzVirtualNetworkGateway -Name $GatewayName -ResourceGroupName $RGName
$LOCAL = Get-AzLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $RGName
New-AzVirtualNetworkGatewayConnection -Name $VPNConnexion -ResourceGroupName $RGName -Location $AzureRegion -VirtualNetworkGateway1 $GATEWAY -LocalNetworkGateway2 $LOCAL -ConnectionType IPsec -SharedKey $SharedKey


New-AzVirtualNetworkGateway -Name "Test" -ResourceGroupName $RGName -Location $AzureRegion -IpConfigurations $IPConfig -GatewayType Vpn -VpnType RouteBased -