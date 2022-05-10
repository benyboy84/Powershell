# *******************************************************************************
# Script to get a total inventory of the current computer.
# This script will get hardware, software, roles and features, odbc, printer...
# 
# This script will create a .txt file with the local computer name.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-10-11  Benoit Blais        Creation
# *******************************************************************************

# **********************************************************************************

# This list contain the services to be excluded from the report.
$ExcludedServices = @("AdobeARMservice","AeLookupSvc","AJRouter","ALG","aoservice","AppIDSvc","Appinfo","AppMgmt","AppReadiness","AppVClient","AppXSvc","AssignedAccessManagerSvc","AudioEndpointBuilder","AudioSrv","AxInstSV","BcastDVRUserService_ad3f9",
                     "BDESVC","BFE","BITS","BluetoothUserService_ad3f9","BrokerInfrastructure","Browser","BTAGService","BthAvctpSvc","bthserv","camsvc","CaptureService_ad3f9","cbdhsvc_ad3f9","CcmExec","CDPSvc","CDPUserSvc_ad3f9","CertPropSvc",
                     "ClickToRunSvc","client_service","ClipSVC","CmRcService","COMSysApp","ConsentUxUserSvc_ad3f9","CoreMessagingRegistrar","cphs","cplspcon","CryptSvc","CscService","cudanacsvc","DcomLaunch","defragsvc","DeviceAssociationService",
                     "DeviceInstall","DevicePickerUserSvc_ad3f9","DevicesFlowUserSvc_ad3f9","DevQueryBroker","Dhcp","diagnosticshub.standardcollector.service","diagsvc","DiagTrack","DisplayEnhancementService","DmEnrollmentSvc","dmwappushservice",
                     "Dnscache","Dolby DAX2 API Service","DoSvc","dot3svc","DPS","DsmSvc","DsSvc","DusmSvc","EapHost","EFS","ehRecvr","ehSched","embeddedmode","EntAppSvc","esifsvc","eTSrv","eventlog","EventSystem","EvtEng","Fax","fdPHost","FDResPub",
                     "fhsvc","FontCache","FontCache3.0.0.0","FortiSslvpnDaemon","FrameServer","ftnlsv3hv","ftscanmgrhv","GoogleChromeElevationService","gpsvc","GraphicsPerfSvc","gupdate","gupdatem","hidserv","hkmsvc","HomeGroupProvider","HvHost",
                     "IBMPMSVC","iClarityQoSService","icssvc","idsvc","igfxCUIService2.0.0.0","IKEEXT","InstallService","IPBusEnum","iphlpsvc","IpxlatCfgSvc","irmon","KDService","KeyIso","KtmRm","LanmanServer","LanmanWorkstation","LBTServ",
                     "Lenovo Instant On","lfsvc","LicenseManager","LITSSVC","lltdsvc","lmhosts","LMIGuardianSvc","LMIMaint","LogMeIn","lpasvc","LPlatSvc","lppsvc","LSM","LxpSvc","MapsBroker","Mcx2Svc","MessagingService_ad3f9","MMCSS","MozillaMaintenance",
                     "MpsSvc","MSCamSvc","MSDTC","MSiSCSI","msiserver","napagent","NaturalAuthentication","NcaSvc","NcbService","NcdAutoSetup","Netlogon","Netman","netprofm","NetSetupSvc","NetTcpPortSharing","NgcCtnrSvc","NgcSvc","NlaSvc","nsi",
                     "nsverctl","OneSyncSvc_ad3f9","ose","osppsvc","ot3svc","p2pimsvc","p2psvc","PcaSvc","PeerDistSvc","perceptionsimulation","PerfHost","PhoneSvc","PimIndexMaintenanceSvc_ad3f9","pla","PlugPlay","Pml","PNRPAutoReg","PNRPsvc",
                     "PolicyAgent","Power","PrintNotify","PrintWorkflowUserSvc_ad3f9","ProfSvc","ProtectedStorage","PushToInstall","QWAVE","RasAuto","RasMan","RegSrvc","RemoteAccess","RemoteRegistry","RetailDemo","RmSvc","RpcEptMapper","RpcLocator",
                     "RpcSs","RtkAudioService","SamSs","SCardSvr","ScDeviceEnum","Schedule","SCPolicySvc","SDRSVC","seclogon","SecurityHealthService","SEMgrSvc","SENS","Sense","SensorDataService","SensorService","SensrSvc","SessionEnv","SgrmBroker",
                     "SharedAccess","SharedRealitySvc","ShellHWDetection","shpamsvc","smphost","SmsRouter","smstsmgr","SNMPTRAP","SnowInventoryAgent5","spectrum","Spooler","sppsvc","sppuinotify","SSDPSRV","ssh-agent","SstpSvc","StateRepository",
                     "stisvc","StorSvc","SUService","svsvc","swprv","SynTPEnhService","SysMain","SystemEventsBroker","TabletInputService","TapiSrv","TBS","TermService","Themes","THREADORDER","ThunderboltService","TieringEngineService","TimeBrokerSvc",
                     "TokenBroker","TPHKLOAD","TrkWks","TrustedInstaller","tzautoupdate","UevAgentService","ufad-ws60","UI0Detect","UmRdpService","UnistoreSvc_ad3f9","upnphost","UserDataSvc_ad3f9","UserManager","UsoSvc","uvnc_service","UxSms",
                     "VacSvc","VaultSvc","vds","vmicguestinterface","vmicheartbeat","vmickvpexchange","vmicrdv","vmicshutdown","vmictimesync","vmicvmsession","vmicvss","VMUSBArbService","vmwsprrdpwks","VSS","W32Time","WaaSMedicSvc","WalletService",
                     "WarpJITSvc","WatAdminSvc","wbengine","WbioSrvc","Wcmsvc","wcncsvc","WcsPlugInService","Wcsvc","WdiServiceHost","WdiSystemHost","WdNisSvc","WebClient","Wecsvc","WEPHOSTSVC","wercplsupport","WerSvc","WFDSConMgrSvc","WiaRpc",
                     "WinDefend","WinHttpAutoProxySvc","Winmgmt","WinRM","wisvc","Wlansvc","wlidsvc","wlpasvc","WManSvc","wmiApSrv","WMPNetworkSvc","workfolderssvc","WpcMonSvc","WPCSvc","WPDBusEnum","WpnService","WpnUserService_ad3f9","wscsvc",
                     "WSearch","wuauserv","wudfsvc","WwanSvc","XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","ZeroConfigService","RSoPProv","sacsvr","SNMP","UALSVC","WAS"                    
                     )

