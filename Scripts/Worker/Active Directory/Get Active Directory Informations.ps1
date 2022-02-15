# **********************************************************************************
# Script to find all information regarding Active Directory.
#
# This script will generate text file with all the collected information and
# a log file with the information related to the script execution.
#
# If you need to troubleshoot the script, you can enable the Debug option in
# the parameter. This will generate display information on the screen.
#
# This script needs to be run directly on a Domain Controller.
#
# This script use Active Directory module
#
# ==================================================================================
# 
# Date        By                  Modification
# ----------  ------------------  --------------------------------------------------
# 2022-02-01  Benoit Blais        Original version
# 2022-02-14  Benoit Blais        Add output file instead of displaying information
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

#Log file
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$Output = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).txt"

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window
#if debug mode is $TRUE.
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
    Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
}

# **********************************************************************************

Log -Text "Script Begin"

#Delete output file or text file if already exist.
Log -Text "Validating if output or log file already exist"
If (Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")}){
    #Old file exist, we will try to delete it.
    Log -Text "Deleting old output and log file"
    Try {
        Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")} | Remove-Item
    }
    Catch {
        Log -Text "An error occured when deleting old output and log file"
    }
}

#Validate if Active Directory module is currently loaded in Powershell session.
Log -Text "Validating if Active Directory module is loaded in the currect Powershell session"
If (!(Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"})){

    #Active Directory is not currently loaded in Powershell session.
    Log -Text "Active Directory is not currently loaded in Powershell session" -Warning
    If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) { 
        
        #Active Directory module installed on that computer.
        Log -Text "Active Directory module installed on that computer"
        #Importing Active Directory module.
        Log -Text "Importing Active Directory module"
        Try {
            Import-Module ActiveDirectory 
        }
        Catch {
            #Unable to import Active Directory module.
            Log -Text "Unable to import Active Directory module" -Error
            #Because this script can't be run without this module, the script execution is stop.
            Break
        }
    
    }
    Else {
        
        #Active Directory module is not installed on the current computer.
        Log -Text "Active Directory module is not installed on the current computer" -Error
        #Because this script can't be run without this module, the script execution is stop.
        Break
    }
}
Else {

    #Active Directory module is loaded in the current Powershell session.
    Log -Text "Active Directory module is loaded in the current Powershell session"

}

#Getting currently logged domain information.
Log -Text "Getting currently logged domain information"
Try { 
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()  
} 
Catch { 
      #Unable to get currently logged domain information.
      Log "Cannot connect to current Domain" -Error
      #Because this script can't run without the Domain information, the script execution is stop.
      Break
} 

$DCList = @()
#Getting a list of all Domain Controller.
Log -Text "Getting a list of all Domain Controller"
$Domain.DomainControllers | ForEach-Object {
    $DCList += $_.Name
}

#If no Domain Controller was found, we will end this script.
If(!$DCList) {
    #No Domain Controller found.
    Log -Text "No Domain Controller found" -Error
    #Because this script can't run without the Domain controllers list, the script execution is stop.
    Break
}

Log -Text "Domain Controllers found"

#Get all informations regarding Active Directory Forest.
Log -Text "Getting Active Directory Forest informations"
Try {
    $ForestInfo = Get-ADForest 
}
Catch {
    #Unable to get all information regarding Active Directory Forest.
    $ForestInfo = $Null
    Log -Text "An error occured during getting Active Directory Forest informations" -Error
}

#Get all informations regarding Active Directory Domain.
Log -Text "Getting Active Directory Domain informations"
Try {
    $DomainInfo = Get-ADDomain 
}
Catch {
    #Unable to get all information regarding Active Directory Domain.
    $DomainInfo = $Null
    Log -Text "An error occured during getting Active Directory Domain informations" -Error
}

#Get Active Directory Schema Version.
Log -Text "Getting Active Directory Schema version"
Try {
    $ADVer = Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion | Select-Object objectVersion
    $ADNUM = $ADVer -replace "@{objectVersion=","" -replace "}",""
}
Catch {
    #Unable to get Active Directory Schema Version.
    $ADNUM = $Null
    Log -Text "An error occured during getting Active Directory Schema Version" -Error
}

