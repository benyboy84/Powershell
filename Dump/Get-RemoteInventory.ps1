# *******************************************************************************
# Script to get a total inventory of the remote server.
# This script will get hardware, software, roles and features, odbc, printer...
# 
# This script will create a .txt file with the server name.
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-10-11  Benoit Blais        Creation
# *******************************************************************************

$InputFile = "Server.txt"

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
                     "WSearch","wuauserv","wudfsvc","WwanSvc","XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc","ZeroConfigService","RSoPProv","sacsvr","SNMP","UALSVC","WAS","wuauserv"
                     )

# This list contain the softwares to be excluded from the report.
$ExcludedSoftwares = @("Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.17","Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.40660","Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.40660",
                       "Microsoft Visual C++ 2019 X64 Additional Runtime - 14.22.27821","Microsoft Visual C++ 2019 X64 Minimum Runtime - 14.22.27821","Microsoft Visual C++ 2005 Redistributable (x64)",
                       "Microsoft Visual C++ 2005 Redistributable (x64)","Microsoft Visual C++ 2008 Redistributable - x64 9.0.21022","Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.6161",
                       "Microsoft Visual C++ 2008 Redistributable - x86 9.0.30729.4148","Microsoft Visual C++ 2008 Redistributable - x86 9.0.30729.6161","Microsoft Visual C++ 2010  x64 Redistributable - 10.0.40219",
                       "Microsoft Visual C++ 2010  x86 Redistributable - 10.0.40219","Microsoft Visual C++ 2010  x86 Runtime - 10.0.40219","Microsoft Visual C++ 2013 Redistributable (x64) - 12.0.21005",
                       "Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.21005","Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005","Microsoft Visual C++ 2015-2019 Redistributable (x64) - 14.20.27508",
                       "Microsoft Visual C++ 2015-2019 Redistributable (x86) - 14.20.27508","Microsoft Visual C++ 2019 X64 Additional Runtime - 14.20.27508","Microsoft Visual C++ 2019 X64 Minimum Runtime - 14.20.27508",
                       "Microsoft Visual C++ 2019 X86 Additional Runtime - 14.20.27508","Microsoft Visual C++ 2019 X86 Minimum Runtime - 14.20.27508","Microsoft Visual C++ 2008 Redistributable - x64 9.0.30729.4148",
                       "Microsoft Visual C++ 2017 x64 Additional Runtime - 14.12.25810","Microsoft Visual C++ 2017 x64 Minimum Runtime - 14.12.25810","Microsoft Visual Studio 2010 Tools for Office Runtime (x64)",
                       "Microsoft Visual Studio 2010 Tools for Office Runtime (x64)"
                       )

# This list contain the ODBC to be excluded from the report.
$ExcludeODBC = @("dBASE Files","Excel Files","MS Access Database","CRD Samples","SampleApp","JavaSampleApp")

# This list contain the shares to be excluded from the report.
$ExcludedShares = @("Remote Admin","Default share","Remote IPC","Printer Drivers")

# This list contain the printers to be excluded from the report.
$ExcludedPrinters = @("Microsoft XPS Document Writer", "Microsoft Print to PDF")

