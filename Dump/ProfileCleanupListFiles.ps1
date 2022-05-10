$Profile = "\\fsx-prod\FSLogix"
$Users = Get-ChildItem -Path $Profile
$Export = @()
$ExportCSV = "C:\Scripts\Benoit\ProfileCleanup.csv"
ForEach ($User in $Users) {
    If (Test-Path "$($Profile)\$($User)\Win2019v6\UPM_Profile") {

        If (([ADSISearcher] "(sAMAccountName=$($User))").FindOne()) {
            If (Test-Path "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Google\Chrome\User Data\Default\Service Worker"){

                # Get all child item in the user folder
                $ChildItem = Get-ChildItem -Path "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Google\Chrome\User Data\Default\Service Worker" -Recurse -Force
                
                #Loop through each file to delete it
                ForEach ($Item in $ChildItem) { 
                    $Row = "" | Select-Object Path,Length
                    $Row.Path = $Item.FullName
                    #We will get the file information, not the folder.
                    If ($Item.PSIsContainer -ne $True) {
                        $ItemSize = $Null
                        # Because the path if a file, we only need to get the file length
                        Try{
                            $ItemSize = $("{0:N2}" -f ($Item.Length / 1MB))
                        }
                        Catch {$Null}
                        # If ItemSize is null, this meen that the file is empty
                        If ($ItemSize -eq $Null) {
                            $Row.Length = 0
                        }
                        Else {
                            $Row.Length = $ItemSize
                        }
                    }
                    Else {
                        $Row.Length = ""
                    }
                    $Export += $Row
                }

            }

            If (Test-Path "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Microsoft\Office\16.0\OfficeFileCache"){
                
                # Get all child item in the user folder
                $ChildItem = Get-ChildItem -Path "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Microsoft\Office\16.0\OfficeFileCache" -Recurse -Force
                #Loop through each file to delete it
                ForEach ($Item in $ChildItem) { 
                    $Row = "" | Select-Object Path,Length
                    $Row.Path = $Item.FullName
                    #We will get the file information, not the folder.
                    If ($Item.PSIsContainer -ne $True) {
                        $ItemSize = $Null
                        # Because the path if a file, we only need to get the file length
                        Try{
                            $ItemSize = $("{0:N2}" -f ($Item.Length / 1MB))
                        }
                        Catch {$Null}
                        # If ItemSize is null, this meen that the file is empty
                        If ($ItemSize -eq $Null) {
                            $Row.Length = 0
                        }
                        Else {
                            $Row.Length = $ItemSize
                        }
                    }
                    Else {
                        $Row.Length = ""
                    }
                    $Export += $Row
                }

            }
        }
    }
} 

Try{
    $Export | Export-Csv -Path $ExportCSV -Encoding UTF8 -NoTypeInformation | Out-Null
}
Catch {
    Log -Text "Unable to export result" -Error
}