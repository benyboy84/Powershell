




get-item cert:\CurrentUser\My\* |
foreach { 
 if ($_.issuer -eq "CN=BBADC03, DC=bba, DC=ca") {
  
  $serialNumber = $_.SerialNumber
  
  # Access MY store of Local Machine profile 
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","CurrentUser")
  $store.Open("ReadWrite")
  
  # Find the cert we want to delete
  $cert = $store.Certificates.Find("FindBySerialNumber",$serialNumber,$FALSE)[0]

  if ($cert -ne $null) {
   # Found the cert. Delete it (need admin permissions to do this)
   $store.Remove($cert) 
   
   Write-Host "Certificate with Serial Number" $serialNumber "has been deleted"
  }
  else {

   # Didn't find the cert. Exit
   Write-Host "Certificate with Serial Number" $serialNumber "could not be found"
  }

  # We are done
  $store.Close()
 }
}