<#
**********************************************************************************
Script to get DNS zone informations.
**********************************************************************************

.SYNOPSIS
Script to get DNS zone informations. 

Version 1.0 of this script.

.DESCRIPTION
This script is use to get DNS zone information like name, numbers of records... 

This script accepts 2 parameters.
-debug       This will generate display details informations in the Powershell window and a log file with the information related to the script execution.
-output      This will generate an output file instead of displaying information in the Powershell window.

WARNING:
This script needs to be run directly on a DNS server and needs to be run "AS ADMINISTRATOR".

.EXAMPLE
./Get_DNS_Zone_Informations.ps1 
./Get_DNS_Zone_Informations.ps1 -debug
./Get_DNS_Zone_Informations.ps1 -output

.NOTES
Author: Benoit Blais

.LINK
https://github.com/benyboy84/Powershell

#>

Param(
    [Switch]$Debug = $False,
    [Switch]$Output = $False
)

#Default action when an error occured
$ErrorActionPreference = "Stop"

#Log file
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Log = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$Outfile = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).txt"

# **********************************************************************************

#Log function will allow to display colored information in the PowerShell window and
#a log file with the information related to the script execution. if debug mode is $TRUE.
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
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }ElseIf($Warning) {
            Write-Host $Text -ForegroundColor Yellow
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }Else {
            Write-Host $Text -ForegroundColor Green
            Try {Add-Content $Log "$(Get-Date) | $Text"} Catch {$Null}
        }
    }
}

# **********************************************************************************

Log -Text "Script begin"

#Delete output files if they already exist.
Log -Text "Validating if outputs files already exists"
If (Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")}){
    #Output files exists, we will try to delete it.
    Log -Text "Deleting old output files"
    Try {
        Get-ChildItem -Path $ScriptPath | Where-Object {($_.Name -match "$($ScriptName)") -and ($_.Name -notmatch "$($ScriptName).ps1") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).log") -and ($_.Name -notmatch "$($ScriptName)_$($TimeStamp).txt")} | Remove-Item
    }
    Catch {
        Log -Text "An error occured when deleting old output files" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
    }
}

#Getting all DNS zone(s).
Log -Text "Getting all DNS zone(s)"
Try {
    $DNSZones = Get-DnsServerZone | Where-Object {!($_.IsAutoCreated)}
}
Catch {
    Log -Text "An error occured during getting all DNS zone(s)." -Error
    Log -Text "$($PSItem.Exception.Message)" -Error
    #Because this script can't run without the DNS zone(s) information, the script execution is stop.
    Break
}

$Text = "DNS zone(s) informations"
Write-Host $Text -ForegroundColor Cyan
If ($Output) {

    Log -Text "Adding information to the output file: $($Text)"
    Try {
        $Text | Out-File -FilePath $Outfile -Append -Encoding utf8 -Width 3000
    } 
    Catch {
        Log -Text 'An error occured during adding information to the output file' -Error
    }

}

$Text = "DNS Forward Zone(s) Informations"
Write-Host $Text -ForegroundColor DarkCyan
If ($Output) {

    Log -Text "Adding information to the output file: $($Text)"
    Try {
        $Text | Out-File -FilePath $Outfile -Append -Encoding utf8 -Width 3000
    } 
    Catch {
        Log -Text 'An error occured during adding information to the output file' -Error
    }

}

