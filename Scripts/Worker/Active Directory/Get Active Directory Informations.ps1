# **********************************************************************************
# Script to find all information regarding Active Directory.
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
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2022-02-01  Benoit Blais        Original version
# **********************************************************************************

Param(
    [Switch]$Debug = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

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
    If ($Debug) {
        $Output = "$(Get-Date) |"
        If($Error) {
            $Output += " ERROR   | $Text"
            Write-Host $Output -ForegroundColor Red
        }
        ElseIf($Warning) {
            $Output += " WARNING | $Text"
            Write-Host $Output -ForegroundColor Yellow
        }
        Else {
            $Output += " INFO    | $Text"
            Write-Host $Output -ForegroundColor Green
        }
    }
}

# **********************************************************************************

Log -Text "Script Begin"

#Validate if Active Directory module is currently loaded in Powershell session.
Log -Text "Validating if Active Directory module is loaded in the currect Powershell session"
If (!(Get-Module | Where-Object {$_.Name -eq "ActiveDirectory"})){

    #Active Directory is not currently loaded in Powershell session.
    Log -Text "Active Directory is not currently loaded in Powershell session" -Warning
    If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) { 
        
        #Active Directory module installed on that computer.
        Log -Text "Active Directory module installed on that computer"
        #Trying to import Active Directory module.
        Log -Text "Trying to import Active Directory module"
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
        Log -Text "ctive Directory module is not installed on the current computer" -Error
        #Because this script can't be run without this module, the script execution is stop.
        Break
    }
}
Else {

    #Active Directory module is loaded in the current Powershell session.
    Log -Text "Active Directory module is loaded in the current Powershell session"

}

#Get currently logged domain information.
Log -Text "Get currently logged domain information"
Try { 
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()  
} 
Catch { 
      Log "Cannot connect to current Domain" -Error
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
   Log -Text "No Domain Controller found" -Error
   Break
}

Log -Text "Domain Controllers Discovered"

#Get all informations regarding Active Directory Forest.
#This information will be display at the end of the script.
Log -Text "Getting Active Directory Forest informations"
Try {
    $ForestInfo = Get-ADForest 
}
Catch {
    Log -Text "An error occured during getting Active Directory Forest informations" -Error
}

#Get all informations regarding Active Directory Domain.
#This information will be display at the end of the script.
Log -Text "Getting Active Directory Domain informations"
Try {
    $DomainInfo = Get-ADDomain 
}
Catch {
    Log -Text "An error occured during getting Active Directory Domain informations" -Error
}

#Get Active Directory Schema Version.
Log -Text "Getting Active Directory Schema version"
Try {
    $ADVer = Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion | Select objectVersion
    $ADNUM = $ADVer -replace "@{objectVersion=","" -replace "}",""
}
Catch {
    Log -Text "An error occured during getting Active Directory Schema Version" -Error
}

#Converting Schema Version to Windows Server version.
If ($ADNum -eq '88') {$SchemaVersion = 'Windows Server 2019'}
ElseIf ($ADNum -eq '87') {$SchemaVersion = 'Windows Server 2016'}
ElseIf ($ADNum -eq '69') {$SchemaVersion = 'Windows Server 2012 R2'}
ElseIf ($ADNum -eq '56') {$SchemaVersion = 'Windows Server 2012'}
ElseIf ($ADNum -eq '47') {$SchemaVersion = 'Windows Server 2008 R2'}
ElseIf ($ADNum -eq '44') {$SchemaVersion = 'Windows Server 2008'}
ElseIf ($ADNum -eq '31') {$SchemaVersion = 'Windows Server 2003 R2'}
ElseIf ($ADNum -eq '30') {$SchemaVersion = 'Windows Server 2003'}

Write-Host "Active Directory Infomations" -ForegroundColor Cyan
Write-Host "Forest Name                        : $($ForestInfo.Name)"
Write-Host "Domain Name                        : $($DomainInfo.Name)"
Write-Host "NetBios Name                       : $($DomainInfo.NetBIOSName)"
Write-Host "Forest mode                        : $($ForestInfo.ForestMode)"
Write-Host "Domain Mode                        : $($DomainInfo.DomainMode)"
Write-Host "Active Directory Schema Version    : $($SchemaVersion)"
Write-Host "FSMO Roles" -ForegroundColor Cyan
Write-Host "Schema Master                      : $($ForestInfo.SchemaMaster)"
Write-Host "Domain Naming Master               : $($ForestInfo.DomainNamingMaster)"
Write-Host "Relative ID (RID) Master           : $($DomainInfo.RidMaster)"
Write-Host "Primary Domain Controller          : $($DomainInfo.PDCEmulator)"
Write-Host "Infrastructure Master              : $($DomainInfo.InfrastructureMaster )"

