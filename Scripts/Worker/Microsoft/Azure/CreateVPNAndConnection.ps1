<#
**********************************************************************************
Script to create Microsoft Azure virtual network and VPN
**********************************************************************************

.SYNOPSIS
Script to create Microsoft Azure virtual network and VPN.

Version 1.0 of this script.

.DESCRIPTION
This script is use to create Microsoft virtual network and VPN. 

This script use Microsoft AZ PowerShell module.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./Microsoft_Azure_Subnet-VPN_Hub.ps1 
./Microsoft_Azure_Subnet-VPN_Hub.ps1  -debug
./Microsoft_Azure_Subnet-VPN_Hub5.ps1  -output

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

#Virtual network
$Vnets = @(
    New-Object PSObject -Property @{Name = ""; AddressPrefix = ""}
)

#Subnet
#Name must be GatewaySubnet.
$Subnets = @(
    New-Object PSObject -Property @{Name = "GatewaySubnet"; AddressPrefix = ""; VirtualNetwork = ""}
)

#Name of the public IP
$PIPName = ""

#Virtual gateway name
$VirtualGatewayName = ""

#Virtual gateway sku
#See for Sku (https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways)
$VirtualGatewaySku = "VpnGw2AZ"

#Virtual gateway generation (Generation1 or Generation2)
$VirtualGatewayGeneration = "Generation2"

#BGP ASN number for virtual network gateway
#Leave it empty if BGP is not required.
$VirtualGatewayASN = ""

#Local gateway name
$LocalGatewayName = ""

#Local gateway IP address
$LocalGatewayIP = ""

#BGP ASN number for virtual network gateway
#Leave it empty if BGP is not required.
$LocalGatewayASN = ""

#Local address prefix
#If you use BGP, it's must be the IP address of the peer.
$LocalAddressPrefix = ""

#VPN connexion name
$VPNConnexionName = ""

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
        Exit
    }
    #Validating if subnet already exist.
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
            Log -Text "Subnet $($Subnet.Name) does not have the address prefix $($Vnet.AddressPrefix)." -Warning
        }
        Else {
            Log -Text "Subnet $($Subnet.Name) already exist."
        }
    }
}

#**************************************************************************************************
#Creation of the public IP address
#**************************************************************************************************    