#Converting Schema Version to Windows Server version.
Log -Text "Converting Schema Version to Windows Server version"
If ($ADNum -eq '88') {$SchemaVersion = 'Windows Server 2019'}
ElseIf ($ADNum -eq '87') {$SchemaVersion = 'Windows Server 2016'}
ElseIf ($ADNum -eq '69') {$SchemaVersion = 'Windows Server 2012 R2'}
ElseIf ($ADNum -eq '56') {$SchemaVersion = 'Windows Server 2012'}
ElseIf ($ADNum -eq '47') {$SchemaVersion = 'Windows Server 2008 R2'}
ElseIf ($ADNum -eq '44') {$SchemaVersion = 'Windows Server 2008'}
ElseIf ($ADNum -eq '31') {$SchemaVersion = 'Windows Server 2003 R2'}
ElseIf ($ADNum -eq '30') {$SchemaVersion = 'Windows Server 2003'}

#Adding "Active Directory Infomations" section title to output file.
Log -Text 'Adding "Active Directory Infomations" section title to output file'
Try {
    Add-Content $Output "Active Directory Infomations"
    Add-Content $Output "----------------------------"
} 
Catch {
    Log -Text 'An error occured when "Active Directory Infomations" section title to output file' -Error
}

#Adding Forest name to output file.
Log -Text "Adding Forest name to output file"
Try {
    If ($Null -ne $ForestInfo.Name) {
        Add-Content $Output "Forest Name                       : $($ForestInfo.Name)"
    } 
    Else {
        Add-Content $Output "Forest Name                       : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Forest name to output file" -Error
}

#Adding Domain name to output file.
Log -Text "Adding Domain name to output file"
Try {
    If ($Null -ne $DomainInfo.Name) {
        Add-Content $Output "Domain Name                       : $($DomainInfo.Name)"
    } 
    Else {
        Add-Content $Output "Domain Name                       : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Domain name to output file" -Error
}

#Adding NetBios name to output file.
Log -Text "Adding NetBios name to output file"
Try {
    If ($Null -ne $DomainInfo.NetBIOSName) {
        Add-Content $Output "NetBios Name                      : $($DomainInfo.NetBIOSName)"
    } 
    Else {
        Add-Content $Output "NetBios Name                      : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding NetBios name to output file" -Error
}

#Adding Forest mode to output file.
Log -Text "Adding Forest mode to output file"
Try {
    If ($Null -ne $ForestInfo.ForestMode) {
        Add-Content $Output "Forest mode                       : $($ForestInfo.ForestMode)"
    } 
    Else {
        Add-Content $Output "Forest mode                       : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Forest mode to output file" -Error
}

#Adding Domain mode to output file.
Log -Text "Adding Domain mode to output file"
Try {
    If ($Null -ne $DomainInfo.DomainMode) {
        Add-Content $Output "Domain Mode                       : $($DomainInfo.DomainMode)"
    } 
    Else {
        Add-Content $Output "Domain Mode                       : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Domain mode to output file" -Error
}

#Adding schema version to output file.
Log -Text "Adding schema version to output file"
Try {
    If ($Null -ne $SchemaVersion) {
        Add-Content $Output "Active Directory Schema Version   : $($SchemaVersion)"
    } 
    Else {
        Add-Content $Output "Active Directory Schema Version   : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding schema version to output file" -Error
}

Try {Add-Content $Output " "} Catch {$Null}

#Adding title to output file.
Log -Text 'Adding "FSMO Roles" section title to output file'
Try {
    Add-Content $Output "FSMO Roles"
    Add-Content $Output "----------"
} 
Catch {
    Log -Text 'An error occured when adding "FSMO Roles" section title to output file' -Error
}

#Adding Schema Master to output file.
Log -Text "Adding Schema Master to output file"
Try {
    If ($Null -ne $ForestInfo.SchemaMaster) {
        Add-Content $Output "Schema Master                     : $($ForestInfo.SchemaMaster)"
    } 
    Else {
        Add-Content $Output "Schema Master                     : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Schema Master to output file" -Error
}

#Adding Domain Naming Master to output file.
Log -Text "Adding Domain Naming Master to output file"
Try {
    If ($Null -ne $ForestInfo.DomainNamingMaster) {
        Add-Content $Output "Domain Naming Master              : $($ForestInfo.DomainNamingMaster)"
    } 
    Else {
        Add-Content $Output "Domain Naming Master              : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Domain Naming Master to output file" -Error
}

#Adding Relative ID (RID) Master to output file.
Log -Text "Adding Relative ID (RID) Master to output file"
Try {
    If ($Null -ne $DomainInfo.RidMaster) {
        Add-Content $Output "Relative ID (RID) Master          : $($DomainInfo.RidMaster)"
    } 
    Else {
        Add-Content $Output "Relative ID (RID) Master          : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Relative ID (RID) Master to output file" -Error
}

#Adding Primary Domain Controller to output file.
Log -Text "Adding Primary Domain Controller to output file"
Try {
    If ($Null -ne $DomainInfo.PDCEmulator) {
        Add-Content $Output "Primary Domain Controller         : $($DomainInfo.PDCEmulator)"
    } 
    Else {
        Add-Content $Output "Primary Domain Controller         : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Primary Domain Controller to output file" -Error
}

#Adding Infrastructure Master to output file.
Log -Text "Adding Infrastructure Master to output file"
Try {
    If ($Null -ne $DomainInfo.InfrastructureMaster) {
        Add-Content $Output "Infrastructure Master             : $($DomainInfo.InfrastructureMaster)"
    } 
    Else {
        Add-Content $Output "Infrastructure Master             : No information found"
    }
}
Catch {
        Log -Text "An error occured when adding Infrastructure Master to output file" -Error
}

Try {Add-Content $Output " "} Catch {$Null}

#Get the size of SysVol Folder on each Domain Controller.
Log -Text "Getting the size of SysVol folder on each Domain Controller"
$SysVolDetails = @()
ForEach ($DC in $DCList) {

    $Object = "" | Select-Object Name,
                                 Path,
                                 Size
    $Object.Name = $DC

    #Getting SysVol folder location for the current DC
    Log -Text "Getting SysVol folder location for $($DC)"
    Try {
        If ($DC -ne $ENV:ComputerName) {
            $SysVolPath = Invoke-Command -ComputerName $DC -ScriptBlock {Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters -Name "SysVol" | Select-Object -ExpandProperty SysVol}
        }
        Else {
            $SysVolPath = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters -Name "SysVol" | Select-Object -ExpandProperty SysVol
        }
    }
    Catch {
        Log -Text "An error occured during getting SysVol folder location for $($DC)"
    }
    
    #Getting SysVol folder size for the current DC
    Log -Text "Getting SysVol folder size for $($DC)"
    Try {
        If ($Null -ne $SysVolPath) {
            If ($DC -ne $ENV:ComputerName) {
                $Size = Invoke-Command -ComputerName $DC -ArgumentList $SysVolPath -ScriptBlock {
                    $Path = $args[0]
                    If (Test-Path $Path) {
                        Get-ChildItem $Path -Recurse | Measure-Object -Sum Length | Select-Object Sum
                    }
                }
            }
            Else {
                If (Test-Path $Path) {
                    $Size = Get-ChildItem $SysVolPath -Recurse | Measure-Object -Sum Length | Select-Object Sum
                }
            }
        }
    }
    Catch {
        Log -Text "An error occured during getting SysVol folder size for $($DC)"
    }

    #Converting SysVol folder size from bytes to ...
    Log -Text "Converting SysVol folder size"
    If ($Null -ne $Size) {
        Switch ($Size.Sum) {
            {$_ -lt 1024}                               {$Size = $Size.Sum
                                                            $Metric = "Bytes"}
            {($_ -gt 1024) -and ($_ -lt 1048576)}       {$Size = $("{0:N2}" -f ($Size.Sum / 1KB))
                                                            $Metric = "KB"}
            {($_ -gt 1048576) -and ($_ -lt 1073741824)} {$Size = $("{0:N2}" -f ($Size.Sum / 1MB))
                                                            $Metric = "MB"}
            {$_ -gt 1073741824}                         {$Size = $("{0:N2}" -f ($Size.Sum / 1GB))
                                                            $Metric = "GB"}
        }
    }

    If ($Null -ne $SysVolPath) {
        $Object.Path = $($SysVolPath)
    }
    Else {
        $Object.Path = "Unable to get SysVol path"
    }
    If ($Null -ne $Size) {
        $Object.Size = "$($Size)$($Metric)"
    }
    Else {
        $Object.Size = "Unable to get SysVol size"
    }

    $SysVolDetails += $Object

}

#Adding title to output file.
Log -Text 'Adding "SysVol Folder Infomations" section title to output file'
Try {
    Add-Content $Output "SysVol Folder Infomations"
    Add-Content $Output "-------------------------"
} 
Catch {
    Log -Text 'An error occured when adding "SysVol Folder Infomations" section title to output file' -Error
}

#Adding SysVol folder information in the output file.
Log -Text "Adding SysVol folder information in the output file"
Try {
    $SysVolDetails | Format-Table -AutoSize | Out-File -FilePath $Output -Append -Encoding utf8
}
Catch {
    Log -Text "An error occured during adding SysVol folder information to output file"
}

#Get details configuration for Domain Controller.
$DCDetails = @()
Log -Text "Get details configuration for every Domain Controller"
ForEach ($DC in $DCList) {

    $Object = "" |  Select-Object Name,
    IPAddress,
    OperatingSystem,
    Site,
    GlobalCatalog,
    ReadOnly
    $Object.Name = $DC

    #Getting details informations for specefic Domain Controller.
    Log -Text "Getting details informations for $($DC)"
    Try {
        $DomainController = Get-ADDomainController -Identity $DC
    }
    Catch {
        Log -Text "Unable to get details infomations for $($DC)" -Error
    }

    #Build an array with the desired properties for Domain Controllers.
    Log -Text "Building an array with the desired properties for Domain Controllers"
    If ($DomainController -ne $Null) {

        $Object.IPAddress = $DomainController.IPv4Address
        $Object.OperatingSystem = $DomainController.OperatingSystem 
        $Object.Site = $DomainController.Site
        $Object.GlobalCatalog = $DomainController.IsGlobalCatalog
        $Object.ReadOnly = $DomainController.IsReadOnly

    }
    Else {

        $Object.IPAddress = "Unable to get IP address"
        $Object.OperatingSystem = "Unable to get operating system" 
        $Object.Site = "Unable to get Active Directory site"
        $Object.GlobalCatalog = "Unable to get Domain Controller mode"
        $Object.ReadOnly = "Unable to get Domain Controller mode"

    }

    $DCDetails += $Object

}

#Adding title to output file.
Log -Text 'Adding "Domain Controllers" section title to output file'
Try {
    Add-Content $Output "Domain Controllers"
    Add-Content $Output "------------------"
} 
Catch {
    Log -Text 'An error occured when adding "Domain Controllers" section title to output file' -Error
}

#Adding DC details informations in the output file.
Log -Text "Adding DC details informations in the output file"
Try {
    $DCDetails | Format-Table -AutoSize | Out-File -FilePath $Output -Append -Encoding utf8
}
Catch {
    Log -Text "An error occured during adding DC details informations in the output file"
}

#Get Sites and Services informations.
#Get Active Directory Replication Site.
Log -Text "Getting Active Directory Replication Site"
Try {
    $ADSites = Get-ADReplicationSite -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Site" -Error
}

#Get Active Directory Replication Subnet.
Log -Text "Getting Active Directory Replication Subnet"
Try {
    $ADSubnets = Get-ADReplicationSubnet -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Subnet" -Error
}

#Get Active Directory Replication Connection.
Log -Text "Getting Active Directory Replication Connection"
Try {
    $AdReplicationConnections = Get-ADReplicationConnection -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Connection" -Error
}

#Get Active Directory Replication Site Link.
Log -Text "Getting Active Directory Replication Site Link"
Try {
    $ADReplicationSiteLinks = Get-ADReplicationSiteLink -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Site Link" -Error
}

#Adding title to output file.
Log -Text 'Adding "Active Directory Sites & Services Infomations" section title to output file'
Try {
    Add-Content $Output "Active Directory Sites & Services Infomations"
    Add-Content $Output "---------------------------------------------"
} 
Catch {
    Log -Text 'An error occured when adding "Active Directory Sites & Services Infomations" section title to output file' -Error
}

#Adding title to output file.
Log -Text 'Adding "Inter-Site Transport" to output file'
Try {
    Add-Content $Output "Inter-Site Transport"
} 
Catch {
    Log -Text 'An error occured when adding "Inter-Site Transport" to output file' -Error
}

#Adding Inter-Site Transport information to output file.
Log -Text "Adding Inter-Site Transport information to output file"
ForEach ($ADReplicationSiteLink in $ADReplicationSiteLinks) {
    Try {
        Add-Content $Output "Name                               : $($ADReplicationSiteLink.Name)"
    }
    Catch {
        Log -Text "An error occured during adding Active Directory Replication Site link to output file"
    }
    Try {
        Add-Content $Output " Cost                              : $($ADReplicationSiteLink.Cost)"
    }
    Catch {
        Log -Text "An error occured during adding Active Directory Replication Site Link cost to output file"
    }
    Try {
        Add-Content $Output " Replication Frequency In Minutes  : $($ADReplicationSiteLink.ReplicationFrequencyInMinutes)"
    }
    Catch {
        Log -Text "An error occured during adding Active Directory Replication Site Link frequency to output file"
    }
    Try {
        Add-Content $Output " Sites                             : $(($ADReplicationSiteLink.SitesIncluded[0].Split(",") | Select-Object -First 1).Replace("CN=",''))"
    }
    Catch {
        Log -Text "An error occured during adding Active Directory Replication Site Link sites to output file"
    }
    #If mor then one site use this Inter-Site Transport, we will loop to add each of them into output file.
    For ($i=1; $i -lt ($ADReplicationSiteLink.SitesIncluded).Count; $i++) {
        Try {
            Add-Content $Output "                                     $(($ADReplicationSiteLink.SitesIncluded[$i].Split(",") | Select-Object -First 1).Replace("CN=",''))"
        }
        Catch {
            Log -Text "An error occured during adding Active Directory Replication Site Link sites to output file"
        }
    }
 }

#Adding title to output file.
Log -Text 'Adding "Subnets" to output file'
Try {
    Add-Content $Output "Subnets"
} 
Catch {
    Log -Text 'An error occured when adding "Subnets" to output file' -Error
}

#Adding subnet information to output file
Log -Text "Adding subnet information to output file"
ForEach ($ADSubnet in $ADSubnets) {
    Try {
        Add-Content $Output "Name                               : $($ADSubnet.Name)"
    }
    Catch {
        Log -Text "An error occured during adding subnet name to output file"
    }
    Try {
        If ($ADSubnet.Site -ne $Null) {
                Add-Content $Output " Site                              : $((($ADSubnet.Site).Split(",") | Select-Object -First 1).Replace("CN=",''))"
        }
        Else {
            Add-Content $Output " Site                              : "
        }
    }
    Catch {
        Log -Text "An error occured during adding subnet's site to output file"
    }
}
#Adding title to output file.
Log -Text 'Adding "Sites" to output file'
Try {
    Add-Content $Output "Sites"
} 
Catch {
    Log -Text 'An error occured when adding "Sites" to output file' -Error
}

#Adding site information to output file.
Log -Text "Adding site information to output file"
ForEach ($ADSite in $ADSites) {
    Try {
        Add-Content $Output "Site Name                          : $($ADSite.Name)" 
    }
    Catch {
        Log -Text "An error occured during adding site name to output file" -Error
    }
    $Servers = $DCDetails | Where-Object {$_.Site -eq $ADSite.Name}
    ForEach ($Server in $Servers) {

        If ($Server.Name -match "\.") {
            $Name = $Server.Name.Split(".") | Select-Object -First 1
        }
        Else {
            $Name = $Server.Name
        }

        Try {
            Add-Content $Output " Server                            : $($Name)"
        }
        Catch {
            Log -Text "An error occured during adding site's server to output file" -Error
        }
        $FromServers = $AdReplicationConnections | Where-Object {$_.ReplicateToDirectoryServer -match $Name} | Select-Object ReplicateFromDirectoryServer

        If ($FromServers -eq $Null) {
            Try {
                Add-Content $Output "  Replicated from                  : "
            }
            Catch {
                Log -Text "An error occured during adding server replicated from to output file" -Error
            }
        }
        ElseIf ($FromServers.Length -eq 1) {
            Try {
                Add-Content $Output "   Replicated from                 : $(($FromServers.ReplicateFromDirectoryServer.Split(",") | Select-Object -Skip 1 | Select-Object -First 1).Replace("CN=",''))"
            }
            Catch {
                Log -Text "An error occured during adding server replicated from to output file" -Error
            }
        }
        Else {
            Try {
                Add-Content $Output "   Replicated from                 : $(($FromServers[0].ReplicateFromDirectoryServer.Split(",") | Select-Object -Skip 1 | Select-Object -First 1).Replace("CN=",''))"
            }
            Catch {
                Log -Text "An error occured during adding server replicated from to output file" -Error
            }
            For ($i=1; $i -lt $FromServers.Length; $i++) {
                Try {
                    Add-Content $Output "                                     $(($FromServers[$i].ReplicateFromDirectoryServer.Split(",") | Select-Object -Skip 1 | Select-Object -First 1).Replace("CN=",''))"
                }
                Catch {
                    Log -Text "An error occured during adding server replicated from to output file" -Error
                }
            }
        }
    }
}

Log -Text "Script ended"