# This list contain the softwares to be excluded from the report.
$ExcludedSoftwares = @("Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.17","Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.40660","Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.40660",
                       "Microsoft Visual C++ 2019 X64 Additional Runtime - 14.22.27821","Microsoft Visual C++ 2019 X64 Minimum Runtime - 14.22.27821","Microsoft Visual C++ 2005 Redistributable (x64)",
                       "Microsoft Visual C++ 2005 Redistributable (x64)","Microsoft Visual C++ 2008 Redistributable - x64 9.0.21022","Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.6161",
                       "Microsoft Visual C++ 2008 Redistributable - x86 9.0.30729.4148","Microsoft Visual C++ 2008 Redistributable - x86 9.0.30729.6161","Microsoft Visual C++ 2010  x64 Redistributable - 10.0.40219",
                       "Microsoft Visual C++ 2010  x86 Redistributable - 10.0.40219","Microsoft Visual C++ 2010  x86 Runtime - 10.0.40219","Microsoft Visual C++ 2013 Redistributable (x64) - 12.0.21005",
                       "Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.21005","Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005","Microsoft Visual C++ 2015-2019 Redistributable (x64) - 14.20.27508",
                       "Microsoft Visual C++ 2015-2019 Redistributable (x86) - 14.20.27508","Microsoft Visual C++ 2019 X64 Additional Runtime - 14.20.27508","Microsoft Visual C++ 2019 X64 Minimum Runtime - 14.20.27508",
                       "Microsoft Visual C++ 2019 X86 Additional Runtime - 14.20.27508","Microsoft Visual C++ 2019 X86 Minimum Runtime - 14.20.27508"
                       )

# This list contain the ODBC to be excluded from the report.
$ExcludeODBC = @("dBASE Files","Excel Files","MS Access Database","CRD Samples","SampleApp","JavaSampleApp")