#Validating if the public IP address already exist.
Log -Text "Validating if the public IP address already exist."
$PIP = Get-AzPublicIpAddress -Name $PIPName -ErrorAction SilentlyContinue
If ($Null -eq $PIP) {
    #Creating public IP.
    Log -Text "Creating public IP $($PIPName)."
    Try {
        If ($GatewaySku -match "VpnGw[0-9]AZ") {
            $PIP = New-AzPublicIpAddress -Name $PIPName -ResourceGroupName $RGName -Location $AzureRegion -IpAddressVersion IPv4 -Sku Standard -AllocationMethod Static -Zone 1,2,3
        }
        Else {
            $PIP = New-AzPublicIpAddress -Name $PIPName -ResourceGroupName $RGName -Location $AzureRegion -IpAddressVersion IPv4 -Sku Standard -AllocationMethod Static
        }
        Log -Text "Public IP $($PIPName) successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the public IP $($PIPName). Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
}
Else {
    $Config = $True
    If ($PIP.ResourceGroupName -ne $RGName) {
        $Config = $False
        Log -Text "Public IP address $($PIPName) is not in the Ressource Group $($RGName). Script will exit." -Warning
    }
    If ($PIP.Location -ne $AzureRegion) {
        $Config = $False
        Log -Text "Public IP address $($PIPName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
    }
    If ($PIP.PublicIpAddressVersion -ne "IPv4") {
        $Config = $False
        Log -Text "Public IP address $($PIPName) version is not IPv4. Script will exit." -Warning
    }
    If ($PIP.Sku.Name -ne "Standard") {
        $Config = $False
        Log -Text "Public IP address $($PIPName) sku is not standard. Script will exit." -Warning
    }
    If ($PIP.PublicIpAllocationMethod -ne "Static") {
        $Config = $False
        Log -Text "Public IP address $($PIPName) allocation method is not static. Script will exit." -Warning
    }
    If ($Config) {
        Log -Text "Public IP address $($PIPName) already exist."
    }
    Else {
        Exit 1
    }
}

#**************************************************************************************************
#Creation of the virtual network gateway
#************************************************************************************************** 

#Validating if the virtual network gateway already exist.
Log -Text "Validating if the virtual network gateway already exist."
$VirtualNetworkGateway = Get-AzVirtualNetworkGateway -Name $VirtualGatewayName -ResourceGroupName $RGName -ErrorAction SilentlyContinue
#Getting required object properties to be able to create virtuel network gateway.
Log -Text "Getting required object properties to be able to create virtuel network gateway."
Try{
    $VNet = Get-AzVirtualNetwork -Name $Vnets[0].Name
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $Subnets[0].Name -VirtualNetwork $VNet
    $PIP = Get-AzPublicIpAddress -Name $PIPName
}
Catch {
        Log -Text "An error occurred during the validation of the objects required to create the virtual network gateway. Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
}
If ($Null -eq $VirtualNetworkGateway) {
    #Creating virtual network gateway.
    Log -Text "Creating virtual network gateway."
    Try {
        $IPConfig = New-AzVirtualNetworkGatewayIpConfig -Name "VirtualNetworkGatewayIPConfig" -SubnetId $Subnet.Id -PublicIpAddressId $PIP.Id
        If ($Null -ne $VirtualGatewayASN) {
            $VirtualNetworkGateway = New-AzVirtualNetworkGateway -Name $VirtualGatewayName -ResourceGroupName $RGName -Location $AzureRegion -IpConfigurations $IPConfig  -GatewayType "Vpn" -VpnType "RouteBased" -GatewaySku $VirtualGatewaySku -VpnGatewayGeneration $VirtualGatewayGeneration -EnableBgp $True  -ASN $VirtualGatewayASN 
        }
        Else {
            $VirtualNetworkGateway = New-AzVirtualNetworkGateway -Name $VirtualGatewayName -ResourceGroupName $RGName -Location $AzureRegion -IpConfigurations $IPConfig  -GatewayType "Vpn" -VpnType "RouteBased" -GatewaySku $VirtualGatewaySku -VpnGatewayGeneration $VirtualGatewayGeneration
        }
        Log -Text "Virtual network gateway $($VirtualGatewayName) successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the virtual network gateway $($VirtualGatewayName)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
}
Else {
    $Config = $True
    If ($VirtualNetworkGateway.ResourceGroupName -ne $RGName) {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) is not in the ressource group $($RGName). Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.Location -ne $AzureRegion) {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.IpConfigurations.PublicIpAddress.Id -ne $PIP.Id) {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) public IP address is not $($PIPName). Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.IpConfigurations.Subnet.Id -ne $Subnet.Id) {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) subnet is not $($Subnets[0].Name). Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.VpnType -ne "RouteBased") {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) vpn type is not route based. Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.GatewayType -ne "Vpn") {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) gateway type is not VPN. Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.Sku.Name -ne $VirtualGatewaySku) {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) sku is not $($VirtualGatewaySku). Script will exit." -Warning
    }
    If ($VirtualNetworkGateway.VpnGatewayGeneration -ne $VirtualGatewayGeneration) {
        $Config = $False
        Log -Text "Virtual network gateway $($VirtualGatewayName) generation is not $($VirtualGatewayGeneration). Script will exit." -Warning
    }
    If ($Null -ne $VirtualGatewayASN) {
        If (!($VirtualNetworkGateway.EnableBgp)) {
            $Config = $False
            Log -Text "Virtual network gateway $($VirtualGatewayName) does not have BGP enabled. Script will exit." -Warning
        }
        If ($VirtualNetworkGateway.BgpSettings.Asn -ne $VirtualGatewayASN) {
            $Config = $False
            Log -Text "Virtual network gateway $($VirtualGatewayName) ASN number is not $($VirtualGatewayASN). Script will exit." -Warning
        }
    }
    If ($Config) {
        Log -Text "Virtual network gateway $($VirtualGatewayName) already exist."
    }
    Else {
        Exit 1
    }
}

#**************************************************************************************************
#Creation local network gateway
#************************************************************************************************** 

