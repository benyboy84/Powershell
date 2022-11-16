<#
**********************************************************************************
Script to create Microsoft Azure virtual network(s) and subnet(s)
**********************************************************************************

.SYNOPSIS
Script to create Microsoft Azure virtual network(s) and subnet(s).

NOTE:
This script will not cover Bastion, DDoS or Firewall. 
    Things that can be configured during a virtual network creation.

VERSION:
1.0
    First version.
2.0
    Add validation for virtual network and subnet properties.
2.1
    Refactoring of the script.

.DESCRIPTION
This script is use to create Microsoft Azure virtual network(s) and subnet(s). 

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
    [String]$Output = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

#Virtual network
$VirtualNetworks = @(
    New-Object PSObject -Property @{Subscription = "hub-prod-001"; ResourceGroup = "rg-hub-prod-001"; Name = "vnet-hub-cac-001"; Region = "canadacentral"; AddressPrefix = "10.0.0.0/16"}
)

#Subnet
#Subnet names are reserved by Microsoft such as: GatewaySubnet, AzureBastionSubnet
#Virtual network must be declared above.
#Comment object if no subnet is required.
$Subnets = @(
    New-Object PSObject -Property @{VirtualNetwork = "vnet-hub-cac-001"; Name = "GatewaySubnet"; AddressPrefix = "10.0.0.0/27";}
    New-Object PSObject -Property @{VirtualNetwork = "vnet-hub-cac-001"; Name = "snet-dns-cac-001"; AddressPrefix = "10.0.0.32/28";}
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

#Creating the log file if $Output parameter is set to TRUE.
If ($Output) {
    #Getting the location of the script.
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    #Getting the file name and extension by splitting the path with "\" character.
    $ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
    #Getting the file name by splitting the with "." character.
    $ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
    #Getting the date and time of the script execution.
    $TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
    #Combining the location of the script, the name of the script and the timestamp to create he log file.
    $Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
}

# **********************************************************************************

Log -Text "Script begin."

# **********************************************************************************

#The Update-AzConfig cmdlet is used to disable the survey message.
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null

#**************************************************************************************************
#Az PowerShell module installation
#************************************************************************************************** 

Log -Text "Validating if Azure module is installed."
$InstalledModule = Get-InstalledModule -Name Az -AllVersions -ErrorAction SilentlyContinue
#If the value of the $InstalledModule variable equals $Null, this indicates that the module is not installed. 
If ($Null -eq $InstalledModule) {
    Log -Text "Microsoft Azure PowerShell module is not install." 
    Log -Text "Installing PowerShell Module..."
    Try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    }
    Catch {
        Log -Text "Unable to install Azure PowerShell module." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error 
        Log -Text "Script will exit." -Error
        Exit 1 
    }
    Log -Text "Microsoft Azure PowerShell module successfully installed."
}
Else {
    Log -Text "Microsoft Azure PowerShell module is installed."
}

#**************************************************************************************************
#Connecting to Microsoft Azure
#************************************************************************************************** 

Log -Text "Connecting to Microsoft Azure..."
Try {
    Connect-AzAccount | Out-Null
}
Catch{
    Log -Text "Unable to login into Microsoft Azure." -Error
    Log -Text "Error:$($PSItem.Exception.Message)" -Error 
    Log -Text "Script will exit." -Error
    Exit 1 
}
Log -Text "Successfully connected to Microsoft Azure."
    
#**************************************************************************************************
#Creation of the virtual network(s)
#**************************************************************************************************

Log -Text "Creating virtual network(s)..."
ForEach ($VirtualNetwork in $VirtualNetworks) {
    Log -Text "Validating if subscription $($VirtualNetwork.Subscription) exist."
    Try {
        $AzSubscription = Get-AzSubscription -SubscriptionName $VirtualNetwork.Subscription
    }
    Catch {
        Log -Text "Subscription $($VirtualNetwork.Subscription) does not exist." -Error
        Log -Text "It will not be possible to validate or create the virtual network $($VirtualNetwork.Name)." -Error
        Continue
    }
    Log -Text "Setting the subscription $($VirtualNetwork.Subscription)..."
    Try {
        Set-AzContext -Subscription $AzSubscription | Out-Null
    }
    Catch {
        Log -Text "Unable to set the subscription $($VirtualNetwork.Subscription)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error 
        Log -Text "It will not be possible to validate or create the virtual network $($VirtualNetwork.Name)." -Error
        Continue 
    }
    Log -Text "Subscription $($VirtualNetwork.Subscription) is now selected."
    Log -Text "Validating if virtual network $($VirtualNetwork.Name) exist."
    $AzVirtualNetwork = Get-AzVirtualNetwork -Name $VirtualNetwork.Name -ErrorAction SilentlyContinue
    #If the value of the $AzVirtualNetwork variable equals $Null, this indicates that the virtual network does not exist.
    If ($Null -eq $AzVirtualNetwork) {
        Log -Text "Validating if resource group $($VirtualNetwork.ResourceGroup) exist."
        $AzResourceGroup = Get-AzResourceGroup -Name $VirtualNetwork.ResourceGroup -ErrorAction SilentlyContinue
        #If the value of the $AzResourceGroup variable equals $Null, this indicates that the resource group does not exist.
        #It is not possible to create a virtual network without a valid resource group.
        If ($Null -ne $AzResourceGroup) {
            Log -Text "Creating the virtual network $($VirtualNetwork.Name)..."
            Try {
                New-AzVirtualNetwork -ResourceGroupName $VirtualNetwork.ResourceGroup -Location $VirtualNetwork.Region -Name $VirtualNetwork.Name  -AddressPrefix $VirtualNetwork.AddressPrefix | Out-Null
            }
            Catch {
                Log -Text "An error occurred during the creation of the virtual network $($VirtualNetwork.Name)." -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                Continue
            }
            Log -Text "Virtual network $($VirtualNetwork.Name) successfully created."
        }
        Else {
            Log -Text "Resource group $($VirtualNetwork.ResourceGroup) does not exist." -Error
            Log -Text "It is not be possible to create the virtual network $($VirtualNetwork.Name) without a valid resource group." -Error
        }
    }
    Else {
        Log -Text "Virtual network $($VirtualNetwork.Name) exist."
        $Config = $True
        If ($AzVirtualNetwork.ResourceGroupName -ne $VirtualNetwork.ResourceGroup) {
            $Config = $False
            Log -Text "Virtual network $($VirtualNetwork.Name) is not in the ressource group $($VirtualNetwork.ResourceGroup)." -Warning
        }
        If ($AzVirtualNetwork.Location -ne $VirtualNetwork.Region) {
            $Config = $False
            Log -Text "Virtual network $($VirtualNetwork.Name) is not in the Microsoft Azure region $($VirtualNetwork.Region)." -Warning
        }
        If ($AzVirtualNetwork.AddressSpace.AddressPrefixes -ne $VirtualNetwork.AddressPrefix) {
            $Config = $False
            Log -Text "Virtual network $($VirtualNetwork.Name) does not have the address prefix $($VirtualNetwork.AddressPrefix)." -Warning
        }
        If ($Config) {
            Log -Text "Virtual network $($VirtualNetwork.Name) is properly configured."
        }
    }
}

