$Profile = "\\fsx-prod\FSLogix"
$Users = Get-ChildItem -Path $Profile
$Export = @()
$ExportCSV = "C:\Scripts\Benoit\ProfileCleanup.csv"
ForEach ($User in $Users) {
    If (Test-Path "$($Profile)\$($User)\Win2019v6\UPM_Profile") {

        If (([ADSISearcher] "(sAMAccountName=$($User))").FindOne()) {
            If (Test-Path "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Google\Chrome\User Data\Default\Service Worker"){

                Remove-Item -Recurse -Force "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Google\Chrome\User Data\Default\Service Worker"
                


            }

            If (Test-Path "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Microsoft\Office\16.0\OfficeFileCache"){
                
                Remove-Item -Recurse -Force "$($Profile)\$($User)\Win2019v6\UPM_Profile\AppData\Local\Microsoft\Office\16.0\OfficeFileCache"

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