$ExcludedFrewall = @("DFS Management (SMB-In)","DFS Management (WMI-In)","DFS Management (DCOM-In)","DFS Management (TCP-In)","Remote Event Log Management (RPC-EPMAP)","Remote Event Log Management (NP-In)","Remote Event Log Management (RPC)",
                     "Distributed Transaction Coordinator (RPC-EPMAP)","Distributed Transaction Coordinator (RPC)","Distributed Transaction Coordinator (TCP-Out)","Distributed Transaction Coordinator (TCP-In)","File and Printer Sharing (LLMNR-UDP-Out)",
                     "File and Printer Sharing (LLMNR-UDP-In)","File and Printer Sharing (Echo Request - ICMPv6-Out)","File and Printer Sharing (Echo Request - ICMPv6-In)","File and Printer Sharing (Echo Request - ICMPv4-Out)",
                     "File and Printer Sharing (Echo Request - ICMPv4-In)","File and Printer Sharing (Spooler Service - RPC-EPMAP)","File and Printer Sharing (Spooler Service - RPC)","File and Printer Sharing (NB-Datagram-Out)",
                     "File and Printer Sharing (NB-Datagram-In)","File and Printer Sharing (NB-Name-Out)","File and Printer Sharing (NB-Name-In)","File and Printer Sharing (SMB-Out)","File and Printer Sharing (SMB-In)",
                     "File and Printer Sharing (NB-Session-Out)","File and Printer Sharing (NB-Session-In)","BranchCache Hosted Cache Client (HTTP-Out)","BranchCache Hosted Cache Server(HTTP-Out)","BranchCache Hosted Cache Server (HTTP-In)",
                     "BranchCache Peer Discovery (WSD-Out)","BranchCache Peer Discovery (WSD-In)","BranchCache Content Retrieval (HTTP-Out)","BranchCache Content Retrieval (HTTP-In)","Windows Remote Management - Compatibility Mode (HTTP-In)",
                     "Windows Remote Management (HTTP-In)","Key Management Service (TCP-In)","Windows Firewall Remote Management (RPC-EPMAP)","Windows Firewall Remote Management (RPC)","Remote Scheduled Tasks Management (RPC-EPMAP)",
                     "Remote Scheduled Tasks Management (RPC)","Windows Management Instrumentation (ASync-In)","Windows Management Instrumentation (WMI-Out)","Windows Management Instrumentation (WMI-In)","Windows Management Instrumentation (DCOM-In)",
                     "Performance Logs and Alerts (DCOM-In)","Performance Logs and Alerts (TCP-In)","Performance Logs and Alerts (DCOM-In)","Performance Logs and Alerts (TCP-In)","Core Networking - Group Policy (LSASS-Out)","Core Networking - DNS (UDP-Out)",
                     "Core Networking - Group Policy (TCP-Out)","Core Networking - Group Policy (NP-Out)","Core Networking - IPv6 (IPv6-Out)","Core Networking - IPv6 (IPv6-In)","Core Networking - IPHTTPS (TCP-Out)","Core Networking - IPHTTPS (TCP-In)",
                     "Core Networking - Teredo (UDP-Out)","Core Networking - Teredo (UDP-In)","Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCPV6-Out)","Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCPV6-In)",
                     "Core Networking - Dynamic Host Configuration Protocol (DHCP-Out)","Core Networking - Dynamic Host Configuration Protocol (DHCP-In)","Core Networking - Internet Group Management Protocol (IGMP-Out)",
                     "Core Networking - Internet Group Management Protocol (IGMP-In)","Core Networking - Destination Unreachable Fragmentation Needed (ICMPv4-In)","Core Networking - Multicast Listener Done (ICMPv6-Out)",
                     "Core Networking - Multicast Listener Done (ICMPv6-In)","Core Networking - Multicast Listener Report v2 (ICMPv6-Out)","Core Networking - Multicast Listener Report v2 (ICMPv6-In)","Core Networking - Multicast Listener Report (ICMPv6-Out)",
                     "Core Networking - Multicast Listener Report (ICMPv6-In)","Core Networking - Multicast Listener Query (ICMPv6-Out)","Core Networking - Multicast Listener Query (ICMPv6-In)","Core Networking - Router Solicitation (ICMPv6-Out)",
                     "Core Networking - Router Solicitation (ICMPv6-In)","Core Networking - Router Advertisement (ICMPv6-Out)","Core Networking - Router Advertisement (ICMPv6-In)","Core Networking - Neighbor Discovery Advertisement (ICMPv6-Out)",
                     "Core Networking - Neighbor Discovery Advertisement (ICMPv6-In)","Core Networking - Neighbor Discovery Solicitation (ICMPv6-Out)","Core Networking - Neighbor Discovery Solicitation (ICMPv6-In)",
                     "Core Networking - Parameter Problem (ICMPv6-Out)","Core Networking - Parameter Problem (ICMPv6-In)","Core Networking - Time Exceeded (ICMPv6-Out)","Core Networking - Time Exceeded (ICMPv6-In)","Core Networking - Packet Too Big (ICMPv6-Out)",
                     "Core Networking - Packet Too Big (ICMPv6-In)","Core Networking - Destination Unreachable (ICMPv6-In)","COM+ Remote Administration (DCOM-In)","COM+ Network Access (DCOM-In)","Remote Administration (RPC-EPMAP)","Remote Administration (NP-In)",
                     "Remote Administration (RPC)","iSCSI Service (TCP-Out)","iSCSI Service (TCP-In)","Network Discovery (Pub WSD-Out)","Network Discovery (Pub-WSD-In)","Network Discovery (LLMNR-UDP-Out)","Network Discovery (LLMNR-UDP-In)",
                     "Network Discovery (WSD-Out)","Network Discovery (WSD-In)","Network Discovery (UPnPHost-Out)","Network Discovery (SSDP-Out)","Network Discovery (SSDP-In)","Network Discovery (WSD Events-Out)","Network Discovery (WSD Events-In)",
                     "Network Discovery (WSD EventsSecure-Out)","Network Discovery (WSD EventsSecure-In)","Network Discovery (NB-Datagram-Out)","Network Discovery (NB-Datagram-In)","Network Discovery (NB-Name-Out)","Network Discovery (NB-Name-In)",
                     "Network Discovery (UPnP-Out)","Network Discovery (UPnP-In)","Remote Service Management (RPC-EPMAP)","Remote Service Management (NP-In)","Remote Service Management (RPC)","Remote Volume Management (RPC-EPMAP)",
                     "Remote Volume Management - Virtual Disk Service Loader (RPC)","Remote Volume Management - Virtual Disk Service (RPC)","Remote Desktop (TCP-In)","Routing and Remote Access (PPTP-Out)","Routing and Remote Access (PPTP-In)",
                     "Routing and Remote Access (L2TP-Out)","Routing and Remote Access (L2TP-In)","Routing and Remote Access (GRE-Out)","Routing and Remote Access (GRE-In)","SCW remote access firewall rule - Svchost - TCP",
                     "SCW remote access firewall rule - Scshost - End Point RPC Mapper","SCW remote access firewall rule - Scshost - Dynamic RPC","SNMP Trap Service (UDP In)","SNMP Trap Service (UDP In)","Netlogon Service (NP-In)",
                     "Secure Socket Tunneling Protocol (SSTP-In)","SNMP Service (UDP In)","SNMP Service (UDP In)","SNMP Service (UDP Out)","SNMP Service (UDP Out)"
                     )