# This list contain the shares to be excluded from the report.
$ExcludedShares = @("Remote Admin","Default share","Remote IPC","Printer Drivers")

# This list contain the printers to be excluded from the report.
$ExcludedPrinters = @("Microsoft XPS Document Writer")
# ********************************************************************************** 

$ComputerName = $env:COMPUTERNAME

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$OutFile = "$($ScriptPath)\$($ComputerName).txt"

$ErrorActionPreference = "stop"

# **********************************************************************************
# Collect server inventory

Try{
    $ComputerOS = Get-WMIObject Win32_OperatingSystem -ComputerName $ComputerName | select-object Caption
    $ComputerInfoOperatingSystem = $ComputerOS.Caption
    }
Catch{
      $ComputerOS = "Unable to get operating system"
      }

Try{
    $ComputerIP = Get-WMIObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '*.*' }
    }
Catch{
      $ComputerIP = "Unable to get IP configuration"
      }
   
Try{
    $ComputerHW = Get-WMIObject -Class Win32_ComputerSystem -ComputerName $ComputerName | select Manufacturer,Model,NumberOfProcessors,@{Expression={$_.TotalPhysicalMemory / 1GB};Label="TotalPhysicalMemoryGB"}
    }
Catch{
      $ComputerHW = New-Object System.Object
      $ComputerHW | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "Unable to get hardware manufacturer" -Force
      $ComputerHW | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "Unable to get hardware model" -Force
      $ComputerHW | Add-Member -MemberType NoteProperty -Name "NumberOfProcessors" -Value "Unable to get no=umber of processors" -Force
      }
    
Try{
    $ComputerCPU = Get-WMIObject win32_processor -ComputerName $ComputerName | select DeviceID,Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors 
    }
Catch{
      $ComputerCPU = New-Object System.Object
      $ComputerCPU | Add-Member -MemberType NoteProperty -Name "DeviceID" -Value "Unable to get CPU device ID" -Force
      $ComputerCPU | Add-Member -MemberType NoteProperty -Name "Name" -Value "Unable to get CPU name" -Force
      $ComputerCPU | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "Unable to get CPU manufacturer" -Force
      $ComputerCPU | Add-Member -MemberType NoteProperty -Name "NumberOfCores" -Value "Unable to get CPU nomber of cores" -Force
      $ComputerCPU | Add-Member -MemberType NoteProperty -Name "NumberOfLogicalProcessors" -Value "Unable to get CPU number of logical processors" -Force
      }

Try{
    $ComputerDisks = Get-WMIObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName | select DeviceID,VolumeName,@{Expression={$_.Size / 1GB};Label="SizeGB"} 
    }
Catch{
      $ComputerDisks = New-Object System.Object
      $ComputerDisks | Add-Member -MemberType NoteProperty -Name "DeviceID" -Value "Unable to get disk device ID" -Force
      $ComputerDisks | Add-Member -MemberType NoteProperty -Name "VolumeName" -Value "Unable to get disk name" -Force
     }

Try{
    $ComputerSerial = (Get-WMIObject Win32_Bios -ComputerName $ComputerName).SerialNumber 
    } 
Catch{
      $ComputerSerial = "Unable to get serial number"
      }
            
$ComputerInfoManufacturer = $ComputerHW.Manufacturer 
$ComputerInfoModel = $ComputerHW.Model 
$ComputerInfoNumberOfProcessors = $ComputerHW.NumberOfProcessors 
$ComputerInfoProcessorID = $ComputerCPU.DeviceID 
$ComputerInfoProcessorManufacturer = $ComputerCPU.Manufacturer 
$ComputerInfoProcessorName = $ComputerCPU.Name 
$ComputerInfoNumberOfCores = $ComputerCPU.NumberOfCores 
$ComputerInfoNumberOfLogicalProcessors = $ComputerCPU.NumberOfLogicalProcessors 
$ComputerInfoRAM = $ComputerHW.TotalPhysicalMemoryGB 
$ComputerInfoDiskDrive = $ComputerDisks.DeviceID 
$ComputerInfoDriveName = $ComputerDisks.VolumeName 
$ComputerInfoSize = $ComputerDisks.SizeGB 
$ComputerInfo = New-Object System.Object
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "OperatingSystem" -Value "$ComputerInfoOperatingSystem"
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "IPv4" -Value "$ComputerIP"
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "$ComputerInfoManufacturer" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Model" -Value "$ComputerInfoModel" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Serial" -Value "$ComputerSerial" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfProcessors" -Value "$ComputerInfoNumberOfProcessors" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorID" -Value "$ComputerInfoProcessorID" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorManufacturer" -Value "$ComputerInfoProcessorManufacturer" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "ProcessorName" -Value "$ComputerInfoProcessorName" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfCores" -Value "$ComputerInfoNumberOfCores" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "NumberOfLogicalProcessors" -Value "$ComputerInfoNumberOfLogicalProcessors" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "RAM" -Value "$ComputerInfoRAM" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskDrive" -Value "$ComputerInfoDiskDrive" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "DriveName" -Value "$ComputerInfoDriveName" -Force 
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Size" -Value "$ComputerInfoSize" -Force 

