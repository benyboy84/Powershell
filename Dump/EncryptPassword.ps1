# *******************************************************************************
# Script to encrypt a password in a text file with an ASE key.
#
# This script will create an encryption key and ask for to enter username and 
# password. It will encrypt it into a text file. Both files will be save in 
# the same location as the script.
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ---------------------------------------------
# 2019-11-20  Benoit Blais        Creation
# *******************************************************************************

# *******************************************************************************

# Define key path
$ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$KeyFile = "$($ScriptPath)\aes.key"
$PasswordFile = "$($ScriptPath)\password.txt"

# *******************************************************************************

$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

Try{
 (Get-Credential -credential "User").Password | ConvertFrom-SecureString -key (get-content $KeyFile) | set-content $PasswordFile

 $WSH = New-Object -ComObject Wscript.Shell
 $WSH.Popup("Please, secure Password.txt and AES.key files.")
}
Catch{
 $WSH = New-Object -ComObject Wscript.Shell
 $WSH.Popup("Error")
}