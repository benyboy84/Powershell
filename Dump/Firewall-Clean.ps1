$profiles = get-wmiobject -class win32_userprofile
cls
Write-Host "`n`n`n`n`n`n`n`n"


Write-Host "Getting Firewall Rules..."
# deleting rules with no owner would be disastrous
$Rules1 = Get-NetFirewallRule -All | 
  Where-Object {$profiles.sid -notcontains $_.owner -and $_.owner }
$Rules1Count = $Rules1.count
Write-Host "" $Rules1Count "Rules`n"

Write-Host "Getting Firewall Rules from ConfigurableServiceStore Store..."
$Rules2 = Get-NetFirewallRule -All -PolicyStore ConfigurableServiceStore | 
  Where-Object { $profiles.sid -notcontains $_.owner -and $_.owner }
$Rules2Count = $Rules2.count
Write-Host "" $Rules2Count "Rules`n"

$Total = $Rules1.count + $Rules2.count
Write-Host "Deleting" $Total "Firewall Rules:" -ForegroundColor Green

$Result = measure-command {

  $start = (Get-Date)
  $i = 0.0

  foreach($rule1 in $Rules1){

    # action
    remove-itemproperty -path "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" -name $rule1.name

    # progress
    $i = $i + 1.0
    $prct = $i / $total * 100.0
    $elapsed = (Get-Date) - $start
    $totaltime = ($elapsed.TotalSeconds) / ($prct / 100.0)
    $remain = $totaltime - $elapsed.TotalSeconds
    $eta = (Get-Date).AddSeconds($remain)

    # display
    $prctnice = [math]::round($prct,2) 
    $elapsednice = $([string]::Format("{0:d2}:{1:d2}:{2:d2}", $elapsed.hours, $elapsed.minutes, $elapsed.seconds))
    $speed = $i/$elapsed.totalminutes
    $speednice = [math]::round($speed,2) 
    Write-Progress -Activity "Deleting Rules1 ETA $eta elapsed $elapsednice loops/min $speednice" -Status "$prctnice" -PercentComplete $prct -secondsremaining $remain
  }

  foreach($rule2 in $Rules2) {

    # action  
    remove-itemproperty -path "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Configurable\System" -name $rule2.name

    # progress
    $i = $i + 1.0
    $prct = $i / $total * 100.0
    $elapse = (Get-Date) - $start
    $totaltime = ($elapsed.TotalSeconds) / ($prct / 100.0)
    $remain = $totaltime - $elapsed.TotalSeconds
    $eta = (Get-Date).AddSeconds($remain)

    # display
    $prctnice = [math]::round($prct,2) 
    $elapsednice = $([string]::Format("{0:d2}:{1:d2}:{2:d2}", $elapsed.hours, $elapsed.minutes, $elapsed.seconds))
    $speed = $i/$elapsed.totalminutes
    $speednice = [math]::round($speed,2) 
    Write-Progress -Activity "Deleting Rules2 ETA $eta elapsed $elapsednice loops/min $speednice" -Status "$prctnice" -PercentComplete $prct -secondsremaining $remain
  }
}

$end = get-date
write-host end $end 
write-host eta $eta

write-host $result.minutes min $result.seconds sec