#Get the size of SysVol Folder
$SysVolDetails = @()
ForEach ($DC in $DCList) {

    #Get SysVol folder location
    Try {
        Log -Text "Getting SysVol Folder location"
        $SysVolPath = Invoke-Command -ComputerName $DC -ScriptBlock {Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters -Name "SysVol" | Select-Object -ExpandProperty SysVol}
    }
    Catch {
        Log -Text "An error occured during getting SysVol folder location"
    }


    If (Test-Path $SysVolPath) {
        $Size = Get-ChildItem $SysVolPath -Recurse | Measure-Object -Sum Length | Select-Object Sum
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
    
    $Object = "" |  Select-Object Name,
                                  Path,
                                  Size
    $Object.Name = $DC
    $Object.Path = $($SysVolPath)
    $Object.Size = "$($Size)$($Metric)"
    $SysVolDetails += $Object

}
Write-Host "SysVol Folder Infomations" -ForegroundColor Cyan
$SysVolDetails | Format-Table -AutoSize

#Get details configuration for Domain Controller.
$DCDetails = @()
Log -Text "Get details configuration for every Domain Controller"
ForEach ($DC in $DCList) {
    Try {
        $DomainController = $Null
        #Getting details informations for specefic Domain Controller.
        Log -Text "Getting details informations for $($DC)"
        $DomainController = Get-ADDomainController -Identity $DC
    }
    Catch {
        Log -Text "Unable to get details infomations for $($DC)" -Error
    }
    #Build an array with the desired properties for Domain Controllers
    If ($DomainController -ne $Null) {
        $Object = "" |  Select-Object Name,
                                    IPAddress,
                                    OperatingSystem,
                                    Site,
                                    GlobalCatalog,
                                    ReadOnly
        $Object.Name = $DomainController.Name
        $Object.IPAddress = $DomainController.IPv4Address
        $Object.OperatingSystem = $DomainController.OperatingSystem 
        $Object.Site = $DomainController.Site
        $Object.GlobalCatalog = $DomainController.IsGlobalCatalog
        $Object.ReadOnly = $DomainController.IsReadOnly
        $DCDetails += $Object
    }
}

Write-Host "Domain Controllers" -ForegroundColor Cyan
$DCDetails | Format-Table -AutoSize

#Get Sites and Services informations.
Try {
    #Get Active Directory Replication Site.
    Log -Text "Getting Active Directory Replication Site"
    $ADSites = Get-ADReplicationSite -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Site" -Error
}
Try {
    #Get Active Directory Replication Subnet.
    Log -Text "Getting Active Directory Replication Subnet"
    $ADSubnets = Get-ADReplicationSubnet -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Subnet" -Error
}
Try {
    #Get Active Directory Replication Connection.
    Log -Text "Getting Active Directory Replication Connection"
    $AdReplicationConnections = Get-ADReplicationConnection -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Connection" -Error
}
Try {
    #Get Active Directory Replication Site Link.
    Log -Text "Getting Active Directory Replication Site Link"
    $ADReplicationSiteLinks = Get-ADReplicationSiteLink -Filter *
}
Catch {
    Log -Text "An error occured during getting Active Directory Replication Site Link" -Error
}

Write-Host "Active Directory Sites & Services Infomations" -ForegroundColor Cyan
Write-Host "Inter-Site Transport" -ForegroundColor DarkCyan
ForEach ($ADReplicationSiteLink in $ADReplicationSiteLinks) {
    Write-Host "Name                               : $($ADReplicationSiteLink.Name)"
    Write-Host " Cost                              : $($ADReplicationSiteLink.Cost)"
    Write-Host " Replication Frequency In Minutes  : $($ADReplicationSiteLink.ReplicationFrequencyInMinutes)"
    Write-Host " Sites                             : $(($ADReplicationSiteLink.SitesIncluded[0].Split(",") | Select-Object -First 1).Replace("CN=",''))"
    For ($i=1; $i -lt ($ADReplicationSiteLink.SitesIncluded).Count; $i++) {
        Write-Host "                                     $(($ADReplicationSiteLink.SitesIncluded[$i].Split(",") | Select-Object -First 1).Replace("CN=",''))"
    }
 }
 Write-Host "Subnets" -ForegroundColor DarkCyan
 ForEach ($ADSubnet in $ADSubnets) {
    Write-Host "Name                               : $($ADSubnet.Name)"
    If ($ADSubnet.Site -ne $Null) {
        Write-Host " Site                              : $((($ADSubnet.Site).Split(",") | Select-Object -First 1).Replace("CN=",''))"
    }
    Else {
        Write-Host " Site                              : "
    }
}
Write-Host "Sites" -ForegroundColor DarkCyan
ForEach ($ADSite in $ADSites) {
    Write-Host "Site Name                          : $($ADSite.Name)" 
    $Servers = $DCDetails | Where-Object {$_.Site -eq $ADSite.Name}
    ForEach ($Server in $Servers) {
        Write-Host " Server                            : $($Server.Name)"
        $FromServers = $AdReplicationConnections | Where-Object {$_.ReplicateToDirectoryServer -match $Server.Name} | Select-Object ReplicateFromDirectoryServer

        If ($FromServers -eq $Null) {
            Write-Host " Replicated from                   : "
        }
        ElseIf ($FromServers.Length -eq 1) {
            Write-Host "  Replicated from                  : $(($FromServers.ReplicateFromDirectoryServer.Split(",") | Select-Object -Skip 1 | Select-Object -First 1).Replace("CN=",''))"
        }
        Else {
            Write-Host "  Replicated from                  : $(($FromServers[0].ReplicateFromDirectoryServer.Split(",") | Select-Object -Skip 1 | Select-Object -First 1).Replace("CN=",''))"
            For ($i=1; $i -lt $FromServers.Length; $i++) {
                Write-Host "                                     $(($FromServers[$i].ReplicateFromDirectoryServer.Split(",") | Select-Object -Skip 1 | Select-Object -First 1).Replace("CN=",''))"
            }
        }
    }
}

Log -Text "Script ended"