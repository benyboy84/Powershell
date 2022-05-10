#requires -RunAsAdministrator

# Is the OS Windows 10?
If ((Get-CimInstance Win32_OperatingSystem).Caption -like "*Windows 10*")

# Is the RSAT already installed?
If (Get-HotFix -Id KB2693643 -ErrorAction SilentlyContinue)

# Is this x86 or x64 CPU?
If ((Get-CimInstance Win32_ComputerSystem).SystemType -like "x64*")

# Download the hotfix for RSAT install
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($URL,$Destination)
$WebClient.Dispose()

# Install the hotfix. No native PowerShell way that I could find.
# wusa.exe returns immediately. Loop until install complete.
wusa.exe $Destination /quiet /norestart /log:$home\Documents\RSAT.log
do {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 3
} until (Get-HotFix -Id KB2693643 -ErrorAction SilentlyContinue)

# Double-check that the role is enabled after install.
If ((Get-WindowsOptionalFeature -Online -FeatureName `
    RSATClient-Roles-AD-Powershell -ErrorAction SilentlyContinue).State `
    -eq 'Enabled') {

    Write-Verbose '---RSAT AD PowerShell already enabled'

} Else {

    Enable-WindowsOptionalFeature -Online -FeatureName `
         RSATClient-Roles-AD-Powershell
}

# Install the help
Update-Help -Module ActiveDirectory -Verbose -Force

# Optionally verify the install.
dir (Join-Path -Path $HOME -ChildPath Downloads\*msu)
Get-HotFix -Id KB2693643
Get-Help Get-ADDomain
Get-ADDomain
