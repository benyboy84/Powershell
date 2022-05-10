# *******************************************************************************
# Login script des serveurs RDS 2008 R2
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ----------------------------------------------
# 2012-06-01  Benoit Blais        Cération initiale du script
# 2012-07-16  Benoit Blais	  Modification du serveur d'impression de Brd.
# 2012-08-09  FX Paquette	  Modification du serveur d'impression de LC.
# 2012-08-16  FX Paquette	  Modification du serveur d'impression de Van.
# 2012-08-30  FX Paquette	  Modification du serveur d'impression de Van.
# 2012-09-11  FX Paquette	  Fin des connexions des imprimantes pour TI.
# 2012-09-20  FX Paquette	  Fin des connexions des imprimantes pour Brossard.
# 2012-09-28  FX Paquette	  Fin des connexions des imprimantes pour EBBA et PDS III.
# 2012-10-05  FX Paquette	  Fin des connexions des imprimantes pour MSH SS.
# 2012-10-10  FX Paquette	  Fin des connexions des imprimantes pour MTL.
# 2012-11-13  Benoit Blais        Ajout du logiciel CertCleaner.exe.
# 2013-07-02  Benoit Blais        Copie du dictionnaire BBA.
# 2013-09-23  Benoit Blais        Modification des certificats.
# 2013-11-11  Benoit Blais        Modification du drag de la souris.
# 2014-01-13  Benoit Blais        Modification des sécurites des repertoires.
# 2014-02-26  Benoit Blais        Ajout de la variable JAVA_HOME.
# 2014-03-17  Benoit Blais        Ajout de la notification de mot de passe.
# 2014-03-31  Benoit Blais        Ajout de la section suppression des imprimantes.
# *******************************************************************************

# ********************FONCTION EST MEMBRE DE...**********************************
Function EstMembreDe($GroupName) {
 Add-Type -AssemblyName System.DirectoryServices.AccountManagement
 $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
 $User = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current
 $Group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($ct,$GroupName)
 If($User.IsMemberOf($Group)) {
  Return $True
 }
 Else {
  Return $False
 }
}
# *******************************************************************************

# ********************FONCTION TEST REGISTRY*************************************
Function Test-RegistryEntry($name) {
    $regkey = "HKCU:\Software\Microsoft\Shared Tools\Proofing Tools\1.0\Custom Dictionaries"
    $exists = Get-ItemProperty -Path "$regkey" -Name "$name" -ErrorAction SilentlyContinue
    If (($exists -ne $null) -and ($exists.Length -ne 0)) {
        Return $true
    }
    Return $false
}
# *******************************************************************************

# ********************DÉBUT DU SCRIPT********************************************
# Importation du module PSTerminalSerices.
# Celui-ci doit être dans le répertoire %WINDIR%\System32\WindowsPowerShell\v1.0\Modules 
# de chacun des serveurs.
$ErrorActionPreference  = 'SilentlyContinue'
Try {
 Import-Module PSTerminalServices
}
Catch {
 # POP UP D'ERREUR
 # Break
}

# Récupération du LOGIN et de l'adresse IP du client de la session active. 
$UserName = $env:USERNAME
$Session = Get-TSSession | ? { $_.UserName -match $UserName} | Select *
If ($Session) {
 $ClientName = $Session.ClientName
 [String]$ClientIP = $Session.ClientIPAddress
 $Location = $ClientIP.Split(".")
}

# ********************LOG DE LA SESSION DE L'USAGER*****************************
$LogPath = "\\bba\bbavol1\1000\011\whos_logged_in\" + $username + ".log"
$WeekLogPath = "\\bba\bbavol1\1000\011\whos_logged_in\Weekly.log"
$FullDate = Get-Date
$Date = $FullDate.ToShortDateString()
$Time = $FullDate.ToShortTimeString()
$ComputerName = $env:ComputerName
$Date + ";" + $Time + ";" + $UserName + ";" + $ComputerName + ";" + $ClientName | Add-Content $LogPath
$Date + ";" + $Time + ";" + $UserName + ";" + $ComputerName + ";" + $ClientName | Add-Content $WeekLogPath
# *******************************************************************************

