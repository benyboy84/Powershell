# ********************FONCTION EST MEMBRE DE...**********************************
Function EstMembreDe($GroupName) {
 Add-Type -AssemblyName System.DirectoryServices.AccountManagement
 $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
 $User = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current
 $Group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($ct,$GroupName)
 If($User.IsMemberOf($Group)) {
write-host "OK"
  Return $True
 }
 Else {
Write-host "Bad"
  Return $False
 }
}
# *******************************************************************************

Write-host "Test #1"
If (EstMembreDe("BRETONBANVILLE\.GrpEN Discipline IT Information Systems")) {
 Try {$Net.MapNetworkDrive("O:", "\\BBA\BBAVOL3")} Catch {}
}
Write-host "Test #2"
If (EstMembreDe("BRETONBANVILLE\.ZrpAF Discipline Technologies de l'information") Or EstMembreDe("BRETONBANVILLE\.ZrpMF Discipline Technologies de l'information")) {
 Try {$Net.MapNetworkDrive("O:", "\\BBA\BBAVOL3")} Catch {}
}

Write-host "Test #3"
If (EstMembreDe("BRETONBANVILLE\Service JT")) {
 Try {$Net.MapNetworkDrive("O:", "\\BBA\BBAVOL3")} Catch {}
}




