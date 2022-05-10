
$RegPathBBA = "HKCU:\Software\BBA"
Write-Host $RegPathBBA

Try {$DeletePrinter = (Get-ItemProperty -Path "$RegPathBBA" -Name "DeletePrinter")."DeletePrinter"} Catch {}

If ($DeletePrinter -eq $Null) {
 New-ItemProperty -Path $RegPathBBA -Name DeletePrinter -PropertyType "DWORD" -Value "0";
}

If ($DeletePrinter -ne 1) {
 Get-WMIObject Win32_Printer | where{$_.Network -eq 'true'} | foreach{$_.delete()}
 Set-ItemProperty -Path $RegPathBBA -Name DeletePrinter -Value "1";
}
