# **********************************************************************************
# Script to get a complete inventory of a computer (hardware, software, printer, 
# ODBC).
#
# This will create a CSV file named ComputerName.csv for each section (hardware,
# software...). The file will be place under directory named with the section title.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2019-09-12  Benoit Blais        First iteration
# **********************************************************************************

# **********************************************************************************

clear-host

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$Path = $ScriptDir + "\Inventory"
If(!(Test-Path -Path $Path)) {
     New-Item -Path $ScriptDir -Name "Inventory" -ItemType "directory"
}
$Result=@()

# *************************************HARDWARE*************************************

# Get operating system version and architecture.

$OSIs64BitArch = ([System.Environment]::Is64BitOperatingSystem)

$OSArchString = if ( $OSIs64BitArch ) {"x64"} else {"x86"}

$OSIsServerVersion = if ([Int]3 -eq [Int](Get-WmiObject -Class Win32_OperatingSystem).ProductType) {$True} else {$False}

$OSVerObjectCurrent = [System.Environment]::OSVersion.Version

If ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "6.1.0.0")) {
    If ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "6.2.0.0")) {
        If ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "6.3.0.0")) {
            If ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "10.0.0.0")) {
                If ( $OSIsServerVersion ) {
                    $ComputerInfoOperatingSystem = 'Windows Server 2016 ' + $OSArchString + " ... OR Above"
                } Else {
                    $ComputerInfoOperatingSystem = 'Windows 10 ' + $OSArchString + " ... OR Above"
                }
            } Else {
                If ( $OSIsServerVersion ) {
                    $ComputerInfoOperatingSystem = 'Windows Server 2012 R2 ' + $OSArchString
                } Else {
                    $ComputerInfoOperatingSystem = 'Windows 8.1 ' + $OSArchString
                }
            }
        } Else {
            If ( $OSIsServerVersion ) {
                $ComputerInfoOperatingSystem = 'Windows Server 2012 ' + $OSArchString
            } Else {
                $ComputerInfoOperatingSystem =  'Windows 8 ' + $OSArchString
            }
        }
    } Else {
        If ( $OSIsServerVersion ) {
            $ComputerInfoOperatingSystem = 'Windows Server 2008 R2 ' + $OSArchString
        } Else {
            $ComputerInfoOperatingSystem = 'Windows 7 OR Windows 7-7601 SP1' + $OSArchString
        }
    }
} 

$ComputerName = $env:computername
 
$ComputerInfo = New-Object System.Object 

$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Name" -Value "$ComputerName" -Force 


$ComputerInfo | Add-Member -MemberType NoteProperty -Name "Username" -Value $($env:USERNAME)
$ComputerInfo | Add-Member -MemberType NoteProperty -Name "OperatingSystem" -Value $ComputerInfoOperatingSystem 

$ComputerHW = Get-WMIObject -Class Win32_ComputerSystem -ComputerName $ComputerName | 
           select Manufacturer,
                  Model,
                  NumberOfProcessors,
                  @{Expression={$_.TotalPhysicalMemory / 1GB};Label="TotalPhysicalMemoryGB"} 

$ComputerCPU = Get-WMIObject win32_processor -ComputerName $ComputerName | 
            select DeviceID, 
                   Name, 
                   Manufacturer, 
                   NumberOfCores, 
                   NumberOfLogicalProcessors 

$ComputerDisks = Get-WMIObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName | 
              select DeviceID, 
                     VolumeName, 
                     @{Expression={$_.Size / 1GB};Label="SizeGB"} 
 
$ComputerSerial = (Get-WMIObject Win32_Bios -ComputerName $ComputerName).SerialNumber 
 
$ComputerGraphics = Get-WMIObject -Class Win32_VideoController | 
                 select Name, 
                 @{Expression={$_.AdapterRAM / 1GB};Label="GraphicsRAM"} 
 
$ComputerSoundDevices = (Get-WMIObject -Class Win32_SoundDevice).Name 
             
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
$ComputerInfoGraphicsName = $ComputerGraphics.Name 
$ComputerInfoGraphicsRAM = $ComputerGraphics.GraphicsRAM 

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
    Add-Member -MemberType NoteProperty -Name "Size" -Value "$ComputerInfoSize"-Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "Graphics" -Value "$ComputerInfoGraphicsName"-Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "GraphicsRAM" -Value "$ComputerInfoGraphicsRAM"-Force 
$ComputerInfo | 
    Add-Member -MemberType NoteProperty -Name "SoundDevices" -Value "$ComputerSoundDevices"-Force 


$Path = $ScriptDir + "\Inventory\Hardware-" + $ComputerName + ".csv"
$ComputerInfo | Export-Csv -Path $Path -NoTypeInformation

