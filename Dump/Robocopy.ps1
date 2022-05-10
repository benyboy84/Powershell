$path = "C:\Data\Mapping User.csv"
$csv = Import-csv -path $path

foreach($line in $csv)
{ 


$ScriptPath = Split-Path $MyInvocation.InvocationName 
$ScriptPath = $ScriptPath + "\OneDriveMapper.ps1"
$ScriptPath
$User = $line.ONEDRIVEURL
$User
$ScriptBlock = [ScriptBlock]::Create("'$ScriptPath' $user")
$ScriptBlock
#Invoke-Command -ScriptBlock $ScriptBlock


#$URL = "-u $($line.ONEDRIVEURL)"
#$Temp = $line.ONEDRIVEURL

#$ScriptPath
#$Script = "$($ScriptPath)\OneDriveMapper.ps1"
#$Script

#$Command = "'$Script'" + " -u $temp"
#$Command
#& ((Split-Path $MyInvocation.InvocationName) + "\OneDriveMapper - Copie.ps1") $URL
#Invoke-Expression $Command
#$command = "$($Line.DIRECTORY) V:\ /MIR"
#$command
#& ("C:\Windows\System32\Robocopy.exe") $Line.DIRECTORY "v:\Mydocument /MIR"  



#Remove-PSDrive V

}

