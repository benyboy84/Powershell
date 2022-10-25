<#
**********************************************************************************
Script to create Microsoft Azure virtual networks and subnets
**********************************************************************************

.SYNOPSIS
Script to create Microsoft Azure virtual networks and subnets.

Version 1.0 of this script.
Version 2.0 of this script.
    Add validation for VNet and subnet properties.

.DESCRIPTION
This script is use to create Microsoft Azure virtual networks and subnets. 

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

#Microsoft Azure Region
$AzureRegion = "canadacentral"

#Microsoft Azure Subscription
$Subscription = "Abonnement"

#Ressource group name
$RGName = "RessourceGroup"

#Virtual networks
$Vnets = @(
    New-Object PSObject -Property @{Name = "Vnet"; AddressPrefix = "10.0.0.0/16"}
)

#Subnets
#If no route table is needed, leave it empty
$Subnets = @(
    New-Object PSObject -Property @{Name = "Data"; AddressPrefix = "10.0.0.0/24"; VirtualNetwork = "Vnet"; RouteTable = ""}
    New-Object PSObject -Property @{Name = "web"; AddressPrefix = "10.0.1.0/24"; VirtualNetwork = "Vnet"; RouteTable = "RouteTable"}
)

#Route table
#Leave it empty if no route table are required
$RouteTables = @(
    New-Object PSObject -Property @{Name = "RouteTable"}
)
 
#Route
#NextHopType can be: Internet, None, VirtualAppliance, VirtualApplianceGateway, VnetLocal
$Routes = @(
    New-Object PSObject -Property @{RouteTable = "RouteTable"; Name = "Internet"; AdressPrefix = "0.0.0.0/0"; NextHopType = "Internet"; NextHopAddress = ""}
    New-Object PSObject -Property @{RouteTable = "RouteTable"; Name = "Web"; AdressPrefix = "10.0.1.0/24"; NextHopType = "VirtualAppliance"; NextHopAddress = "10.0.0.4"}
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
        Log -Text "Unable to create ressource group $($RGName). Script will exit." -Error
        Log -Text "Error:$($PSItem.Exception.Message)" -Error
        Exit 1
    }
    Log -Text "Ressourge group $($RGName) was successfully created."
}
Else {
    If ($AzResourceGroup.Location -ne $AzureRegion) {
        Log -Text "Ressourge group $($RGName) is not in the Microsoft Azure region $($AzureRegion)." -Warning
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
            Log -Text "Virtual network $($Vnet.Name) is not in the ressource group $($RGName)." -Warning
        }
        If ($AzVirtualNetwork.Location -ne $AzureRegion) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) is not in the Microsoft Azure region $($AzureRegion)." -Warning
        }
        If ($AzVirtualNetwork.AddressSpace.AddressPrefixes -ne $VNet.AddressPrefix) {
            $Config = $False
            Log -Text "Virtual network $($Vnet.Name) does not have the address prefix $($Vnet.AddressPrefix)." -Warning
        }
        If ($Config) {
            Log -Text "Virtual network $($Vnet.Name) already exist."
        }
    }
}

#**************************************************************************************************
#Creation of the subnet
#**************************************************************************************************

#Creating subnet.
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
#Creation of the route table
#**************************************************************************************************

