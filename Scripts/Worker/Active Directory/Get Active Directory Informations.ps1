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

#Getting Active Directory Objects.
Log -Text "Getting Active Directory Objects"
Try {
    #Get all Active Directory computer objects.
    Log -Text "Getting Active Directory computers objects"
    $Computers = [Array](Get-ADComputer -Filter *).Count
}
Catch {
    Log -Text "An error occured during getting Active Directory computers objects" -Error
}
Try {
    #Get all Active Directory users objects .
    Log -Text "Getting Active Directory users objects"
    $Users = [Array](Get-ADUser -filter *).Count
}
Catch {
    Log -Text "An error occured during getting Active Directory users objects" -Error
}
Try {
    #Get all Active Directory groups objects.
    Log -Text "Getting Active Directory groups objects"
    $Groups = [Array](Get-ADGroup -Filter *).Count
}
Catch {
    Log -Text "An error occured during getting Active Directory groups objects" -Error
}
Try {
    #Get all Active Directory GPO objects.
    Log -Text "Getting Active Directory GPO objects"
    $GPO = [Array](Get-GPO -All).Count
}
Catch {
    Log -Text "An error occured during getting Active Directory GPO objects" -Error
}

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


ForEach ($DC in $DCList) {

    Get-ADDomainController -Identity $DC.Name

}

Write-Host ""
Write-Host "Active Directory Infomations" -ForegroundColor Cyan
Write-Host "Forest Name                        : $($ForestInfo.Name)"
Write-Host "Domain Name                        : $($DomainInfo.Name)"
Write-Host "NetBios Name                       : $($DomainInfo.NetBIOSName)"
Write-Host "Forest mode                        : $($ForestInfo.ForestMode)"
Write-Host "Domain Mode                        : $($DomainInfo.DomainMode)"
Write-Host "Active Directory Schema Version    : $($SchemaVersion)"
Write-Host ""
Write-Host "FSMO Roles" -ForegroundColor Cyan
Write-Host "Schema Master                      : $($ForestInfo.SchemaMaster)"
Write-Host "Domain Naming Master               : $($ForestInfo.DomainNamingMaster)"
Write-Host "Relative ID (RID) Master           : $($DomainInfo.RidMaster)"
Write-Host "Primary Domain Controller          : $($DomainInfo.PDCEmulator)"
Write-Host "Infrastructure Master              : $($DomainInfo.InfrastructureMaster )"
Write-Host ""
Write-Host "Active Directory objects statistics" -ForegroundColor Cyan
Write-Host "Computers                          : $($Computers.count)"
Write-Host "Users                              : $($Users.count)"
Write-Host "Groups                             : $($Groups.count)"
Write-Host "GPO                                : $($GPO.count)"
Write-Host ""
Write-Host "Active Directory Sites & Services Infomations" -ForegroundColor Cyan
ForEach ($ADSite in $ADSites) {
  Write-Host "Site Name                          : $($ADSite.Name)" 
  $SiteSubnets = $ADSubnets | Where-Object {$_.Site -match $ADSite.Name}
  If ($SiteSubnets -eq $Null) {
    Write-Host " Subnet                            : "
  }
  ElseIf ($SiteSubnets.Length -eq 1) {
    Write-Host " Subnet                            : $($SiteSubnets.Name)"
  }
  Else {
    Write-Host " Subnet                            : $($SiteSubnets[0].Name)"
    For ($i=1; $i -lt $SiteSubnets.Length; $i++) {
    Write-Host "                                     $($SiteSubnets[$i].Name)"
    }
  }
  $SiteLinks = $ADReplicationSiteLinks | Where-Object {$_.SitesIncluded -match $ADSite.Name}
  If ($SiteLinks -eq $Null) {
    Write-Host " Inter-Site Transport              : "
  }
  ElseIf ($SiteLinks.Length -eq 1) {
    Write-Host " Inter-Site Transport              : $($SiteLinks.Name)"
    Write-Host "  Cost                             : $($SiteLinks.Cost)"
    Write-Host "  Replication Frequency In Minutes : $($SiteLinks.ReplicationFrequencyInMinutes)"
  }
  Else {
    ForEach ($SiteLink in $SiteLinks) {
        Write-Host " Inter-Site Transport              : $($SiteLink.Name)"
        Write-Host "  Cost                             : $($SiteLink.Cost)"
        Write-Host "  Replication Frequency In Minutes : $($SiteLink.ReplicationFrequencyInMinutes)"
    }
  }
  $Servers = Get-ADDomainController | Where-Object {$_.Site -eq $ADSite.Name}
  ForEach ($Server in $Servers) {
    
    Write-Host " Server                            : $($Server.Name)"
    $FromServers = $AdReplicationConnections | Where-Object {$_.ReplicateToDirectoryServer -match $Server.Name} | Select-Object ReplicateFromDirectoryServer

    If ($FromServers -eq $Null) {
        Write-Host " Replicated from                   : "
    }
    ElseIf ($FromServers.Length -eq 1) {
        Write-Host " Replicated from                   : $($FromServers.Name)"
    }
    Else {
        Write-Host " Replicated from                   : $($FromServers[0].Name)"
        For ($i=1; $i -lt $FromServers.Length; $i++) {
        Write-Host "                                     $($FromServers[$i].Name)"
        }
      }
 
    
  }

}

