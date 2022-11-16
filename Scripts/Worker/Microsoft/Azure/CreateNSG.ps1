<#
**********************************************************************************
Script to create and assign Microsoft Azure network security group(s)
**********************************************************************************

.SYNOPSIS
Script to create and assign Microsoft Azure network security group(s).

NOTE:
This script will not cover NIC assignment. 

VERSION:
1.0
    First version.

.DESCRIPTION
This script is use to create and assign Microsoft Azure virtual network security group(s). 

This script use Microsoft AZ PowerShell module.

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

.EXAMPLE
./CreateNSG.ps1 
./CreateNSG.ps1  -debug
./CreateNSG.ps1  -output

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

#Network security group(s)
$NetworkSecurityGroups = @(
    New-Object PSObject -Property @{Subscription = "hub-prod-001"; ResourceGroup = "rg-hub-prod-001"; Name = "nsg-snet-dns-cac-001"; Region = "canadacentral";}
)

#Network security rule(s)
#Network security group must be declared above.
#Allowed value:
# - Name: Must be unique for the network security group
# - Access: Allow or Deny
# - Direction: Inbound, Outbound
# - Priority: 1 to 4096 and must be unique for the inbound security rules or for the outboud security rules
# - Protocol: Ah, Esp, Icmp, Tcp, Udp
# - SourceAddressPrefix: can be a valid address prefix, "*" for ANY or a valid tag like Internet, VirtualNetwork, AzureLoadBalancer...
# - SourcePortRange: must be written with format 443 or (80,443)
# - DestinationAddressPrefix: ccan be a valid address prefix, "*" for ANY or a valid tag like Internet, VirtualNetwork, AzureLoadBalancer...
# - DestinationPortRange: must be written with format 443 or (80,443)
#Comment object if no subnet is required.
$SecurityRules = @(
    New-Object PSObject -Property @{NetworkSecurityGroup = "nsg-snet-dns-cac-001"; Name = "AllowDNS"; Description = "Allow DNS UDP 53"; Access = "Allow"; Direction = "Inbound"; Priority = "1100"; Protocol = "UDP"; SourceAddressPrefix = "*"; SourcePortRange = "*"; DestinationAddressPrefix = "VirtualNetwork"; DestinationPortRange = "53"}
)

