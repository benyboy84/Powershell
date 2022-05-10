# *******************************************************************************
# Script permettant d��liminer les SID non connu des permissions des 
# fichiers/r�pertoires.
#
# Le fichier/r�pertoire ne doit pas h�riter des permissions du parent.
#
# ===============================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  ----------------------------------------------
# 2012-09-27  Benoit Blais        C�ration initiale du script
# *******************************************************************************

Clear-host

$location = Read-Host "Enter the folder location?"

#Search recursivly through location defined
get-childitem -r $location | foreach{
 $tempLocation = $_.FullName

 #Get ACL for tempLocation
 $acl = get-acl $tempLocation

 #Get SID of unknown user from ACL
 $acl.Access | where{
 $_.IdentityReference -like "*S-1*" -and $_.isinherited -like $false} | foreach{
 
  #Foreach SID purge the SID from the ACL
   $acl.purgeaccessrules($_.IdentityReference)
   
   #Reapply ACL to file or folder with out SID
   Set-Acl -AclObject $acl -path $tempLocation
   }
 }