$ComputerInfo | Out-File -FilePath $OutFile 


# **********************************************************************************
# Collect server softwares

Out-File -FilePath $OutFile -InputObject "------------------" -Append
Out-File -FilePath $OutFile -InputObject "SOFTWARES" -Append
Out-File -FilePath $OutFile -InputObject "------------------" -Append

$Result = @()
$OSIs64BitArch = ([System.Environment]::Is64BitOperatingSystem)
$OSArchString = if ( $OSIs64BitArch ) {"x64"} else {"x86"}

If ($OSArchString -like "x64") {
    Try {
         $Software = Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                     Select-Object DisplayName,DisplayVersion,Publisher |
                     Where-Object {(($_.DisplayName) -notin $ExcludedSoftwares) -and (($_.DisplayName) -ne $Null)}
         }                     
    Catch {}
    Try {
         $Software += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                      Select-Object DisplayName,DisplayVersion,Publisher |
                      Where-Object {(($_.DisplayName) -notin $ExcludedSoftwares) -and (($_.DisplayName) -ne $Null)}
         }
    Catch {}
} 
Else {
    Try {
         $Software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                     Select-Object DisplayName,DisplayVersion,Publisher |
                     Where-Object {(($_.DisplayName) -notin $ExcludedSoftwares) -and (($_.DisplayName) -ne $Null)}
         }
    Catch {}
}

ForEach ($Object in $Software) {
    $obj = "" |  Select-Object DisplayName,DisplayVersion,Publisher
    $obj.DisplayName = $Object.DisplayName
    $obj.DisplayVersion = $Object.DisplayVersion
    $obj.Publisher = $Object.Publisher
    $Result += $obj
}

$Result | Sort-Object -Property DisplayName | Format-Table -AutoSize | Out-File -FilePath $OutFile -Append


# **********************************************************************************
# Collect server roles and features

Out-File -FilePath $OutFile -InputObject "------------------" -Append
Out-File -FilePath $OutFile -InputObject "ROLES AND FEATURES" -Append
Out-File -FilePath $OutFile -InputObject "------------------" -Append

Try{
    $Features =  Get-WmiObject -Computer $ComputerName -query 'select * from Win32_ServerFeature where parentid=0' | foreach { $_.Name }
    } 
Catch {
       $Features = "Unable to get role and feature"
       }

$Features | Out-File -FilePath $OutFile -Append
Out-File -FilePath $OutFile -InputObject "" -Append

# **********************************************************************************
# Collect server services

Out-File -FilePath $OutFile -InputObject "--------" -Append
Out-File -FilePath $OutFile -InputObject "SERVICES" -Append
Out-File -FilePath $OutFile -InputObject "--------" -Append

$Result = @()

Try{
    $Services =  Get-WmiObject -Class Win32_Service -Computer $ComputerName | Where-Object {($_.Name -notin $ExcludedServices)}
    } 
Catch {
       Out-File -FilePath $OutFile -InputObject "Unable to get service" -Append 
       Out-File -FilePath $OutFile -InputObject "" -Append
       }

