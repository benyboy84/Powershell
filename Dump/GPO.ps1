$GPOs = get-gpo -all

foreach ($gpo in $GPOs) {

Get-GPOReport -name $gpo.displayname -ReportType HTML -Path "C:\Audit\$($gpo.displayname).html"
}