ForEach ($RouteTable in $RouteTables) {
    #Validating if the route table already exist.
    Log -Text "Validating if the route table $($RTName) already exist."
    $RT = Get-AzRouteTable -Name $RouteTable.Name -ResourceGroupName $RGName -ErrorAction SilentlyContinue
    If ($Null -eq $RT) {
        #Creating route table.
        Log -Text "Creating route table $($RouteTable.Name)."
        Try {
            $RT = New-AzRouteTable -Name $RouteTable.Name -ResourceGroupName $RGName -Location $AzureRegion
            Log -Text "Routing table $($RouteTable.Name) successfully created."
        }
        Catch {
            Log -Text "An error occurred during the creation of the route table $($RouteTable.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        $Config = $True
        If ($RT.ResourceGroupName -ne $RGName) {
            $Config = $False
            Log -Text "Route table $($RouteTable.Name) is not in the ressource group $($RGName)." -Warning
        }
        If ($RT.Location -ne $AzureRegion) {
            $Config = $False
            Log -Text "Route table $($RouteTable.Name) is not in the Microsoft Azure region $($AzureRegion)." -Warning
        }
        If ($Config) {
            Log -Text "Routing table $($RTName) for trust subnet already exist."
        }
    }
}

#**************************************************************************************************
#Assignment of route table to subnet
#**************************************************************************************************

$AssignedTo = $Subnets | Where-Object {$_.RouteTable -ne ""}
ForEach($Assignment in $AssignedTo) {
    #Getting the subnet for route table.
    Log -Text "Getting required information to assign route table $($Assignment.RouteTable) to $($Assignment.Name)."
    Try {
        $VNet = Get-AzVirtualNetwork -Name $Assignment.VirtualNetwork -ResourceGroupName $RGName
        $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $Assignment.Name
        $RT = Get-AzRouteTable -Name $Assignment.RouteTable -ResourceGroupName $RGName 
    }
    Catch {
        Log -Text "Unable to get the subnet for route table." -Error
        Continue
    }
    If ($Null -eq $Subnet.RouteTable) {
        Try{
            #Assignment of the route table to the subnet.
            Log -Text "Assignment of the route table $($Assignment.RouteTable) to the subnet $($Assignment.Name)."
            Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -AddressPrefix $Assignment.AddressPrefix -Name $Assignment.Name -RouteTable $RT | Out-Null
            $VNet | Set-AzVirtualNetwork | Out-Null
            Log -Text "Route table $($Assignment.RouteTable) successfully assigne to $($Assignment.Name) subnet."
        }
        Catch {
            Log -Text "An error occurred during the assignment of the route table $($Assignment.RouteTable) to subnet $($Assignment.Name). Script will exit." -Error
            Log -Text "Error:$($PSItem.Exception.Message)" -Error
            Exit 1
        }
    }
    Else {
        If ($Subnet.RouteTable.Id -notmatch $Assignment.RouteTable) {
            Log -Text "Subnet $($Assignment.Name) does not have the route table $($Assignment.RouteTable) assigned to it." -Warning
        }
        Else {
            Log -Text "Route table is assigned to subnet $($Assignment.Name)."
        }
    }
}

#**************************************************************************************************
#Route creation
#**************************************************************************************************

ForEach ($Route in $Routes) {
    #Getting route table for route.
    Log -Text "Getting route table $($Route.RouteTable) for route $($Route.Name)."
    Try {
        $RT = Get-AzRouteTable -Name $Route.RouteTable -ResourceGroupName $RGName 
    }
    Catch {
        Log -Text "Unable to get the route table $($Route.RouteTable) for route $($Route.Name)." -Error
        Continue
    }
    #Validating if route already exist in route table.
    Log -Text "Validating if route already exist in route table $($RT.Name)."
    $RouteConfig = Get-AzRouteConfig -RouteTable $RT -ErrorAction SilentlyContinue
    If ($Null -eq $RouteConfig) {
        #Creating route.
        Log -Text "No route exist in route table $($RT.Name)."
        Log -Text "Creating route."
        If ($Route.NextHopType -eq "VirtualAppliance") {
            If ($Route.NextHopAddress -ne "") {
                Try {
                    $RT | Add-AzRouteConfig -Name $Route.Name -AddressPrefix $Route.AdressPrefix -NextHopType $Route.NextHopType -NextHopIpAddress $Route.NextHopAddress | Set-AzRouteTable | Out-Null
                    Log -Text "Route $($Route.Name) successfully created."
                }
                Catch {
                    Log -Text "An error occurred during the creation of route table $($Route.Name). Script will exit." -Error
                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                    Exit 1 
                }
            }
            Else {
                Log -Text "Next hop Ip address can't be empty when next hop type is virrtuel appliance." -Error
            }
        }
        Else {
            Try {
                $RT | Add-AzRouteConfig -Name $Route.Name -AddressPrefix $Route.AdressPrefix -NextHopType $Route.NextHopType | Set-AzRouteTable | Out-Null
                Log -Text "Route $($Route.Name) successfully created."
            }
            Catch {
                Log -Text "An error occurred during the creation of route table $($Route.Name). Script will exit." -Error
                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                Exit 1 
            }
        }
    }
    Else {
        $RouteConfig = Get-AzRouteConfig -RouteTable $RT -Name $Route.Name -ErrorAction SilentlyContinue
        If ($Null -eq $RouteConfig) {
            #Route with same name does not exist.
            $RouteConfig = Get-AzRouteConfig -RouteTable $RT | Where-Object {$_.AddressPrefix -eq $Route.AdressPrefix}
            If($Null -eq $RouteConfig) {
                #No route with same prefix exist
                $RouteConfig = $RouteConfig | Where-Object {$_.NextHopType -eq $Route.NextHopType}
                If ($Null -eq $RouteConfig) {
                    #No route with same next hop exist
                    #Creating route
                    Log -Text "Creating route."
                        If ($Route.NextHopType -eq "VirtualAppliance") {
                            If ($Route.NextHopAddress -ne "") {
                                Try {
                                    $RT | Add-AzRouteConfig -Name $Route.Name -AddressPrefix $Route.AdressPrefix -NextHopType $Route.NextHopType -NextHopIpAddress $Route.NextHopAddress | Set-AzRouteTable | Out-Null
                                    Log -Text "Route $($Route.Name) successfully created."
                                }
                                Catch {
                                    Log -Text "An error occurred during the creation of route table $($Route.Name). Script will exit." -Error
                                    Log -Text "Error:$($PSItem.Exception.Message)" -Error
                                    Exit 1 
                                }
                            }
                            Else {
                                Log -Text "Next hop Ip address can't be empty when next hop type is virrtuel appliance." -Error
                            }
                        }
                        Else {
                            Try {
                                $RT | Add-AzRouteConfig -Name $Route.Name -AddressPrefix $Route.AdressPrefix -NextHopType $Route.NextHopType | Set-AzRouteTable | Out-Null
                                Log -Text "Route $($Route.Name) successfully created."
                            }
                            Catch {
                                Log -Text "An error occurred during the creation of route table $($Route.Name). Script will exit." -Error
                                Log -Text "Error:$($PSItem.Exception.Message)" -Error
                                Exit 1 
                            }
                        }
                }
             }
            Else {
                #Route with same address prefix already exist.
                #Validating if route with same prefix have only the wrong name.
                If ($RouteConfig.Name -ne $Route.Name) {
                    Log -Text "Name for route with address prefix $($Route.AdressPrefix) is not $($Route.Name)." -Warning
                }
                If ($RouteConfig.NextHopType -ne $Route.NextHopType) {
                    Log -Text "Next hop type for route with address prefix $($Route.AdressPrefix) is not $($Route.NextHopType)." -Warning
                    $Config = $False
                }
                If ($RouteConfig.NextHopType -eq "VirtualAppliance") {
                    If ($RouteConfig.NextHopAddress -ne $Route.NextHopAddress) {
                        Log -Text "Next hop ip address for route with address prefix $($Route.AdressPrefix) is not $($Route.NextHopAddress)." -Warning
                        $Config = $False
                    }
                }
            }
        }
        Else {
            #Route with the same name exist.
            #Validating if adress prefix is correctly configured.
            $Config = $True
            If ($RouteConfig.AddressPrefix -ne $Route.AdressPrefix) {
                Log -Text "Address prefix for route $($Route.Name) is not $($Route.AdressPrefix)." -Warning
                $Config = $False
            }
            If ($RouteConfig.NextHopType -ne $Route.NextHopType) {
                Log -Text "Next hop type for route $($Route.Name) is not $($Route.NextHopType)." -Warning
                $Config = $False
            }
            If ($RouteConfig.NextHopType -eq "VirtualAppliance") {
                If ($RouteConfig.NextHopAddress -ne $Route.NextHopAddress) {
                    Log -Text "Next hop ip address for route $($Route.Name) is not $($Route.NextHopAddress)." -Warning
                    $Config = $False
                }
            }
            If ($Config) {
                Log -Text "Route with name $($Route.Name) already exist"
            }
        }
    }
}







#$RouteExist = $False
#ForEach ($Routes in $RT.Routes) {
#    If ($Routes.AddressPrefix -eq "0.0.0.0/0" -and $Route.NextHopType -eq "VirtualAppliance" -and $Route.NextHopIpAddress -eq $LBIP) {
#        $RouteExist = $True
#    }
#}
#If (!($RouteExist)) {
#    $Config = $False
#    Log -Text "Route table $($RTName) does not contain the appropriate route. Script will exit." -Warning
#}
#If ($Subnet.RouteTable.Id -notmatch $RT.Name) {
#    $Config = $False
#    Log -Text "Route table $($RTName) is not associate to $($Subnet.Name). Script will exit." -Warning
#}