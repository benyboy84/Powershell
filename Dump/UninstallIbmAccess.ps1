Start-Process -FilePath msiexec -ArgumentList /x ,'{164EB883-354E-4290-AD76-67CEE65403A3}', /qn -wait
IF (Test-Path -Path "C:\AS400")
{Remove-Item "C:\AS400" -Recurse}

IF (Test-Path -Path "C:\ProgramData\IBM")
{Remove-Item "C:\ProgramData\IBM" -Recurse}

IF (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\AS400")
{Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\AS400" -Recurse}

If (test-path -Path "C:\Program Files (x86)\IBM")
{
    IF (Test-Path -Path "C:\Program Files (x86)\IBM")
    {Remove-Item "C:\Program Files (x86)\IBM" -Recurse}
 
    IF (Test-Path -Path "C:\Program Files\IBM")
    {Remove-Item "C:\Program Files\IBM" -Recurse}
}
Else
{
    IF (Test-Path -Path "C:\Program Files\IBM")
    {Remove-Item "C:\Program Files\IBM" -Recurse}
}