# *******************************************************************************

####MANDATORY MANUAL CONFIGURATION

# Configure the output xlsx file destination.
$OutFile = "ServerInventory.xls"

# **********************************************************************************

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptNameAndExtension = $MyInvocation.MyCommand.Definition.Split("\") | Select-Object -Last 1
$ScriptName = $ScriptNameAndExtension.Split(".") | Select-Object -First 1
$TimeStamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm")
$Count = 0
$ComputerName = $env:COMPUTERNAME
$Logs = "$($ScriptPath)\$($ScriptName)_$($TimeStamp).log"
$TempFolder = "Inventory_$($TimeStamp)"
$DefaultServices = @("AdobeARMservice","AeLookupSvc","AJRouter","ALG","aoservice","AppIDSvc","Appinfo","AppMgmt","AppReadiness","AppVClient","AppXSvc","AssignedAccessManagerSvc","AudioEndpointBuilder","AudioSrv","AxInstSV","BcastDVRUserService_ad3f9",
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
                     "WSearch","wuauserv","wudfsvc","WwanSvc","XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","ZeroConfigService"                    
                     )
$ExcludedSoftwares = @("Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.17","Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.40660","Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.40660",
                       "Microsoft Visual C++ 2019 X64 Additional Runtime - 14.22.27821","Microsoft Visual C++ 2019 X64 Minimum Runtime - 14.22.27821"
                       )
$ExcludeODBC = @("dBASE Files","Excel Files","MS Access Database","CRD Samples")
$ExcludedShare = @("Remote Admin","Default share","Remote IPC","Printer Drivers")

# **********************************************************************************

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script Begin" 
Out-File -FilePath $Logs -InputObject "$(Get-Date) - Server Name : $($CompuerName)" -Append

If (!(Test-Path "$($env:TEMP)\$($TempFolder)")) {
    New-Item -Path $env:TEMP -Name $TempFolder -ItemType "directory" | Out-Null
}

$ErrorActionPreference = "stop"

# **********************************************************************************
# Collect server inventory

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting inventory..." -Append

$ComputerInfo = New-Object System.Object

Try{
    $ComputerOS = Get-WMIObject Win32_OperatingSystem -ComputerName $ComputerName |
    select-object Caption
    $ComputerInfoOperatingSystem = $ComputerOS.Caption
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully collect operating system information" -Append
   }
Catch{
      $ComputerOS = "Unable to get operating system"
      Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to collect operating system information" -Append
     }

Try{
    $ComputerIP = Get-WMIObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '*.*' }
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully collect server IP information" -Append
   }
Catch{
      $ComputerIP = "Unable to get IP configuration"
      Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to collect server IP information" -Append
     }
   
Try{
    $ComputerHW = Get-WMIObject -Class Win32_ComputerSystem -ComputerName $ComputerName | 
    select Manufacturer, 
           Model, 
           NumberOfProcessors, 
           @{Expression={$_.TotalPhysicalMemory / 1GB};Label="TotalPhysicalMemoryGB"}
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully collect hardware information" -Append
   }
Catch{
      $ComputerHW = New-Object System.Object
      $ComputerHW.Manufacturer = "Unable to get hardware manufacturer" 
      $ComputerHW.Model = "Unable to get hardware model"
      $ComputerHW.NumberOfProcessors = "Unable to get no=umber of processors"
      Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to collect hardware information" -Append
     }
    
Try{
    $ComputerCPU = Get-WMIObject win32_processor -ComputerName $ComputerName | 
    select DeviceID, 
           Name, 
           Manufacturer, 
           NumberOfCores, 
           NumberOfLogicalProcessors 
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully collect CPU information" -Append
   }
Catch{
      $ComputerCPU = New-Object System.Object
      $ComputerCPU.DeviceID = "Unable to get CPU device ID"
      $ComputerCPU.Name = "Unable to CPU name "
      $ComputerCPU.Manufacturer = "Unable to get CPU manufacturer"  
      $ComputerCPU.NumberOfCores = "Unable to get CPU nomber of cores"
      $ComputerCPU.NumberOfLogicalProcessors = "Unable to get CPU number of logical processors"
      Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to collect CPU information" -Append
     }