#Network security group assignment to subnet
#Network security group must be declared above.
#Comment object if no subnet is required.
$NetworkSecurityGroupsToSubnet = @(
    New-Object PSObject -Property @{NetworkSecurityGroup = "nsg-snet-dns-cac-001"; VirtualNetwork = "vnet-hub-cac-001"; Subnet ="snet-dns-cac-001"}
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

Log -Text "Validating if Azure module is already installed."
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
    Log -Text "Microsoft Azure PowerShell module is already installed."
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
#Creation of the network security group(s)
#**************************************************************************************************

Log -Text "Creating network security group(s)..."
ForEach ($NetworkSecurityGroup in $NetworkSecurityGroups) {
    Log -Text "Validating if subscription $($NetworkSecurityGroup.Subscription) exist."
    Try {
        $AzSubscription = Get-AzSubscription -SubscriptionName $NetworkSecurityGroup.Subscription
    }
    Catch {
        Log -Text "Subscription $($NetworkSecurityGroup.Subscription) does not exist." -Error
        Log -Text "It will not be possible to validate or create the network security group $($NetworkSecurityGroup.Name)." -Error
        Continue
    }
    Log -Text "Setting the subscription $($NetworkSecurityGroup.Subscription)..."
    Try {
        Set-AzContext -Subscription $AzSubscription | Out-Null
    }
    Catch {
        Log -Text "Unable to set the subscription $($VirtualNetwork.Subscription)." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error 
        Log -Text "It will not be possible to validate or create the network security group $($NetworkSecurityGroup.Name)." -Error
        Continue 
    }
    Log -Text "Validating if network security group $($NetworkSecurityGroup.Name) exist."
    $AzNetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroup.Name
    #If the value of the $AzNetworkSecurityGroup variable equals $Null, this indicates that the network security group does not exist.
    If ($Null -eq $AzNetworkSecurityGroup) {
        Log -Text "Validating if resource group $($NetworkSecurityGroup.ResourceGroup) exist."
        $AzResourceGroup = Get-AzResourceGroup -Name $NetworkSecurityGroup.ResourceGroup -ErrorAction SilentlyContinue
        #If the value of the $AzResourceGroup variable equals $Null, this indicates that the resource group does not exist.
        #It is not possible to create a network security group without a valid resource group.
        If ($Null -ne $AzResourceGroup) {
            Log -Text "Creating the network security group $($NetworkSecurityGroup.Name)..."
            Try {
                New-AzNetworkSecurityGroup -Name $NetworkSecurityGroup.Name -ResourceGroupName $NetworkSecurityGroup.ResourceGroup -Location $NetworkSecurityGroup.Region | Out-Null
            }
            Catch {
                Log -Text "An error occurred during the creation of the network security group $($NetworkSecurityGroup.Name)." -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                Continue
            }
            Log -Text "Network security group $($NetworkSecurityGroup.Name) successfully created."
        }
        Else {
            Log -Text "Resource group $($NetworkSecurityGroup.ResourceGroup) does not exist." -Error
            Log -Text "It is not be possible to create the network security group $($NetworkSecurityGroup.Name) without a valid resource group." -Error
       }
    }
    Else {
        Log -Text "Network security group $($NetworkSecurityGroup.Name) exist."
        $Config = $True
        If ($AzNetworkSecurityGroup.ResourceGroupName -ne $NetworkSecurityGroup.ResourceGroup) {
            $Config = $False
            Log -Text "Network security group $($NetworkSecurityGroup.Name) is not in the ressource group $($NetworkSecurityGroup.ResourceGroup)." -Warning
        }
        If ($AzNetworkSecurityGroup.Location -ne $NetworkSecurityGroup.Region) {
            $Config = $False
            Log -Text "Network security group $($NetworkSecurityGroup.Name) is not in the Microsoft Azure region $($NetworkSecurityGroup.Region)." -Warning
        }
        #validating if rules that should not exist are present in the network security group.
        $ActiveRules = $AzNetworkSecurityGroup.SecurityRules | Select-Object Name -ExpandProperty Name
        $RequiredRules = $SecurityRules | Where-Object {$_.NetworkSecurityGroup -eq $NetworkSecurityGroup.Name} | Select-Object Name -ExpandProperty Name
        $Results = Compare-Object -ReferenceObject $ActiveRules -DifferenceObject $RequiredRules
        #Side indicator value can be "=" when the value is present in both array, "<=" if value is only present in the reference object abd "=>" if value is only present in the difference object.
        #Because we need to validate if rule that should not exist are present, we will look for the side indicator "<=".
        $Results = $Results | Where-Object {$_.SideIndicator -eq "<="}
        ForEach ($Result in $Results) {
            $Config = $False
            $AzNetworkSecurityRuleConfig = $AzNetworkSecurityGroup.SecurityRules | Where-Object {$_.Name -eq $Result.InputObject}
            Log -Text "Rule $($AzNetworkSecurityRuleConfig.Name) should not exist in the network security group $($NetworkSecurityGroup.Name)." -Warning
        }
        If ($Config) {
            Log -Text "Network security group $($NetworkSecurityGroup.Name) is properly configured."
        }
    }
}

#**************************************************************************************************
#Add rule(s) to network security group(s)
#**************************************************************************************************

Log -Text "Adding rule(s) to security group(s)..."
ForEach ($SecurityRule in $SecurityRules) {
    Log -Text "Getting the subscription for the network security group $($SecurityRule.NetworkSecurityGroup)."
    $Subscription = $NetworkSecurityGroups | Where-Object {$_.Name -eq $SecurityRule.NetworkSecurityGroup} | Select -Property Subscription -ExpandProperty Subscription
    #If the value of the $Subscription variable equals $Null, this indicates that the network security group is not declared in the mandatory manual configuration section.
    If ($Null -eq $Subscription) {
        Log -Text "Unable to get the subscription name for the network security group $($SecurityRule.NetworkSecurityGroup)." -Error
        Log -Text "It will not be possible to validate or create the security rule $($SecurityRule.Name)." -Error
        Continue
    }
    Else {
        Log -Text "Validating if subscription $($Subscription) exist."
        Try {
            $AzSubscription = Get-AzSubscription -SubscriptionName $Subscription
        }
        Catch {
            Log -Text "Subscription $($Subscription) does not exist." -Error
            Log -Text "It will not be possible to validate or create the security rule $($SecurityRule.Name) in network security group $($SecurityRule.NetworkSecurityGroup)." -Error
            Continue
        }
        Log -Text "Setting the subscription $($Subscription)..."
        Try {
            Set-AzContext -Subscription $AzSubscription | Out-Null
        }
        Catch {
            Log -Text "Unable to set the subscription $($Subscription)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error 
            Log -Text "It will not be possible to validate or create the security rule $($SecurityRule.Name) in network security group $($SecurityRule.NetworkSecurityGroup)." -Error
            Continue 
        }
        Log -Text "Subscription $($Subscription) is now selected."
    }    
    Log -Text "Getting the network security group $($SecurityRule.NetworkSecurityGroup) for rule $($SecurityRule.Name)."
    $AzNetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $SecurityRule.NetworkSecurityGroup
    #If the value of the $AzNetworkSecurityGroup variable equals $Null, this indicates that the network security group does not exist.
    If ($Null -eq $AzNetworkSecurityGroup) {
        Log -Text "Unable to get the network security group $($SecurityRule.NetworkSecurityGroup) for security rule $($SecurityRule.Name)." -Error
        Log -Text "It will not be possible to validate or create the security rule $($SecurityRule.Name) in network security group $($SecurityRule.NetworkSecurityGroup)." -Error
        Continue
    }
    Log -text "Validating if security rule $($SecurityRule.Name) exist in network security group $($SecurityRule.NetworkSecurityGroup)."
    $AzNetworkSecurityRuleConfig = $AzNetworkSecurityGroup.SecurityRules | Where-Object {$_.Name -eq $SecurityRule.Name}
    #If the value of the $AzNetworkSecurityGroup variable equals $Null, this indicates that the security rule does not exist.
    If ($Null -eq $AzNetworkSecurityRuleConfig) {
        Log -Text "Creating security rule $($SecurityRule.Name) in network security group $($SecurityRule.NetworkSecurityGroup)..."
        Try {
            $AzNetworkSecurityGroup | Add-AzNetworkSecurityRuleConfig -Name $SecurityRule.Name -Description $SecurityRule.Description -Access $SecurityRule.Access -Direction $SecurityRule.Direction -Priority $SecurityRule.Priority -Protocol $SecurityRule.Protocol -SourceAddressPrefix $SecurityRule.SourceAddressPrefix -SourcePortRange $SecurityRule.SourcePortRange -DestinationAddressPrefix $SecurityRule.DestinationAddressPrefix -DestinationPortRange $SecurityRule.DestinationPortRange | Out-Null
            $AzNetworkSecurityGroup | Set-AzNetworkSecurityGroup | Out-Null
        }
        Catch {
            Log -Text "An error occurred during the security rule $($SecurityRule.Name) in network security group $($SecurityRule.NetworkSecurityGroup)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Continue
        }
        Log -Text "Security rule $($SecurityRule.Name) successfully created in network security group $($SecurityRule.NetworkSecurityGroup)."
    }
    Else {
        Log -Text "Security rule $($SecurityRule.Name) exist in network security group $($SecurityRule.NetworkSecurityGroup)."
        $Config = $True
        If ($AzNetworkSecurityRuleConfig.Description -ne $SecurityRule.Description) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) description is not '$($SecurityRule.Description)'." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.Access -ne $SecurityRule.Access) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) access is not $($SecurityRule.Access)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.Direction -ne $SecurityRule.Direction) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) direction is not $($SecurityRule.Direction)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.Priority -ne $SecurityRule.Priority) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) priority is not $($SecurityRule.Priority)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.Protocol -ne $SecurityRule.Protocol) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) protocol is not $($SecurityRule.Protocol)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.SourceAddressPrefix -ne $SecurityRule.SourceAddressPrefix) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) source address prefix is not $($SecurityRule.SourceAddressPrefix)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.SourcePortRange -ne $SecurityRule.SourcePortRange) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) source port range is not $($SecurityRule.SourcePortRange)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.DestinationAddressPrefix -ne $SecurityRule.DestinationAddressPrefix) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) destination address prefix is not $($SecurityRule.DestinationAddressPrefix)." -Warning
        }
        If ($AzNetworkSecurityRuleConfig.DestinationPortRange -ne $SecurityRule.DestinationPortRange) {
            $Config = $False
            Log -Text "Security rule $($SecurityRule.Name) destination port range is not $($SecurityRule.DestinationPortRange)." -Warning
        }
        If ($Config) {
            Log -Text "Security rule $($SecurityRule.Name) in network security group $($SecurityRule.NetworkSecurityGroup) is properly configured."
        }
    }
}