If ($Services >0) {
    ForEach ($Service in $Services) {
        
        $Details = Get-WmiObject win32_service | Select Name,DisplayName,Description,StartMode,State,PathName,StartName | where-object -Property name -like $Service.name
        $ServerServices = "" |  Select-Object Name,DisplayName,Description,StartMode,State,PathName,StartName
        $ServerServices.Name = $Details.Name
        $ServerServices.DisplayName = $Details.DisplayName
        $ServerServices.Description = $Details.Description
        $ServerServices.StartMode = $Details.StartMode
        $ServerServices.State = $Details.State
        $ServerServices.PathName = $Details.PathName
        $ServerServices.StartName = $Details.StartName  

        $Result += $ServerServices
        $Details = ""
    }
    $Result | Out-File -FilePath $OutFile -Append
}
Else {
    Out-File -FilePath $OutFile -InputObject "There is no service other than the usual ones." -Append
    Out-File -FilePath $OutFile -InputObject "" -Append
}

# **********************************************************************************
# Collect server ODBC

Out-File -FilePath $OutFile -InputObject "----" -Append
Out-File -FilePath $OutFile -InputObject "ODBC" -Append
Out-File -FilePath $OutFile -InputObject "----" -Append

$Result = @()

Try {
     $ODBC = Get-OdbcDsn -DsnType "System" | Select Name,DriverName,Attribute | Where-Object {($_.Name -notin $ExcludeODBC)}
     }
Catch {
       Out-File -FilePath $OutFile -InputObject "Unable to get ODBC" -Append 
       Out-File -FilePath $OutFile -InputObject "" -Append
       }               

If ($ODBC.count > 0) {
    ForEach ($Object in $ODBC) {
        $obj = "" |  Select-Object Name,DsnType,DriverName,Attribute
        $obj.Name = $Object.Name
        $obj.DsnType = $Object.DsnType
        $obj.DriverName = $Object.DriverName
        $obj.Attribute = $Object.Attribute
        $Result += $obj
    }
    $Result | Out-File -FilePath $OutFile -Append
}
Else {
    Out-File -FilePath $OutFile -InputObject "There is no ODBC other than the usual ones." -Append
    Out-File -FilePath $OutFile -InputObject "" -Append
}

# **********************************************************************************
# Collect server shares

Out-File -FilePath $OutFile -InputObject "--------------" -Append
Out-File -FilePath $OutFile -InputObject "NETWORK SHARES" -Append
Out-File -FilePath $OutFile -InputObject "--------------" -Append

Try{
    $Shares =  Get-WmiObject -class Win32_Share -Computer $ComputerName | Select Name,Path,Caption,Description | Where-Object {$_.Description -notin $ExcludedShares}
    } 
Catch {
       Out-File -FilePath $OutFile -InputObject "Unable to get network share" -Append 
       Out-File -FilePath $OutFile -InputObject "" -Append
       }

If ($Shares -eq $Null) {
    Out-File -FilePath $OutFile -InputObject "There is no network share other than the usual ones." -Append
    Out-File -FilePath $OutFile -InputObject "" -Append
}
Else {
    $Shares | Sort-Object -Property Name | Format-Table -AutoSize | Out-File -FilePath $OutFile -Append
}

# **********************************************************************************
# Collect server printers

Out-File -FilePath $OutFile -InputObject "--------" -Append
Out-File -FilePath $OutFile -InputObject "PRINTERS" -Append
Out-File -FilePath $OutFile -InputObject "--------" -Append

$Result = @()

Try {
     $Printer = Get-Printer | Select Name,ComputerName,DriverName,PortName | Where-Object {$_.Name -notin $ExcludedPrinters}
     }
Catch {
       Out-File -FilePath $OutFile -InputObject "Unable to get printer" -Append 
       Out-File -FilePath $OutFile -InputObject "" -Append
       }

If ($Printer.count > 0) {
    ForEach ($Object in $Printer) {
        $obj = "" |  Select-Object Name,ServerName,DriverName,PortName
        $obj.Name = $Object.Name
        $obj.ServerName = $Object.ComputerName
        $obj.DriverName = $Object.DriverName
        $obj.PortName = $Object.PortName
        $Result += $obj
    }
    $Result | Sort-Object -Property Name | Format-Table -AutoSize | Out-File -FilePath $OutFile -Append
}
Else {
    Out-File -FilePath $OutFile -InputObject "There is no printer other than the usual ones." -Append
    Out-File -FilePath $OutFile -InputObject "" -Append
}