# *************************************SOFTWARE*************************************

# Get the installed software.

If ($OSArchString -like "x64") {
    $Software = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
           Select-Object DisplayName,
                         DisplayVersion,
                         Publisher |
           Where-Object {($_.DisplayName) -and
                         ($_.DisplayName -notlike "Microsoft Visual C++*") -and
                         ($_.DisplayName -notlike "Java*")}
                             


    $Software += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
           Select-Object DisplayName,
                         DisplayVersion,
                         Publisher |
           Where-Object {($_.DisplayName) -and
                         ($_.DisplayName -notlike "Microsoft Visual C++*") -and
                         ($_.DisplayName -notlike "Java*")}
} Else {
    $Software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
           Select-Object DisplayName,
                         DisplayVersion,
                         Publisher |
           Where-Object {($_.DisplayName) -and
                         ($_.DisplayName -notlike "Microsoft Visual C++*") -and
                         ($_.DisplayName -notlike "Java*")}
}

ForEach ($Object in $Software) {
    $obj = "" |  Select-Object ComputerName,
                               DisplayName,
                               DisplayVersion,
                               Publisher
    $obj.ComputerName = $ComputerName
    $obj.DisplayName = $Object.DisplayName
    $obj.DisplayVersion = $Object.DisplayVersion
    $obj.Publisher = $Object.Publisher
    $Result += $obj
}
$Path = $ScriptDir + "\Inventory\Software-" + $ComputerName + ".csv"
$Result | Export-Csv -Path $Path -NoTypeInformation
$Result = $Null

# **************************************DRIVE***************************************

# Get the configured network drive on the computer.

$Drives = Get-WmiObject -Class Win32_MappedLogicalDisk | 
          select Name, 
                 ProviderName

ForEach ($Object in $Drives) {
    $obj = "" |  Select-Object ComputerName,
                               Name,
                               ProviderName
    $obj.ComputerName = $ComputerName
    $obj.Name = $Object.Name
    $obj.ProviderName = $Object.ProviderName
    $Result += $obj
}
$Path = $ScriptDir + "\Inventory\MapDrive-" + $ComputerName + ".csv"
$Result | Export-Csv -Path $Path -NoTypeInformation
$Result = $Null

# **************************************ODBC****************************************

# Get the configured ODBC on the computer.

$ODBC = Get-OdbcDsn | 
        Select Name, 
              DsnType,
              DriverName,
              Attribute |
        Where-Object {($_.Name -ne "dBASE Files") -and
                      ($_.Name -ne "Excel Files") -and 
                      ($_.Name -ne "MS Access Database")}

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
$Path = $ScriptDir + "\Inventory\ODBC-" + $ComputerName + ".csv"
$Result | Export-Csv -Path $Path -NoTypeInformation
$Result = $Null

# *************************************PRINTER***************************************

# Get the configured network printer on the computer.

$Printer = Get-Printer |
           Select Name,
                  ComputerName,
                  DriverName,
                  PortName |
            Where-Object {($_.ComputerName)}

ForEach ($Object in $Printer) {
    $obj = "" |  Select-Object ComputerName,
                               Name,
                               ServerName,
                               DriverName,
                               PortName
    $obj.ComputerName = $ComputerName
    $obj.Name = $Object.Name
    $obj.ServerName = $Object.ComputerName
    $obj.DriverName = $Object.DriverName
    $obj.PortName = $Object.PortName
    $Result += $obj
}
$Path = $ScriptDir + "\Inventory\NetworkPrinter-" + $ComputerName + ".csv"
$Result | Export-Csv -Path $Path -NoTypeInformation
$Result = $Null

# *************************************PRINTER***************************************

# Get the Microsoft Outlook configuration on the computer.

Try {
    $PST = New-Object -comObject Outlook.Application
}
Catch {
}
If ($PST) {
    $PST = $PST.Session.Stores | where { ($_.FilePath -like '*.PST') }
    If ($PST) {
        ForEach ($Object in $PST) {
            $obj = "" |  Select-Object ComputerName,
                                       DisplayName,
                                       FilePath
            $obj.ComputerName = $ComputerName
            $obj.DisplayName = $Object.DisplayName
            $obj.FilePath = $Object.FilePath
            $Result += $obj
        }
        $Path = $ScriptDir + "\Inventory\PST-" + $ComputerName + ".csv"
        $Result | Export-Csv -Path $Path -NoTypeInformation
        $Result = $Null
    }
}


# *************************************PRINTER***************************************


$wsh = New-Object -ComObject Wscript.Shell

$wsh.Popup("Completed execution")

Exit