#**************************************************************************************************
#Creation of the subnet(s)
#**************************************************************************************************

Log -Text "Creating subnet(s)..."
ForEach ($Subnet in $Subnets) {
    Log -Text "Getting the subscription for the virtual network $($Subnet.VirtualNetwork)."
    $Subscription = $VirtualNetworks | Where-Object {$_.Name -eq $Subnet.VirtualNetwork} | Select -Property Subscription -ExpandProperty Subscription
    #If the value of the $Subscription variable equals $Null, this indicates that the virtual network is not declared in the mandatory manual configuration section.
    If ($Null -eq $Subscription) {
        Log -Text "Unable to get the subscription name for the virtual network $($Subnet.VirtualNetwork)." -Error
        Log -Text "It will not be possible to validate or create the subnet $($Subnet.Name)." -Error
        Continue
    }
    Else {
        Log -Text "Validating if subscription $($Subscription) exist."
        Try {
            $AzSubscription = Get-AzSubscription -SubscriptionName $Subscription
        }
        Catch {
            Log -Text "Subscription $($Subscription) does not exist." -Error
            Log -Text "It will not be possible to validate or create the subnet $($Subnet.Name)." -Error
            Continue
        }
        Log -Text "Setting the subscription $($Subscription)..."
        Try {
            Set-AzContext -Subscription $AzSubscription | Out-Null
        }
        Catch {
            Log -Text "Unable to set the subscription $($Subscription)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error 
            Log -Text "It will not be possible to validate or create the subnet $($Subnet.Name)." -Error
            Continue 
        }
        Log -Text "Subscription $($Subscription) is now selected."
    }    
    Log -Text "Getting the virtual network for subnet $($Subnet.Name)."
    $AzVirtualNetwork = Get-AzVirtualNetwork -Name $Subnet.VirtualNetwork
    #If the value of the $AzVirtualNetwork variable equals $Null, this indicates that the virtual network does not exist.
    If ($Null -eq $AzVirtualNetwork) {
        Log -Text "Unable to get the virtual network $($Subnet.VirtualNetwork) for subnet $($Subnet.Name)." -Error
        Log -Text "It will not be possible to validate or create the subnet $($Subnet.Name)." -Error
        Continue
    }
    Log -Text "Validating if subnet $($Subnet.Name) exist."
    $AzVirtualNetworkSubnetConfig = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $AzVirtualNetwork -Name $Subnet.Name -ErrorAction SilentlyContinue
    If ($Null -eq $AzVirtualNetworkSubnetConfig) {
        Log -Text "Creating subnet $($Subnet.Name)..."
        Try {
            Add-AzVirtualNetworkSubnetConfig -Name $Subnet.Name -AddressPrefix $Subnet.AddressPrefix -VirtualNetwork $AzVirtualNetwork | Out-Null
            $AzVirtualNetwork | Set-AzVirtualNetwork | Out-Null
        }
        Catch {
            Log -Text "An error occurred during the creation of subnet $($Subnet.Name)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Continue
        }
        Log -Text "Subnet $($Subnet.Name) successfully created."
    }
    Else {
        Log -Text "Subnet $($Subnet.Name) exist."
        If ($AzVirtualNetworkSubnetConfig.AddressPrefix -ne $Subnet.AddressPrefix) {
            Log -Text "Subnet $($Subnet.Name) does not have the address prefix $($Subnet.AddressPrefix)." -Warning
        }
        Else {
            Log -Text "Subnet $($Subnet.Name) is properly configured."
        }
    }
}