#Validating if the local network gateway already exist.
Log -Text "Validating if the local network gateway already exist."
$LocalNetworkGateway = Get-AzLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $RGName -ErrorAction SilentlyContinue
If ($Null -eq $LocalNetworkGateway) {
    #Creating local network gateway.
    Log -Text "Creating local network gateway."
    Try {
        If ($Null -ne $LocalGatewayASN) {
            $LocalNetworkGateway = $LocalGateway = New-AzLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $RGName -Location $AzureRegion -GatewayIpAddress $LocalGatewayIP -AddressPrefix $LocalAddressPrefix -Asn $LocalGatewayASN -BgpPeeringAddress "$($LocalAddressPrefix.Split("/") | Select-Object -First 1)"
        }
        Else {
            $LocalNetworkGateway = $LocalGateway = New-AzLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $RGName -Location $AzureRegion -GatewayIpAddress $LocalGatewayIP -AddressPrefix $LocalAddressPrefix
        }
        Log -Text "Local network gateway $($LocalGatewayName) successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the local network gateway $($LocalGatewayName)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
}
Else {
    $Config = $True
    If ($LocalNetworkGateway.ResourceGroupName -ne $RGName) {
        $Config = $False
        Log -Text "Local network gateway $($LocalGatewayName) is not in the ressource group $($RGName). Script will exit." -Warning
    }
    If ($LocalNetworkGateway.Location -ne $AzureRegion) {
        $Config = $False
        Log -Text "Local network gateway $($LocalGatewayName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
    }
    If ($LocalNetworkGateway.GatewayIpAddress -ne $LocalGatewayIP) {
        $Config = $False
        Log -Text "Local network gateway $($LocalGatewayName) IP address is not $($LocalGatewayIP). Script will exit." -Warning
    }
    If ($Null -ne $LocalGatewayASN) {
        If ($LocalNetworkGateway.BgpSettings.ASN -ne $LocalGatewayASN) {
            $Config = $False
            Log -Text "Local network gateway $($LocalGatewayName) ASN number is not $($LocalGatewayASN). Script will exit." -Warning
        }
        If ($LocalNetworkGateway.BgpSettings.BgpPeeringAddress -ne "$($LocalAddressPrefix.Split("/") | Select-Object -First 1)") {
            $Config = $False
            Log -Text "Local network gateway $($LocalGatewayName) BGP peer is not $($LocalAddressPrefix.Split("/") | Select-Object -First 1). Script will exit." -Warning
        }
    }
    If ($Config) {
        Log -Text "Virtual network gateway $($VirtualGatewayName) already exist."
    }
    Else {
        Exit 1
    }
}

#**************************************************************************************************
#Creation virtual network connection
#************************************************************************************************** 

#Validating if the virtual network connection already exist.
Log -Text "Validating if the virtual network connection already exist."
$VirtualNetworkConnection = Get-AzVirtualNetworkGatewayConnection -Name $VPNConnexionName -ResourceGroupName $RGName -ErrorAction SilentlyContinue
#Getting required object properties to be able to create virtuel network connection.
Log -Text "Getting required object properties to be able to create virtuel network connection."
Try{
    $LocalNetworkGateway = Get-AzLocalNetworkGateway -Name $LocalGatewayName -ResourceGroupName $RGName
    $VirtualNetworkGateway = Get-AzVirtualNetworkGateway -Name $VirtualGatewayName -ResourceGroupName $RGName
}
Catch {
        Log -Text "An error occurred during the validation of the objects required to create the virtual network connection. Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
}
If ($Null -eq $VirtualNetworkConnection) {
    #Creating virtual network connection.
    Log -Text "Creating virtual network connection."
    Try {
        If ($Null -ne $LocalGatewayASN) {
            $VirtualNetworkConnection = New-AzVirtualNetworkGatewayConnection -Name $VPNConnexionName -ResourceGroupName $RGName -Location $AzureRegion -VirtualNetworkGateway1 $VirtualNetworkGateway -LocalNetworkGateway2 $LocalNetworkGateway -ConnectionType IPsec -SharedKey $SharedKey -EnableBgp $True
        }
        Else {
            $VirtualNetworkConnection = New-AzVirtualNetworkGatewayConnection -Name $VPNConnexionName -ResourceGroupName $RGName -Location $AzureRegion -VirtualNetworkGateway1 $VirtualNetworkGateway -LocalNetworkGateway2 $LocalNetworkGateway -ConnectionType IPsec -SharedKey $SharedKey 
        }
        Log -Text "Virtual network connection $($VPNConnexionName) successfully created."
    }
    Catch {
        Log -Text "An error occurred during the creation of the virtual network connection $($LocalGatewayName)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
}
Else {
    $Config = $True
    If ($VirtualNetworkConnection.ResourceGroupName -ne $RGName) {
        $Config = $False
        Log -Text "Virtual network connection $($VPNConnexionName) is not in the ressource group $($RGName). Script will exit." -Warning
    }
    If ($VirtualNetworkConnection.Location -ne $AzureRegion) {
        $Config = $False
        Log -Text "Virtual network connection $($VPNConnexionName) is not in the Microsoft Azure region $($AzureRegion). Script will exit." -Warning
    }
    If ($VirtualNetworkConnection.ConnectionType -ne "IPsec") {
        $Config = $False
        Log -Text "Virtual network connection $($VPNConnexionName) connection type is not IPSEC. Script will exit." -Warning
    }
    If ($VirtualNetworkConnection.SharedKey -ne $SharedKey) {
        $Config = $False
        Log -Text "Virtual network connection $($VPNConnexionName) shared key is not the right one. Script will exit." -Warning
    }
    If ($VirtualNetworkConnection.VirtualNetworkGateway1.Id -ne $VirtualNetworkGateway.Id) {
        $Config = $False
        Log -Text "Virtual network connection $($VPNConnexionName) virtual network gateway is not the right one. Script will exit." -Warning
    }
    If ($VirtualNetworkConnection.LocalNetworkGateway2.Id -ne $LocalNetworkGateway.Id) {
        $Config = $False
        Log -Text "Virtual network connection $($VPNConnexionName) local network gateway is not the right one. Script will exit." -Warning
    }
    If ($Null -ne $LocalGatewayASN) {
        If (!($VirtualNetworkConnection.EnableBgp)) {
            $Config = $False
            Log -Text "Virtual network connection $($VPNConnexionName) does not have BGP enabled. Script will exit." -Warning
        }
    }
    If ($Config) {
        Log -Text "Virtual network gateway $($VirtualGatewayName) already exist."
    }
    Else {
        Exit 1
    }
}
