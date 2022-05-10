<# 
   .Synopsis 
    Translates a user name to a SID or a SID to a user name. 
   .Description 
    This script translates a user name to a SID or a SID to a user name. 
    Note: To translate the user name to the SID, you must 
    use the logon name (SAMAccountName), and not the full user name. 
   .Example 
    UserToSid.ps1  -user "mytestuser" 
    Displays SID of mytestuser in current domain 
   .Example 
    UserToSid.ps1  -sid "S-1-5-21-1877799863-120120469-1066862428-500" 
    Displays user with SID of "S-1-5-21-1877799863-120120469-1066862428-500" 
   .Inputs 
    [string] 
   .OutPuts 
    [string] 
   .Notes 
    NAME:  UserToSid-SidToUser.ps1 
    AUTHOR: Ed Wilson 
    LASTEDIT: 10/05/2010 
    VERSION: 2.0 
    KEYWORDS: Active Directory, user accounts, Security.Principal.SecurityIdentifier 
   .Link 
     Http://www.ScriptingGuys.com 
#Requires -Version 2.0 
#> 
param( 
      [string] 
      $domain = $env:USERDOMAIN, 
      [string] 
      $user, 
      [string] 
      $sid 
      ) #end param 

# Begin Functions 

function New-Underline 
{ 
<# 
.Synopsis 
 Creates an underline the length of the input string 
.Example 
 New-Underline -strIN "Hello world" 
.Example 
 New-Underline -strIn "Morgen welt" -char "-" -sColor "blue" -uColor "yellow" 
.Example 
 "this is a string" | New-Underline 
.Notes 
 NAME: 
 AUTHOR: Ed Wilson 
 LASTEDIT: 5/20/2009 
 VERSION: 2.0 
 KEYWORDS: scripting techniques, string manipulation 
.Link 
 Http://www.ScriptingGuys.com 
#> 
[CmdletBinding()] 
param( 
      [Parameter(Mandatory = $true,Position = 0,valueFromPipeline=$true)] 
      [string] 
      $strIN, 
      [string] 
      $char = "=", 
      [string] 
      $sColor = "Green", 
      [string] 
      $uColor = "darkGreen", 
      [switch] 
      $pipe 
 ) #end param 
 $strLine= $char * $strIn.length 
 if(-not $pipe) 
  { 
   Write-Host -ForegroundColor $sColor $strIN 
   Write-Host -ForegroundColor $uColor $strLine 
  } 
  Else 
  { 
   $strIn 
   $strLine 
  } 
} #end New-Underline function 

Function Get-UserToSid() 
{ 
  $ntAccount = new-object System.Security.Principal.NTAccount($domain, $user) 
  $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier]) 
  New-UnderLine("$domain/$user sid is:") 
  ($local:sid).value 
  exit 
} #end UserToSid 

Function Get-SidToUser() 
{ 
 New-Underline("Obtaining SID translation ... this might take a bit of time ...") 
 New-UnderLine("Sid: $sid is:") 
 [adsi]"LDAP://<SID=$sid>" 
 exit 
} #end sidToUser 

# *** Entry point to script *** 

if($sid)       { Get-SidToUser } 
if($user)      { Get-UserToSid }