# ********************CRÉATION ET SECURITÉ DE RÉPERTOIRE*************************
$UserFolderPath ="\\nearline0\ServiceDePayeDirCreate$\" + $UserName + "\"
$ServiceDePayePath = $UserFolderPath + "_ServiceDePaye" + "\"
$DesktopFolderPath = $UserFolderPath + "Desktop" + "\"
$ConsignoFolderPath = $UserFolderPath + ".consigno3" + "\"
If (!(Test-Path -path $UserFolderPath)) {
 New-Item $UserFolderPath -type directory
}
If (!(Test-Path -path $ServiceDePayePath)) {
 New-Item $ServiceDePayePath -type directory
}
ICACLS $UserFolderPath /c /Grant:r "${UserName}:(OI)(CI)(F)" Everyone:"(OI)(CI)(RX)" `"Domain Admins`":"(OI)(CI)(F)" /Inheritance:r /Q
ICACLS $ServiceDePayePath /c /Grant:r "${UserName}:(OI)(CI)(F)" `"Domain Admins`":"(OI)(CI)(F)" /Inheritance:r /Q
ICACLS $DesktopFolderPath /c /Grant:r "${UserName}:(OI)(CI)(F)" `"Domain Admins`":"(OI)(CI)(F)" /Inheritance:r /Q
ICACLS $DesktopFolderPath /c /Remove:g Everyone /Inheritance:r /Q
ICACLS $ConsignoFolderPath /c /Grant:r "${UserName}:(OI)(CI)(F)" `"Domain Admins`":"(OI)(CI)(F)" /Inheritance:r /Q
# *******************************************************************************

# ********************DRAG DE SOURIS À 4 PIXELS********************************
 New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name DragHeight -PropertyType String -Value "4" -Force
 New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name DragWidth -PropertyType String -Value "4" -Force
# *******************************************************************************

# ********************MICROSOFT OFFICE 2010 USER INFO****************************
$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = $Filter
$Path = $Searcher.FindOne()
$User = $Path.GetDirectoryEntry()
[String]$UserMail = $User.Mail
$Initial = $UserMail.SubString(0,1) + $UserMail.SubString(($UserMail.indexof("."))+1,1)
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\Common\UserInfo" -Name UserName -PropertyType String -Value $User.FullName -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\Common\UserInfo" -Name UserInitials -PropertyType String -Value $Initial -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\Common\UserInfo" -Name Company -PropertyType String -Value "BBA Inc." -Force
# *******************************************************************************