#**************************************************************************************************
#Assign network security group(s) 
#**************************************************************************************************


Log -Text "Assigning network security security group(s) to subnet..."
ForEach ($NetworkSecurityGroupToSubnet in $NetworkSecurityGroupsToSubnet) {
    Log -Text "Getting the subscription for the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup)."
    $Subscription = $NetworkSecurityGroups | Where-Object {$_.Name -eq $NetworkSecurityGroupToSubnet.NetworkSecurityGroup} | Select -Property Subscription -ExpandProperty Subscription
    #If the value of the $Subscription variable equals $Null, this indicates that the network security group is not declared in the mandatory manual configuration section.
    If ($Null -eq $Subscription) {
        Log -Text "Unable to get the subscription name for the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup)." -Error
        Log -Text "It will not be possible to validate or assign the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) to subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
        Continue
    }
    Else {
        Log -Text "Validating if subscription $($Subscription) exist."
        Try {
            $AzSubscription = Get-AzSubscription -SubscriptionName $Subscription
        }
        Catch {
            Log -Text "Subscription $($Subscription) does not exist." -Error
            Log -Text "It will not be possible to validate or assign the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) to subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
            Continue
        }
        Log -Text "Setting the subscription $($Subscription)..."
        Try {
            Set-AzContext -Subscription $AzSubscription | Out-Null
        }
        Catch {
            Log -Text "Unable to set the subscription $($Subscription)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error 
            Log -Text "It will not be possible to validate or assign the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) to subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
            Continue 
        }
        Log -Text "Subscription $($Subscription) is now selected."
    }    
    Log -Text "Getting the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup)."
    $AzNetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroupToSubnet.NetworkSecurityGroup
    #If the value of the $AzNetworkSecurityGroup variable equals $Null, this indicates that the network security group does not exist.
    If ($Null -eq $AzNetworkSecurityGroup) {
        Log -Text "Unable to get the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup)." -Error
        Log -Text "It will not be possible to validate or assign the network securrity group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) to subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
        Continue
    }
    Log -Text "Getting the virtual network for subnet $($NetworkSecurityGroupToSubnet.Subnet)."
    $AzVirtualNetwork = Get-AzVirtualNetwork -Name $NetworkSecurityGroupToSubnet.VirtualNetwork
    #If the value of the $AzVirtualNetwork variable equals $Null, this indicates that the virtual network does not exist.
    If ($Null -eq $AzVirtualNetwork) {
        Log -Text "Unable to get the virtual network $($NetworkSecurityGroupToSubnet.VirtualNetwork) for subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
        Log -Text "It will not be possible to validate or assign the network securrity group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) to subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
        Continue
    }
    Log -Text "Getting the subnet $($NetworkSecurityGroupToSubnet.Subnet)."
    $AzVirtualNetworkSubnetConfig = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $AzVirtualNetwork -Name $NetworkSecurityGroupToSubnet.Subnet -ErrorAction SilentlyContinue
    #If the value of the $AzVirtualNetworkSubnetConfig variable equals $Null, this indicates that the subnet does not exist.
    If ($Null -eq $AzVirtualNetworkSubnetConfig) {
        Log -Text "Unable to get the subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
        Log -Text "It will not be possible to validate or assign the network securrity group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) to subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
        Continue
    }
    If ($Null -eq $AzVirtualNetworkSubnetConfig.NetworkSecurityGroup.Id) {
        Log -Text "Assigning the network security group $($NetworkSecurityGroupToSubnet.VirtualNetwork) to subnet $($NetworkSecurityGroupToSubnet.Subnet)..."
        Try {
            Set-AzVirtualNetworkSubnetConfig -Name $AzVirtualNetworkSubnetConfig.Name -VirtualNetwork $AzVirtualNetwork -AddressPrefix $AzVirtualNetworkSubnetConfig.AddressPrefix -NetworkSecurityGroup $AzNetworkSecurityGroup | Out-Null
            $AzVirtualNetwork | Set-AzVirtualNetwork | Out-Null
        }
        Catch {
            Log -Text "An error occurred during the assignment of the network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) subnet $($NetworkSecurityGroupToSubnet.Subnet)." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Continue
        }
        Log -Text "Network security group $($NetworkSecurityGroupToSubnet.VirtualNetwork) successfully assigned to subnet $($NetworkSecurityGroupToSubnet.Subnet)..."
    }
    ElseIf ($AzVirtualNetworkSubnetConfig.NetworkSecurityGroup.Id -ne $AzNetworkSecurityGroup.Id) {
            Log -Text "Network security group $($AzVirtualNetworkSubnetConfig.NetworkSecurityGroup.Id.Split("/") | Select-Object -Last 1) is currently assign to subnet $($NetworkSecurityGroupToSubnet.Subnet) instead of $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup)." -Warning
    }
    Else {
            Log -Text "Network security group $($NetworkSecurityGroupToSubnet.NetworkSecurityGroup) is properly assign to subnet $($NetworkSecurityGroupToSubnet.Subnet)."
    }
    
}