# ********************************************************************************** 

$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$Servers = Get-Content "$($ScriptPath)\$($InputFile)"

ForEach ($Server in $Servers) {

    $ComputerName = $Server

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
        $LastBoot = Get-CimInstance -ClassName win32_operatingsystem -ComputerName $ComputerName  | select lastbootuptime
        $LastBoot = $LastBoot.lastbootuptime
        }
    Catch{
          $LastBootS = "Unable to get last boot time"
          }

    Try{
        $ComputerIP = Get-WMIObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '*.*' }
        }
    Catch{
          $ComputerIP = "Unable to get IP configuration"
          }

    Try{
        $DHCPEnabled = Get-WMIObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | Select DHCPEnabled, IPAddress  | Where { $_.IPAddress -like '*.*' }
        }
    Catch{
          $DHCPEnabled = "Unable to get IP configuration"
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
        $ComputerPartitions = Get-WMIObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName | select DeviceID,VolumeName,@{Expression={$_.Size / 1GB};Label="SizeGB"} 
        }
    Catch{
          $ComputerPartitions = New-Object System.Object
          $ComputerPartitions | Add-Member -MemberType NoteProperty -Name "DeviceID" -Value "Unable to get disk device ID" -Force
          $ComputerPartitions | Add-Member -MemberType NoteProperty -Name "VolumeName" -Value "Unable to get disk name" -Force
         }

    Try{
        $ComputerDisks = Invoke-Command -ComputerName $Computername -ScriptBlock {Get-Disk} 
        }
    Catch{
          $ComputerDisks = New-Object System.Object
          $ComputerDisks | Add-Member -MemberType NoteProperty -Name "Number" -Value "Unable to get disk Number" -Force
          $ComputerDisks | Add-Member -MemberType NoteProperty -Name "FriendlyName" -Value "Unable to get disk FriendlyName" -Force
          $ComputerDisks | Add-Member -MemberType NoteProperty -Name "OperationalStatus" -Value "Unable to get disk Operational Status" -Force
          $ComputerDisks | Add-Member -MemberType NoteProperty -Name "Size" -Value "Unable to get disk Total Size" -Force
          $ComputerDisks | Add-Member -MemberType NoteProperty -Name "PartitionStyle" -Value "Unable to get disk Partition Style" -Force
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
    ForEach ($CPU in $ComputerCPU){
        $ComputerInfoProcessorID += "$($CPU.DeviceID) " 
        $ComputerInfoProcessorManufacturer += "$($CPU.Manufacturer) " 
        $ComputerInfoProcessorName += "$($CPU.Name) " 
        $ComputerInfoNumberOfCores += "$($CPU.NumberOfCores) " 
        $ComputerInfoNumberOfLogicalProcessors += "$($CPU.NumberOfLogicalProcessors) "
    }
    $ComputerInfoRAM = $ComputerHW.TotalPhysicalMemoryGB 
    ForEach ($Partition in $ComputerPartitions) {
        $ComputerInfoDiskDrive += "$($Partition.DeviceID) "
        $ComputerInfoDriveName += "$($Partition.VolumeName) " 
        $ComputerInfoSize += "$($Partition.SizeGB) " 
    }
    ForEach ($Disk in $ComputerDisks){
        $ComputerInfoDiskNumber += "$($Disk.Number) "
        $ComputerInfoDiskName += "$($Disk.FriendlyName) " 
        $ComputerInfoDiskStatus += "$($Disk.OperationalStatus) " 
        $ComputerInfoDiskSize += "$($Disk.Size) " 
        $ComputerInfoDiskStyle += "$($Disk.PartitionStyle) " 
    }
    $ComputerInfo = New-Object System.Object
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "OperatingSystem" -Value "$ComputerInfoOperatingSystem"
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "LastBootTime" -Value "$LastBoot"
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "IPv4" -Value "$ComputerIP"
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DHCP" -Value $DHCPEnabled.DHCPEnabled
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
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "Partition" -Value "$ComputerInfoDiskDrive" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "PartitionName" -Value "$ComputerInfoDriveName" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "PartitionSize" -Value "$ComputerInfoSize" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskDrive" -Value "$ComputerInfoDiskNumber" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskName" -Value "$ComputerInfoDiskName" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskStatus" -Value "$ComputerInfoDiskStatus" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskSize" -Value "$ComputerInfoDiskSize" -Force 
    $ComputerInfo | Add-Member -MemberType NoteProperty -Name "DiskStyle" -Value "$ComputerInfoDiskStyle" -Force 

    $ComputerInfo | Out-File -FilePath $OutFile 

    # **********************************************************************************
    # Collect local users

    Out-File -FilePath $OutFile -InputObject "-----" -Append
    Out-File -FilePath $OutFile -InputObject "USERS" -Append
    Out-File -FilePath $OutFile -InputObject "-----" -Append

    Try {
         Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True"  | Select Name, Disabled | where-object {!($_.Disabled)} | Sort-Object -Property Name } | Format-Table -Property Name, Disabled -AutoSize  | Out-File -FilePath $OutFile -Append
        } 
    Catch {
           Out-File -FilePath $OutFile -InputObject "Unable to get local users." -Append
          }

    # **********************************************************************************
    # Collect server roles and features

    Out-File -FilePath $OutFile -InputObject "------------------" -Append
    Out-File -FilePath $OutFile -InputObject "ROLES AND FEATURES" -Append
    Out-File -FilePath $OutFile -InputObject "------------------" -Append

    Try{
        Get-WmiObject -Computer $ComputerName -query 'select * from Win32_ServerFeature where parentid=0' | foreach { $_.Name } | Out-File -FilePath $OutFile -Append
        } 
    Catch {
           Out-File -FilePath $OutFile -InputObject "Unable to get role and feature" -Append
           }

    Out-File -FilePath $OutFile -InputObject " " -Append

    # **********************************************************************************
    # Collect server shares

    Out-File -FilePath $OutFile -InputObject "--------------" -Append
    Out-File -FilePath $OutFile -InputObject "NETWORK SHARES" -Append
    Out-File -FilePath $OutFile -InputObject "--------------" -Append

    Try{
        $Shares =  Get-WmiObject -class Win32_Share -Computer $ComputerName | Select Name,Path,Description | Where-Object {$ExcludedShares -NotContains $_.Description}
        } 
    Catch {
           Out-File -FilePath $OutFile -InputObject "Unable to get network share" -Append 
           Out-File -FilePath $OutFile -InputObject " " -Append
           }

    If ($Shares -eq $Null) {
        Out-File -FilePath $OutFile -InputObject "There is no network share other than the usual ones." -Append
        Out-File -FilePath $OutFile -InputObject " " -Append
    }
    Else {
        $Shares | Sort-Object -Property Name | FL | Out-File -FilePath $OutFile -Append
    }

    # **********************************************************************************
    # Collect server printers

    Out-File -FilePath $OutFile -InputObject "--------" -Append
    Out-File -FilePath $OutFile -InputObject "PRINTERS" -Append
    Out-File -FilePath $OutFile -InputObject "--------" -Append

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Try {
             $hostAddresses = @{}
             Get-WmiObject Win32_TCPIPPrinterPort | ForEach-Object {
                 $hostAddresses.Add($_.Name, $_.HostAddress)
                 }
             $LocalPrinters = Get-WmiObject Win32_Printer | ForEach-Object {
                                  New-Object PSObject -Property @{
                                      "Name" = $_.Name
                                      "DriverName" = $_.DriverName
                                      "ShareName" = $_.ShareName
                                      "HostAddress" = $hostAddresses[$_.PortName]
                                      }
                              }
             $Printer = $LocalPrinters | Where-Object {$ExcludedPrinters -NotContains $_.Name}
             }
        Catch {
               Out-File -FilePath $OutFile -InputObject "Unable to get printer" -Append 
               Out-File -FilePath $OutFile -InputObject " " -Append
               }
    }

    If ($Printer -eq $Null) {
        Out-File -FilePath $OutFile -InputObject "There is no printer other than the usual ones." -Append
        Out-File -FilePath $OutFile -InputObject " " -Append
    }
    Else {
        $Printer | Sort-Object -Property Name | Format-Table -Property Name,DriverName,ShareName,HostAddress -AutoSize | Out-File -FilePath $OutFile -Append
    }

    # **********************************************************************************
    # Collect server ODBC

    Out-File -FilePath $OutFile -InputObject "----" -Append
    Out-File -FilePath $OutFile -InputObject "ODBC" -Append
    Out-File -FilePath $OutFile -InputObject "----" -Append

    $Result = @()

    Try {
         $ODBC = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-OdbcDsn -DsnType "System" | Select Name,DriverName,Attribute | Where-Object {($ExcludeODBC -NotContains $_.Name)}}
         }
    Catch {
           Out-File -FilePath $OutFile -InputObject "Unable to get ODBC" -Append 
           Out-File -FilePath $OutFile -InputObject " " -Append
           }               

    If ($ODBC -ne $Null) {
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
        Out-File -FilePath $OutFile -InputObject " " -Append
    }

    # **********************************************************************************
    # Collect server scheduled tasks

    Out-File -FilePath $OutFile -InputObject "---------------" -Append
    Out-File -FilePath $OutFile -InputObject "SCHEDULED TASKS" -Append
    Out-File -FilePath $OutFile -InputObject "---------------" -Append

    $Report = @()

    Try {$tasks = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-ChildItem -Path "c:\Windows\System32\Tasks"}} Catch {}

    If ($tasks -ne $Null) {
        ForEach ($task in $tasks) {
            If ($task.name -ne "Microsoft") {
                $Details = "" | select Task, User, Enabled, Application, Arguments
                [xml]$TaskInfo = Invoke-Command -ComputerName $ComputerName -ScriptBlock {(Get-Content $Using:task.fullname)}
                $Details.Task = $task.name
                $Details.User = $TaskInfo.task.principals.principal.id
                $Details.Enabled = $TaskInfo.task.settings.enabled
                $Details.Application = $TaskInfo.task.actions.exec.command
                $Details.Arguments = $TaskInfo.task.actions.exec.Arguments
                $Report += $Details
            }
        }
        $Report | Sort-Object -Property Task | Out-File -FilePath $OutFile -Append
    }
    Else {
        Out-File -FilePath $OutFile -InputObject "There is no task to list." -Append
        Out-File -FilePath $OutFile -InputObject " " -Append
    }
    <#
    # **********************************************************************************
    # Collect server website

    If (Get-WmiObject -Computer $ComputerName -query 'select * from Win32_ServerFeature where parentid=0' | Select name,id | Where-Object {$_.name -like '*iis*'}) {

        Out-File -FilePath $OutFile -InputObject "----------------" -Append
        Out-File -FilePath $OutFile -InputObject "WEB SERVER (IIS)" -Append
        Out-File -FilePath $OutFile -InputObject "----------------" -Append
        Out-File -FilePath $OutFile -InputObject "" -Append

        $tab = 1

        Function List([string]$ID){
            $query = 'select * from Win32_ServerFeature where parentid='+$id
            $roles = Get-WmiObject -Computer $ComputerName -query $query | Select name,id,parentid
            If ($roles -ne $Null) {
                $tab = $tab + 1
                ForEach ($role in $roles){
                   For ($i0;$i-le$tab;$i++) {
                     $space = $space + "  "
                   }
                   $space + $role.name | Out-File -FilePath $OutFile -Append
                   List ($role.id)
                }
            }
            Else {
                $tab = $tab - 1
            }
        }

        $webrole = Get-WmiObject -Computer $ComputerName -query 'select * from Win32_ServerFeature where parentid=0' | Select name,id | Where-Object {$_.name -like '*iis*'}
        $webrole.name | Out-File -FilePath $OutFile -Append
        $query = 'select * from Win32_ServerFeature where parentid='+$webrole.id
        $roles = Get-WmiObject -Computer $ComputerName -query $query | Select name,id,parentid
        ForEach ($role in $roles){
            "  " + $role.name | Out-File -FilePath $OutFile -Append
            List ($role.id)
        }

        Try {Import-Module WebAdministration} Catch {}
        If (Get-Module -ListAvailable -Name WebAdministration) {
            $report =@()
            $bindins = @()
            $sites = dir "IIS:\Sites"

            ForEach ($child in $sites) {
                $website = $child.name
                $state = $child.state
                ForEach ($b in $child.bindings.Collection) {
                    $binding += "[" + $b.protocol + "," + $b.bindingInformation + "]"
                }
                $temp = "" | Select WebSite, State, Bindings, Path
                $temp.WebSite = $child.name
                $temp.State = $child.state
                $temp.Bindings = $binding
                $temp.Path = $child.physicalPath
                $report += $temp
            }
            $Report | Out-File -FilePath $OutFile -Append
            Get-WebApplication | Out-File -FilePath $OutFile -Append
        }
    }
    #>


    # **********************************************************************************
    # Collect server softwares

    Out-File -FilePath $OutFile -InputObject "---------" -Append
    Out-File -FilePath $OutFile -InputObject "SOFTWARES" -Append
    Out-File -FilePath $OutFile -InputObject "---------" -Append

    $Result = @()
    $OSIs64BitArch = ([System.Environment]::Is64BitOperatingSystem)
    $OSArchString = if ( $OSIs64BitArch ) {"x64"} else {"x86"}

    If ($OSArchString -like "x64") {
        Try {
             $Software = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                         Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                         Select-Object DisplayName,DisplayVersion,Publisher |
                         Where-Object {($ExcludedSoftwares -NotContains ($_.DisplayName)) -and (($_.DisplayName) -ne $Null)}
                         }
             }                     
        Catch {}
        Try {
             $Software += Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                          Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                          Select-Object DisplayName,DisplayVersion,Publisher |
                          Where-Object {($ExcludedSoftwares -NotContains ($_.DisplayName)) -and (($_.DisplayName) -ne $Null)}
                          }
             }
        Catch {}
    } 
    Else {
        Try {
             $Software = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                         Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                         Select-Object DisplayName,DisplayVersion,Publisher |
                         Where-Object {($ExcludedSoftwares -NotContains ($_.DisplayName)) -and (($_.DisplayName) -ne $Null)}
                         }
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
    # Collect server services

    Out-File -FilePath $OutFile -InputObject "--------" -Append
    Out-File -FilePath $OutFile -InputObject "SERVICES" -Append
    Out-File -FilePath $OutFile -InputObject "--------" -Append

    $Result = @()

    Try{
        $Services =  Get-WmiObject -Class Win32_Service -Computer $ComputerName | Where {($ExcludedServices -NotContains $_.Name)}
        } 
    Catch {
           Out-File -FilePath $OutFile -InputObject "Unable to get service" -Append 
           Out-File -FilePath $OutFile -InputObject " " -Append
           }

    If ($Services.count -ne 0) {
        ForEach ($Service in $Services) {
        
            $Details = Get-WmiObject win32_service -Computer $ComputerName | Select Name,DisplayName,Description,StartMode,State,PathName,StartName | where-object {$_.name -like $Service.name}
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
        Out-File -FilePath $OutFile -InputObject " " -Append
    }

    # **********************************************************************************
    # Collect custom firewall rule

    Out-File -FilePath $OutFile -InputObject "--------" -Append
    Out-File -FilePath $OutFile -InputObject "FIREWALL" -Append
    Out-File -FilePath $OutFile -InputObject "--------" -Append

    Try {$DomainProfile = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile | Select-Object EnableFirewall}} Catch {}
    Try {$PublicProfile = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\PublicProfile | Select-Object EnableFirewall}} Catch {}
    Try {$PrivateProfile = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\StandardProfile | Select-Object EnableFirewall}} Catch {}

    If ($DomainProfile -eq "1") {
        Out-File -FilePath $OutFile -InputObject "Domain Profile   - Windows firewall is on" -Append 
    }
    Else {
        Out-File -FilePath $OutFile -InputObject "Domain Profile   - Windows firewall is off" -Append
    }

    If ($PrivateProfile -eq "1") {
        Out-File -FilePath $OutFile -InputObject "Private Profile  - Windows firewall is on" -Append 
    }
    Else {
        Out-File -FilePath $OutFile -InputObject "Private Profile  - Windows firewall is off" -Append
    }

    If ($PublicProfile -eq "1") {
        Out-File -FilePath $OutFile -InputObject "Public Profile   - Windows firewall is on" -Append 
    }
    Else {
        Out-File -FilePath $OutFile -InputObject "Public Profile   - Windows firewall is off" -Append
    }

    Try {
         $Rules=(New-object -ComObject HNetCfg.FWPolicy2).rules
         $Firewall = $Rules | Where-Object {$ExcludedFrewall -NotContains $_.name} | Select-Object -Property name, description, ApplicationName, ServiceName, Protocol, LocalPorts, RemotePorts, LocalAddresses, RemoteAddresses, ICMPType, Direction, Action
        }
    Catch {
           Out-File -FilePath $OutFile -InputObject "Unable to get firewall rules" -Append 
           Out-File -FilePath $OutFile -InputObject " " -Append
          }

    If ($Firewall -ne $Null) {
        $Firewall | Sort-Object -Property Name | Out-File -FilePath $OutFile -Append
    }
    Else {
        Out-File -FilePath $OutFile -InputObject "There is no rules other than the usual ones." -Append
        Out-File -FilePath $OutFile -InputObject " " -Append
    }

}