# ********************CONNEXION DES LECTEURS RÉSEAU******************************
$Net = $(New-Object -ComObject WScript.Network)
Try {$Net.MapNetworkDrive("G:", "\\BBA\BBAVOL1")} Catch {}
Try {$Net.MapNetworkDrive("M:", "\\NEARLINE\DOCUMENTATION_TECHNIQUE")} Catch {}
Try {$Net.MapNetworkDrive("N:", "\\NEARLINE\BBAVOL2")} Catch {}
If (EstMembreDe("BRETONBANVILLE\.ZrpAF Discipline Technologies de l'information") Or EstMembreDe("BRETONBANVILLE\.ZrpMF Discipline Technologies de l'information")) {
 Try {$Net.MapNetworkDrive("O:", "\\BBA\BBAVOL3")} Catch {}
}
If (EstMembreDe("BRETONBANVILLE\ETAP")) {
 Try {$Net.MapNetworkDrive("Q:", "\\bbatsetapdata\ETAPDATA")} Catch {}
}
If ($Location[1]  -eq "4") {
 Try {$Net.MapNetworkDrive("R:", "\\BBAFILE08\LabradorCity")} Catch {}
}
If ($Location[1]  -eq "3") {
 Try {$Net.RemoveNetworkDrive("S:",1,1)} Catch {}
 Try {$Net.MapNetworkDrive("S:", "\\BBAIMP07\SCAN")} Catch {}
}
Try {$Net.MapNetworkDrive("T:", "\\BBAAPPS01\CAD")} Catch {}
Try {$Net.MapNetworkDrive("U:", "\\NEARLINE0\USERS$\" + $UserName)} Catch {}
Try {$Net.MapNetworkDrive("V:", "\\NEARLINE0\USERS$")} Catch {}
Try {$Net.MapNetworkDrive("Z:", "\\NEARLINE\ARCHIVES")} Catch {}
# *******************************************************************************

# *****************CREATION DE LA VARIABLE JAVA_HOME*****************************
$RegistryPath = "HKLM:\SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment"
$CurrentVersion = (Get-ItemProperty -Path "$RegistryPath " -Name "CurrentVersion")."CurrentVersion"
$RegistryPath = $RegistryPath + "\" + $CurrentVersion
$JavaHome = (Get-ItemProperty -Path "$RegistryPath " -Name "JavaHome")."JavaHome"
$JavaHome = $JavaHome + "\bin"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $JavaHome, "User")
# *******************************************************************************

# ****************SUPPRESSION DES CERTIFICATS BBADC03****************************
$store = new-object System.Security.Cryptography.X509Certificates.X509Store "My","CurrentUser"
$store.Open("ReadWrite")
$certs = $store.Certificates
foreach ($cert in $certs)
{
 if ($cert.issuer -eq "CN=BBADC03, DC=bba, DC=ca")
 {
    $store.Remove($cert)
 }
}
$store.Close()
# *******************************************************************************

# ******************EXECUTION DU LOGICIEL CERTCLEANER.EXE************************
$AdobeSignature = "\\bba\bbavol3\PROD\SignatureAdobe\" + $UserName
If (Test-Path $AdobeSignature) {
 $AdobeSignature = $AdobeSignature + "\appearances.acrodata"
 \\bbadc03\NETLOGON\RDS\CertCleaner\Executable\CertCleaner.exe -i "Communications Server" -c "BBA Root CA" -p $AdobeSignature
}
Else {
 \\bbadc03\NETLOGON\RDS\CertCleaner\Executable\CertCleaner.exe -i "Communications Server" -c "BBA Root CA" -p "\\bba\bbavol3\PROD\SignatureAdobe\appearances.acrodata"
}
# *******************************************************************************

# ********************COPY OFFICE CUSTOM DICT************************************
$RegPath = "HKCU:\Software\Microsoft\Shared Tools\Proofing Tools\1.0\Custom Dictionaries"
$RegValue = "BBA_OfficeDictionary.DIC"

If (-Not (Test-Path $RegPath)) {
 New-Item -Path $RegPath;
 New-ItemProperty -Path $RegPath -Name "1" -PropertyType "String" -Value "CUSTOM.DIC";
 New-ItemProperty -Path $RegPath -Name "1_state" -PropertyType "BINARY" -Value ([byte[]](01,00,00,00));
 New-ItemProperty -Path $RegPath -Name "2" -PropertyType "String" -Value $RegValue;
 New-ItemProperty -Path $RegPath -Name "2_state" -PropertyType "BINARY" -Value ([byte[]](01,00,00,00));
 New-ItemProperty -Path $RegPath -Name UpdateComplete -PropertyType "DWORD" -Value "1";
}
Else {
 $a = (Get-ItemProperty -Path "$RegPath" -Name "2")."2"
 $1 = (Get-ItemProperty -Path "$RegPath" -Name "1")."1"
 
 If ($1 -eq "CUSTOM.DIC") {
  Try {$1_state = (Get-ItemProperty -Path "$RegPath" -Name "1_state")."1_state"} Catch {}
  If ($1_state -eq $null) {
   New-ItemProperty -Path $RegPath -Name "1_state" -PropertyType "BINARY" -Value ([byte[]](01,00,00,00));
  }
 }
 
 If ($a -eq "BBA_OfficeDictionnary.DIC") {
  Set-ItemProperty -Path $RegPath -Name "2" -Value $RegValue;
 }
 Else {
  If (-Not ($a -eq "BBA_OfficeDictionary.DIC")) {

   $RegProp = 0
   Do {
   $RegProp = $RegProp + 1
   Try {$test = (Get-ItemProperty -Path "$RegPath" -Name "$RegProp")."$RegProp"} Catch {}
   }
   While ($test -ne $null)

   $TempValue = (Get-ItemProperty -Path "$RegPath" -Name "2")."2"
   New-ItemProperty -Path $RegPath -Name $RegProp -PropertyType "String" -Value $TempValue;

   Rename-ItemProperty -Path $RegPath -Name "2_state" -NewName $RegProp"_state";
   
   Set-ItemProperty -Path $RegPath -Name "2" -Value $RegValue;
   Set-ItemProperty -Path $RegPath -Name "2_state" -Value ([byte[]](01,00,00,00));
  }
 }
}
# *******************************************************************************

# *********************PASSWORD NOTIFICATION*************************************
Try {\\bbadc03\netlogon\RDS\HTA\Notification.hta} Catch {}
# *******************************************************************************

# *********************DELETE NETWORK PRINTER*************************************
$RegPathBBA = "HKCU:\Software\BBA"

Try {$DeletePrinter = (Get-ItemProperty -Path "$RegPathBBA" -Name "DeletePrinter")."DeletePrinter"} Catch {}

If ($DeletePrinter -eq $Null) {
 If (-Not (Test-Path $RegPathBBA)) {
  New-Item -Path $RegPathBBA;
 }
 New-ItemProperty -Path $RegPathBBA -Name DeletePrinter -PropertyType "DWORD" -Value "0";
}

If ($DeletePrinter -ne 1) {
 Get-WMIObject Win32_Printer | where{$_.Network -eq 'true'} | foreach{$_.delete()}
 Set-ItemProperty -Path $RegPathBBA -Name DeletePrinter -Value "1";
}
# *******************************************************************************