#Looping through each forward zone to get informations.
Log -Text "Looping through each forward zone to get informations"
$ForwardZone = @()
ForEach ($DNSZone in ($DNSZones | Where-Object {!($_.IsReverseLookupZone)})) {

    $Object = "" | Select-Object Name,
                                 Status,
                                 Type,
                                 DirectoryServiceIntegrated,
                                 DynamicUpdates, 
                                 Aging, 
                                 NoRefreshInterval,
                                 RefreshInterval,
                                 SOA_RefreshInterval,
                                 SOA_RetryInterval,
                                 SOA_ExpiresAfter,
                                 SOA_MinimumTimeToLive,
                                 ZoneNameServer, 
                                 StaticHost, 
                                 DynamicHost,
                                 CNAME

    $Object.Name = $DNSZone.ZoneName
    $Object.Type = $DNSZone.ZoneType
    $Object.DirectoryServiceIntegrated = $DNSZone.IsDsIntegrated
    
    #Because no Powershell command are available to get these informations, we will use WMI.
    #Getting zone information from WMI.
    Log -Text "Getting zone $($DNSZone.ZoneName) informations from WMI"
    Try {
        $Info = $Null
        $Info = Get-WmiObject MicrosoftDNS_Zone -Namespace Root\MicrosoftDNS | Where-object {$_.name -eq $DNSZone.ZoneName}
        If ($Info.Paused -match "False") {
            $Object.Status = "Running"
        }
        Else {
            $Object.Status = "Paused"
        }
            
        Switch ($Info.AllowUpdate) {
            0 {$Object.DynamicUpdates = "None"}
            1 {$Object.DynamicUpdates = "Nonsecure and secure"}
            2 {$Object.DynamicUpdates = "Secure only"}
        }
    }
    Catch{
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) informations from WMI" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.Status= "Error"
        $Object.DynamicUpdates = "Error"
    }

    #Getting zone aging informations.
    Log -Text "Getting zone $($DNSZone.ZoneName) aging informations"
    Try {
        $Aging = $Null
        $Aging = Get-DNSServerZoneAging -Name $DNSZone.ZoneName
        $Object.Aging = $Aging.AgingEnabled
        $Object.NoRefreshInterval = $Aging.NoRefreshInterval
        $Object.RefreshInterval = $Aging.RefreshInterval
    }
    Catch {
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) aging informations" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.Aging = "Error"
        $Object.NoRefreshInterval = "Error"
        $Object.RefreshInterval = "Error"
    }

    #Getting zone Start of Authority (SOA) informations.
    Log -Text "Getting zone $($DNSZone.ZoneName) Start of Authority (SOA) informations"
    Try {
        $SOA = $Null
        $SOA = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType Soa
        $Object.SOA_RefreshInterval = "$($SOA.RecordData.RefreshInterval.Days) : $($SOA.RecordData.RefreshInterval.Hours) : $($SOA.RecordData.RefreshInterval.Minutes) : $($SOA.RecordData.RefreshInterval.Seconds)"
        $Object.SOA_RetryInterval = "$($SOA.RecordData.RetryDelay.Days) : $($SOA.RecordData.RetryDelay.Hours) : $($SOA.RecordData.RetryDelay.Minutes) : $($SOA.RecordData.RetryDelay.Seconds)"
        $Object.SOA_ExpiresAfter = "$($SOA.RecordData.ExpireLimit.Days) : $($SOA.RecordData.ExpireLimit.Hours) : $($SOA.RecordData.ExpireLimit.Minutes) : $($SOA.RecordData.ExpireLimit.Seconds)"
        $Object.SOA_MinimumTimeToLive = "$($SOA.RecordData.MinimumTimeToLive.Days) : $($SOA.RecordData.MinimumTimeToLive.Hours) : $($SOA.RecordData.MinimumTimeToLive.Minutes) : $($SOA.RecordData.MinimumTimeToLive.Seconds)"
    }
    Catch {
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) Start of Authority (SOA) informations" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.SOA_RefreshInterval = "Error"
        $Object.SOA_RetryInterval = "Error"
        $Object.SOA_ExpiresAfter = "Error"
        $Object.SOA_MinimumTimeToLive = "Error"
    }

    #Getting zone name server(s) informations.
    Log -Text "Getting zone $($DNSZone.ZoneName) delegation informations"
    Try {
        $ZoneNameServer = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType NS | Where-Object {$_.Hostname -eq "@"} | Select-Object RecordData -ExpandProperty RecordData | Select-Object NameServer -ExpandProperty NameServer
        $Object.ZoneNameServer = $ZoneNameServer
    }
    Catch {
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) delegation informations" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.ZoneNameServer = = "Error"
    }

    #Getting all static A records for that zone.
    Log -Text "Getting all static A records for zone $($DNSZone.ZoneName)"
    Try {
        $StaticHost = $Null
        [Array]$StaticHost = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType A  | Where-Object {($_.Timestamp -eq $Null) -and ($_.Hostname -ne "@") -and ($_.Hostname -ne "DomainDnsZones") -and ($_.Hostname -ne "ForestDnsZones")}
        $Object.StaticHost = $StaticHost.Count
    }
    Catch {
        Log -Text "An error occured during getting all static A records for zone $($DNSZone.ZoneName)" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.StaticHost = "Error"
    }

    #Getting all dynamic A records for that zone.
    Log -Text "Getting all dynamic A records for zone $($DNSZone.ZoneName)"
    Try {
        $DynamicHost = $Null
        [Array]$DynamicHost = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType A  | Where-Object {($_.Timestamp -ne $Null) -and ($_.Hostname -ne "@") -and ($_.Hostname -ne "DomainDnsZones") -and ($_.Hostname -ne "ForestDnsZones")}
        $Object.DynamicHost = $DynamicHost.Count
    }
    Catch {
        Log -Text "An error occured during getting all dynamic A records for zone $($DNSZone.ZoneName)" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.DynamicHost = "Error"
    }

    #Getting all CNAME records for that zone.
    Log -Text "Getting all CNAME records for zone $($DNSZone.ZoneName)"
    Try {
        $CNAME = $Null
        [Array]$CNAME = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType CNAME
        $Object.CNAME = $CNAME.Count
    }
    Catch {
        Log -Text "An error occured during getting all CNAME records for zone $($DNSZone.ZoneName)" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.CNAME = "Error"
    }



    $ForwardZone += $Object

}

