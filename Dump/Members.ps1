$Users = Get-ADGroupMember -Identity "GGPS-APP-IE_eService_MSDS_CX_FR" -Recursive 
$Count = 0

ForEach ($User in $Users){

    If ($User.objectClass -eq "user") {
        $Count++
    }

}
$Count