Try{
    $ComputerDisks = Get-WMIObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName | 
    select DeviceID, 
           VolumeName, 
           @{Expression={$_.Size / 1GB};Label="SizeGB"} 
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully collect disk information" -Append
   }
Catch{
      $ComputerDisks = New-Object System.Object
      $ComputerDisks.DeviceID = "Unable to get disk device ID"
      $ComputerDisks.VolumeName = "Unable to get disk name"
      Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to collect disk information" -Append
     }

Try{
    $ComputerSerial = (Get-WMIObject Win32_Bios -ComputerName $ComputerName).SerialNumber 
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully collect serial number" -Append
   } 
Catch{
      $ComputerSerial = "Unable to get serial number"
      Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to collect serial number" -Append
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
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "OperatingSystem" -Value "$ComputerInfoOperatingSystem"
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "IPv4" -Value "$ComputerIP"
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "Manufacturer" -Value "$ComputerInfoManufacturer" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "Model" -Value "$ComputerInfoModel" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "Serial" -Value "$ComputerSerial" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "NumberOfProcessors" -Value "$ComputerInfoNumberOfProcessors" -Force 
 $ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "ProcessorID" -Value "$ComputerInfoProcessorID" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "ProcessorManufacturer" -Value "$ComputerInfoProcessorManufacturer" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "ProcessorName" -Value "$ComputerInfoProcessorName" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "NumberOfCores" -Value "$ComputerInfoNumberOfCores" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "NumberOfLogicalProcessors" -Value "$ComputerInfoNumberOfLogicalProcessors" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "RAM" -Value "$ComputerInfoRAM" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "DiskDrive" -Value "$ComputerInfoDiskDrive" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "DriveName" -Value "$ComputerInfoDriveName" -Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "Size" -Value "$ComputerInfoSize" -Force 

Try {
    $ComputerInfo | Export-Csv -FilePath "$($env:TEMP)\$($TempFolder)\Inventory.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export inventory to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export inventory to CSV" -Append
}

$ComputerInfoOperatingSystem = $Null
$ComputerIP = $Null
$ComputerInfoManufacturer =  $Null
$ComputerInfoModel = $Null
$ComputerSerial = $Null
$ComputerInfoNumberOfProcessors = $Null
$ComputerInfoProcessorID =  $Null
$ComputerInfoProcessorManufacturer = $Null  
$ComputerInfoProcessorName = $Null
$ComputerInfoNumberOfCores =  $Null
$ComputerInfoNumberOfLogicalProcessors = $Null 
$ComputerInfoRAM = $Null
$ComputerInfoDiskDrive = $Null 
$ComputerInfoDriveName =  $Null
$ComputerInfoSize =  $Null
$ComputerDisks = $Null
$ComputerCPU = $Null
$ComputerHW = $Null
$ComputerInfo = $Null

# **********************************************************************************
# Collect server softwares

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting softwares..." -Append
$Result = @()

$OSIs64BitArch = ([System.Environment]::Is64BitOperatingSystem)

$OSArchString = if ( $OSIs64BitArch ) {"x64"} else {"x86"}

If ($OSArchString -like "x64") {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - 64bit operating system" -Append
    Try {
         $Software = Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                     Select-Object DisplayName,
                                   DisplayVersion,
                                   Publisher |
                     Where-Object {(($_.DisplayName) -notin $ExcludedSoftwares) -and (($_.DisplayName) -ne $Null)}
         Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully read HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" -Append
        }                     
    Catch {
           Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to read HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" -Append
          }
    Try {
         $Software += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                      Select-Object DisplayName,
                                    DisplayVersion,
                                    Publisher |
                      Where-Object {(($_.DisplayName) -notin $ExcludedSoftwares) -and (($_.DisplayName) -ne $Null)}
         Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully read HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -Append
        }
    Catch {
           Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to read HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -Append
          }
} 
Else {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - 32bit operating system" -Append
    Try {
         $Software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                     Select-Object DisplayName,
                                   DisplayVersion,
                                   Publisher |
                     Where-Object {(($_.DisplayName) -notin $ExcludedSoftwares) -and (($_.DisplayName) -ne $Null)}
         Out-File -FilePath $Logs -InputObject "$(Get-Date) - Successfully read HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -Append
        }
    Catch {
           Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to read HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -Append
          }
}

ForEach ($Object in $Software) {
    $obj = "" |  Select-Object DisplayName,
                               DisplayVersion,
                               Publisher
    $obj.DisplayName = $Object.DisplayName
    $obj.DisplayVersion = $Object.DisplayVersion
    $obj.Publisher = $Object.Publisher
    $Result += $obj
}

Try {
    $Result | Export-Csv -Path "$($env:TEMP)\$($TempFolder)\Software.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export software to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export software to CSV" -Append
}

$Software = $Null
$Result = $Null
$OSIs64BitArch = $Null
$obj = $Null

# **********************************************************************************
# Collect server roles and features

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting roles and features..." -Append
$RolesAndFeatures = New-Object System.Object

Try{
    $Features =  Get-WmiObject -Computer $ComputerName -query 'select * from Win32_ServerFeature where parentid=0' | foreach { $_.Name }
    $Features =  $Features -join "`r`n"
    if ($lastexitcode) {throw $er}
    Else { Out-File -FilePath $Logs -InputObject "$(Get-Date) - Features successfully collected" -Append }
} 
Catch {
    $Features = "Features not collected"
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Features not collected" -Append
}

$RolesAndFeatures |
    Add-Member -MemberType NoteProperty -Name "Features" -Value "$Features" -Force 


Try {
    $RolesAndFeatures | Export-Csv "$($env:TEMP)\$($TempFolder)\RoleAndFeature.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export roles and features to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export roles and features to CSV" -Append
}

$RolesAndFeatures = $Null
$Features = $Null

# **********************************************************************************
# Collect server services

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting services..." -Append
$ServerServices = New-Object System.Object

Try{
    $Services =  Get-WmiObject -Class Win32_Service -Computer $ComputerName
    if ($lastexitcode) {throw $er}
    Else { Out-File -FilePath $Logs -InputObject "$(Get-Date) - Services successfully collected" -Append }
} 
Catch {
    $Services = "Services not collected on " + $ComputerName
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Services not collected" -Append
}

ForEach ($Service in $Services) {
    If($Service.name -notin $DefaultServices){
        
        $Details = Get-WmiObject win32_service | where-object -Property name -like $Service.name

        $ServerServices | 
            Add-Member -MemberType NoteProperty -Name "Name" -Value $Details.Name -Force
        $ServerServices |
            Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $Details.DisplayName -Force 
        $ServerServices | 
            Add-Member -MemberType NoteProperty -Name "Description" -Value $Details.Description -Force
        $ServerServices | 
            Add-Member -MemberType NoteProperty -Name "StartMode" -Value $Details.StartMode -Force
        $ServerServices |
            Add-Member -MemberType NoteProperty -Name "State" -Value $Details.State -Force
        $ServerServices |
            Add-Member -MemberType NoteProperty -Name "PathName" -Value $Details.PathName -Force 
        $ServerServices |
            Add-Member -MemberType NoteProperty -Name "StartName" -Value $Details.StartName -Force 

        $Details = ""
    }
}

Try {
    $ServerServices | Export-Csv "$($env:TEMP)\$($TempFolder)\Service.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export service to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export service to CSV" -Append
}

$Services = $Null
$Details = $Null
$ServerServices = $Null

# **********************************************************************************
# Collect server ODBC

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting ODBC..." -Append
$Result = @()

Try {
     $ODBC = Get-OdbcDsn -DsnType "System" | 
             Select Name, 
                    DriverName,
                    Attribute |
             Where-Object {($_.Name -notin $ExcludeODBC)}
     Out-File -FilePath $Logs -InputObject "$(Get-Date) - ODBC successfully collected" -Append
    }
Catch {
       $ODBC = New-Object System.Object
       $ODBC.Name = "Unable to get ODBC name"
       $ODBC.DriverName = "Unable to get ODBC driver name"
       $ODBC.Attribute = "Unable to get ODBC attribute"
       Out-File -FilePath $Logs -InputObject "$(Get-Date) - ODBC not collected" -Append
      }
                      

ForEach ($Object in $ODBC) {
    $obj = "" |  Select-Object ComputerName,
                               Name,
                               DsnType,
                               DriverName,
                               Attribute
    $obj.ComputerName = $ComputerName
    $obj.Name = $Object.Name
    $obj.DsnType = $Object.DsnType
    $obj.DriverName = $Object.DriverName
    $obj.Attribute = $Object.Attribute
    $Result += $obj
}

Try {
    $Result | Export-Csv -Path "$($env:TEMP)\$($TempFolder)\ODBC.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export ODBC to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export ODBC to CSV" -Append
}

$Result = $Null
$ODBC= $Null
$obj = $Null

# **********************************************************************************
# Collect server shares

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting network shares..." -Append

Try{
    $Shares =  Get-WmiObject -class Win32_Share -Computer $ComputerName | 
               Select Name,
                      Path,
                      Caption,
                      Description |
               Where-Object {$_.Description -notin $ExcludedShare}
    if ($lastexitcode) {throw $er}
    Else { Out-File -FilePath $Logs -InputObject "$(Get-Date) - Shares successfully collected" -Append }
} 
Catch {
    $Shares = "Shares not collected on " + $ComputerName
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Shares not collected" -Append
}

Try {
    $Shares | Export-Csv -Path "$($env:TEMP)\$($TempFolder)\Share.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export share to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export share to CSV" -Append
}

$Shares = $Null

# **********************************************************************************
# Collect server printers

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Collecting printers..." -Append
$Result = @()

$Printer = Get-Printer |
           Select Name,
                  ComputerName,
                  DriverName,
                  PortName |
            Where-Object {($_.ComputerName)}

ForEach ($Object in $Printer) {
    $obj = "" |  Select-Object Name,
                               ServerName,
                               DriverName,
                               PortName
    $obj.Name = $Object.Name
    $obj.ServerName = $Object.ComputerName
    $obj.DriverName = $Object.DriverName
    $obj.PortName = $Object.PortName
    $Result += $obj
}

Try {
    $Result | Export-Csv -Path "$($env:TEMP)\$($TempFolder)\Printer.csv" -NoTypeInformation
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Export printer to CSV" -Append
}
Catch {
    Out-File -FilePath $Logs -InputObject "$(Get-Date) - Unable to export printer to CSV" -Append
}

$Result = $Null

# **********************************************************************************
# Merge

$csvs = Get-ChildItem "$($env:TEMP)\$($TempFolder)"

$outputfilename = "$($ScriptPath)\$($OutFile)"

$excelapp = new-object -comobject Excel.Application
$excelapp.sheetsInNewWorkbook = $csvs.Count
$xlsx = $excelapp.Workbooks.Add()
$sheet=1

foreach ($csv in $csvs)
{
$row=1
$column=1
$worksheet = $xlsx.Worksheets.Item($sheet)
$worksheet.Name = [io.path]::GetFileNameWithoutExtension($csv.Name)
$file = (Get-Content "$($env:TEMP)\$($TempFolder)\$($csv)")
foreach($line in $file)
{
$linecontents=$line -split ‘,(?!\s*\w+”)’
foreach($cell in $linecontents)
{
$worksheet.Cells.Item($row,$column) = $cell
$column++
}
$column=1
$row++
}
$sheet++
}

$xlsx.SaveAs($outputfilename)
$excelapp.quit()

Remove-Item "$($env:TEMP)\$($TempFolder)\*.*"
Remove-Item "$($env:TEMP)\$($TempFolder)"

Out-File -FilePath $Logs -InputObject "$(Get-Date) - Script End" -Append