$ForwardZone 

If ($Output) {

    Log -Text "Adding information to the output file: $($Text)"
    Try {
        $ForwardZone | Format-Table * -AutoSize | Out-File -FilePath $Outfile -Append -Encoding utf8 -Width 3000
    } 
    Catch {
        Log -Text 'An error occured during adding information to the output file' -Error
    }

}

$Text = "DNS Reverse Zone(s) Informations"
Write-Host $Text -ForegroundColor DarkCyan
If ($Output) {

    Log -Text "Adding information to the output file: $($Text)"
    Try {
        $Text | Out-File -FilePath $Outfile -Append -Encoding utf8 -Width 3000
    } 
    Catch {
        Log -Text 'An error occured during adding information to the output file' -Error
    }

}

#Looping through each reverse zone to get informations.
Log -Text "Looping through each reverse zone to get informations"
$ReverseZone = @()
ForEach ($DNSZone in ($DNSZones | Where-Object {$_.IsReverseLookupZone})) {

    $Object = "" | Select-Object Name,
                                 Status,
                                 Type,
                                 DirectoryServiceIntegrated,
                                 DynamicUpdates, 
                                 Aging, 
                                 NoRefreshInterval,
                                 RefreshInterval,
                                 SOA_RefreshInterval,
                                 SOA_RetryInterval,
                                 SOA_ExpiresAfter,
                                 SOA_MinimumTimeToLive,
                                 ZoneNameServer, 
                                 StaticPTR, 
                                 DynamicPTR

    $Object.Name = $DNSZone.ZoneName
    $Object.Type = $DNSZone.ZoneType
    $Object.DirectoryServiceIntegrated = $DNSZone.IsDsIntegrated
    
    #Because no Powershell command are available to get these informations, we will use WMI.
    #Getting zone information from WMI.
    Log -Text "Getting zone $($DNSZone.ZoneName) informations from WMI"
    Try {
        $Info = $Null
        $Info = Get-WmiObject MicrosoftDNS_Zone -Namespace Root\MicrosoftDNS | Where-object {$_.name -eq $DNSZone.ZoneName}
        If ($Info.Paused -match "False") {
            $Object.Status = "Running"
        }
        Else {
            $Object.Status = "Paused"
        }
            
        Switch ($Info.AllowUpdate) {
            0 {$Object.DynamicUpdates = "None"}
            1 {$Object.DynamicUpdates = "Nonsecure and secure"}
            2 {$Object.DynamicUpdates = "Secure only"}
        }
    }
    Catch{
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) informations from WMI" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.Status= "Error"
        $Object.DynamicUpdates = "Error"
    }

    #Getting zone aging informations.
    Log -Text "Getting zone $($DNSZone.ZoneName) aging informations"
    Try {
        $Aging = $Null
        $Aging = Get-DNSServerZoneAging -Name $DNSZone.ZoneName
        $Object.Aging = $Aging.AgingEnabled
        $Object.NoRefreshInterval = $Aging.NoRefreshInterval
        $Object.RefreshInterval = $Aging.RefreshInterval
    }
    Catch {
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) aging informations" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.Aging = "Error"
        $Object.NoRefreshInterval = "Error"
        $Object.RefreshInterval = "Error"
    }

    #Getting zone Start of Authority (SOA) informations.
    Log -Text "Getting zone $($DNSZone.ZoneName) Start of Authority (SOA) informations"
    Try {
        $SOA = $Null
        $SOA = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType Soa
        $Object.SOA_RefreshInterval = "$($SOA.RecordData.RefreshInterval.Days) : $($SOA.RecordData.RefreshInterval.Hours) : $($SOA.RecordData.RefreshInterval.Minutes) : $($SOA.RecordData.RefreshInterval.Seconds)"
        $Object.SOA_RetryInterval = "$($SOA.RecordData.RetryDelay.Days) : $($SOA.RecordData.RetryDelay.Hours) : $($SOA.RecordData.RetryDelay.Minutes) : $($SOA.RecordData.RetryDelay.Seconds)"
        $Object.SOA_ExpiresAfter = "$($SOA.RecordData.ExpireLimit.Days) : $($SOA.RecordData.ExpireLimit.Hours) : $($SOA.RecordData.ExpireLimit.Minutes) : $($SOA.RecordData.ExpireLimit.Seconds)"
        $Object.SOA_MinimumTimeToLive = "$($SOA.RecordData.MinimumTimeToLive.Days) : $($SOA.RecordData.MinimumTimeToLive.Hours) : $($SOA.RecordData.MinimumTimeToLive.Minutes) : $($SOA.RecordData.MinimumTimeToLive.Seconds)"
    }
    Catch {
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) Start of Authority (SOA) informations" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.SOA_RefreshInterval = "Error"
        $Object.SOA_RetryInterval = "Error"
        $Object.SOA_ExpiresAfter = "Error"
        $Object.SOA_MinimumTimeToLive = "Error"
    }

    #Getting zone name server(s) informations.
    Log -Text "Getting zone $($DNSZone.ZoneName) delegation informations"
    Try {
        $ZoneNameServer = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType NS | Where-Object {$_.Hostname -eq "@"} | Select-Object RecordData -ExpandProperty RecordData | Select-Object NameServer -ExpandProperty NameServer
        $Object.ZoneNameServer = $ZoneNameServer
    }
    Catch {
        Log -Text "An error occured during getting zone $($DNSZone.ZoneName) delegation informations" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.ZoneNameServer = = "Error"
    }

    #Getting all static PTR records for that zone.
    Log -Text "Getting all static PTR records for zone $($DNSZone.ZoneName)"
    Try {
        $StaticPTR = $Null
        [Array]$StaticPTR = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType PTR  | Where-Object {($_.Timestamp -eq $Null) -and ($_.Hostname -ne "@") -and ($_.Hostname -ne "DomainDnsZones") -and ($_.Hostname -ne "ForestDnsZones")}
        $Object.StaticPTR = $StaticPTR.Count
    }
    Catch {
        Log -Text "An error occured during getting all static PTR records for zone $($DNSZone.ZoneName)" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.StaticPTR = "Error"
    }

    #Getting all dynamic PTR records for that zone.
    Log -Text "Getting all dynamic PTR records for zone $($DNSZone.ZoneName)"
    Try {
        $DynamicPTR = $Null
        [Array]$DynamicPTR = Get-DnsServerResourceRecord -ZoneName $DNSZone.ZoneName -RRType PTR  | Where-Object {($_.Timestamp -ne $Null) -and ($_.Hostname -ne "@") -and ($_.Hostname -ne "DomainDnsZones") -and ($_.Hostname -ne "ForestDnsZones")}
        $Object.DynamicPTR = $DynamicPTR.Count
    }
    Catch {
        Log -Text "An error occured during getting all dynamic PTR records for zone $($DNSZone.ZoneName)" -Error
        Log -Text "$($PSItem.Exception.Message)" -Error
        $Object.DynamicPTR = "Error"
    }

    $ReverseZone += $Object

}

$ReverseZone

If ($Output) {

    Log -Text "Adding information to the output file: $($Text)"
    Try {
        $ReverseZone | Format-Table * -AutoSize | Out-File -FilePath $Outfile -Append -Encoding utf8 -Width 3000
    } 
    Catch {
        Log -Text 'An error occured during adding information to the output file' -Error
    }

}

Log -Text "Script end"