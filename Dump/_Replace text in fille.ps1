# **********************************************************************************
# Script to replace string in file.
# This script can be use with one file, a folder or folder and subfolder.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2019-09-06  Benoit Blais        First iteration
# **********************************************************************************

# **********************************************************************************

# Parameters
Param(
  [Parameter(Mandatory=0)]
  [String]$SOURCE,
  [Parameter(Mandatory=0)]
  [String]$RECURSIVE,
  [Parameter(Mandatory=0)]
  [String]$CSV,
  [Parameter(Mandatory=0)]
  [String]$FROM,
  [Parameter(Mandatory=0)]
  [String]$TO,
  [Parameter(Mandatory=0)]
  [String]$FILTER,
  [Parameter(Mandatory=0)]
  [String]$OUTPUT
  )

# **********************************************************************************

Clear-Host

# **********************************************************************************

# This section contain all the function required by this script.

# Validate-Source
# This function validate if the XML variable contain a valid folder path or XML file.
Function Validate-Source([string]$Path){
  # Validate if the parameter is empty or not. If it's empty, we will exit the 
  # function with false value.
  If($Path -ne ""){ 
    # Validate if the path exist. If the path does not exist, we will exit the 
    # function with false value.
    If(Test-Path -Path $Path){ 
      # Validate if the variable contain a folder or a file path.
      # If it's a folder, we set the global variable folder to true and exist the 
      # function with true value. Otherwise, we will exit the function with false value.
      If((Get-Item $Path) -is [System.IO.DirectoryInfo]){
        $GLOBAL:FOLDER = $True
        Return $True
        }
    }
    Else{
      Write-Host "The specified location does not exist." -ForegroundColor Red
      Write-Host "`n"
      Return $False
      }
    }
  Else{
    Write-Host "You need to specify the location where the source files are located." -ForegroundColor Red
    Write-Host "`n"
    Return $False
    }
  }

# Validate-CSV
# This function validate if the CSV variable contain a valid CSV file.
Function Validate-CSV([string]$File){
  # Validate if the parameter is empty or not. If it's empty, we will exit the 
  # function with false value.
  If($File -ne ""){
    # Validate if the path exist. If the path does not exist, we will exit the 
    # function with false value. If the path exist, we will validate if it's a 
    # CSV file. If it's the case, we will exist the function with a true value. 
    # Otherwise, we will exit the function with false value.
    If(Test-Path -Path $File){
      $extn = [IO.Path]::GetExtension($File)
      If($extn -eq ".csv" ){
        Return $True
        }
      Else{
        Write-Host "The specified file is not a CSV file." -ForegroundColor Red
        Write-Host "`n"
        Return $False
        }
      }
    Else{
      Write-Host "The specified file does not exist." -ForegroundColor Red
      Write-Host "`n"
      Return $False
      }
    }
  Else{
    Write-Host "You need to specify a CSV file containing the text to replace." -ForegroundColor Red
    Write-Host "`n"
    Return $False
    }
}

# **********************************************************************************

# SOURCE parameter validation.
# If the parameter is specified, we will validate if. Otherwhise, we
# will ask the user to enter one and we will validate it.
# Loop until the SOURCE variable contain a valid path.
While(!(Validate-Source $SOURCE)){
    Write-Host "Enter the location of the sources file(s)." -ForegroundColor Cyan
    Write-Host "It could be a file or a folder containing files."  -ForegroundColor Cyan
    Write-Host "Source location: " -ForegroundColor Gray -NoNewline
    $SOURCE = Read-Host
    Write-Host "`n"
  }

# **********************************************************************************

# Recursive parameter validation.
# If the parameter is specified, we will validate if it is adequate. Otherwhise, we
# will ask the user to enter one and we will validate it.
:Recurse While(($RECURSIVE -eq "") -And ($GLOBAL:FOLDER)){
  write-host $RECURSIVE
  Write-Host "Do you want to loop in subfolder?" -ForegroundColor Cyan
  Write-Host "[Y] Yes " -ForegroundColor Cyan -NoNewline
  Write-Host "[N] No " -ForegroundColor Yellow -NoNewline
  Write-Host "(default is N): " -ForegroundColor Cyan -NoNewline
  $RECURSIVE = Read-Host
  switch($RECURSIVE.ToLower()){
    ""      {Write-Host "No" -ForegroundColor White -NoNewline
             Write-Host "`n"
             $RECURSIVE = $False
             Break Recurse}
    "y"     {Write-Host "`n"
             $RECURSIVE = $True
             Break Recurse}
    "yes"   {Write-Host "`n"
             $RECURSIVE = $True
             Break Recurse}
    "n"     {Write-Host "`n"
             $RECURSIVE = $False
             Break Recurse}
    "no"    {Write-Host "`n"
             $RECURSIVE = $False
             Break Recurse}
    default {Write-Host "`n"
             $RECURSIVE = ""}
    }
  }

If(($RECURSIVE -ne "") -And !($GLOBAL:FOLDER)){
  Write-Host "The recursive option cannot be use with file." -ForegroundColor Red
  Write-Host "`n"
}

# **********************************************************************************

# Validate if the user enter a value for CSV, FROM and TO variable at the same time.
If((!($CSV -eq "") -and !($FROM -eq "") -and !($TO -eq "")) -or (!($CSV -eq "") -and (!($FROM -eq "") -or !($TO -eq "")))){
  Write-Host "You cannot specify a CSV file, FROM and TO at the same time." -ForegroundColor Red
  Write-Host "`n"
  $CSV = ""
  $FROM = ""
  $To = ""
  }

# **********************************************************************************

# Because all variable are empty, first, ask the user if he want to use a CSV file.
If(($CSV -eq "") -and ($FROM -eq "") -and ($TO -eq "")){
  $USECSV = ""
  :CSV  While($USECSV = " "){
    Write-Host "Do you want to use a CSV file? "  -ForegroundColor Cyan
    Write-Host "[Y] Yes " -ForegroundColor Cyan -NoNewline
    Write-Host "[N] No " -ForegroundColor Yellow -NoNewline
    Write-Host "(default is N): " -ForegroundColor Cyan -NoNewline
    $USECSV = Read-Host
    $USECSV.ToLower()
    switch($USECSV.ToLower()){
      ""      {Write-Host "No" -ForegroundColor White -NoNewline
               Write-Host "`n"
               $USECSV = $False
               Break CSV}
      "n"     {Write-Host "`n"
               $USECSV = $False
               Break CSV}
      "no"    {Write-Host "`n"
               $USECSV = $False
               Break CSV}
      "y"     {Write-Host "`n"
               $USECSV = $True
               Break CSV}
      "yes"   {Write-Host "`n"
               $USECSV = $True
               Break CSV}
      default {Write-Host "`n"
               $USECSV = ""}
      }
    }
  }

# **********************************************************************************

# Validate if the user enter the FROM and the TO parameters.
If((($FROM -eq "") -or ($TO -eq "")) -and !($USECSV)){
  $USECSV = $False
  While($FROM -eq ""){
    Write-Host "Specify the text to replace: "  -ForegroundColor Cyan -NoNewline
    $FROM = Read-Host
    Write-Host "`n"
    }
  While($TO -eq ""){
    Write-Host "Specify the replacement text: "  -ForegroundColor Cyan -NoNewline
    $To = Read-Host
    Write-Host "`n"
    }
  }

# **********************************************************************************

# CSV parameter validation.
# If the parameter is specified, we will validate if it is adequate. Otherwhise, we
# will ask the user to enter one and we will validate it.
If(($USECSV)){
  While(!(Validate-CSV $CSV)){ 
    Write-Host "Enter the location of the CSV file containing the from and to field o find and replace text."  -ForegroundColor Cyan
    Write-Host "The CSV file need to be in this format: from,to"  -ForegroundColor Cyan
    Write-Host "CSV file: " -ForegroundColor Gray -NoNewline
    $CSV = Read-Host
    Write-Host "`n"
    }
  }

# **********************************************************************************

If(($FILTER -eq "") -And ($GLOBAL:FOLDER)){
  While($True){
    Write-Host "Do you want filter file by extension?" -ForegroundColor Cyan
    Write-Host "[Y] Yes " -ForegroundColor Cyan -NoNewline
    Write-Host "[N] No " -ForegroundColor Yellow -NoNewline
    Write-Host "(default is N): " -ForegroundColor Cyan -NoNewline
    $FILTER = Read-Host
    If($FILTER -Like ""){
      Write-Host "No" -ForegroundColor White -NoNewline
      Write-Host "`n"
      $FILTER = $False
      Break
      }
    Else{
      If(($FILTER -Like "N") -or ($FILTER -Like "NO")){
        Write-Host "`n"
        $FILTER = $False
        Break
        }
      If(($FILTER -Like "Y") -or ($FILTER -Like "YES")){
        Write-Host "`n"
        $FILTER = $True
        Write-Host "Enter the file extension on which you want to filter." -ForegroundColor Cyan
        Write-Host "File extension: " -ForegroundColor Gray -NoNewline
        $EXT = Read-Host
        Write-Host "`n"
        If($EXT.StartsWith(".")){
          $EXT = "*" + $EXT
          }
        Else{
          $EXT = "*." + $EXT
          }
        Break
        }
      Write-Host "`n"
      $FILTER = ""
      }
    }
  }

# **********************************************************************************

Clear-Host

# **********************************************************************************

If($GLOBAL:FOLDER){
  If($Recursive){
    $SOURCE_Files = Get-ChildItem -Path $SOURCE -Recurse -Filter $EXT
    }
  Else{
    $SOURCE_Files = Get-ChildItem -Path $SOURCE -Filter $EXT
    }
  }
Else{
  $SOURCE_Files = Get-Item -Path $SOURCE
  }

If($CSV -ne ""){
  $CSV_Replaces = Import-Csv $CSV -Header from,to
  }


$Result = @()

ForEach($File in $SOURCE_Files){

  If($CSV -ne ""){
    ForEach($Line in $CSV_Replaces){
      $Matches = Select-String -InputObject $Temp -Pattern ([regex]::Escape($Line.from)) -AllMatches
      $Matches = $Matches.Matches.count
    
        $Temp = Get-Content -Path $File.FullName
      
        $Temp -replace [Regex]::Escape($Line.From), $Line.To | Set-Content -Path $File.FullName -Force -encoding ascii

      

    
        $obj = "" | Select-Object File,From,To,Qty
        $obj.File = $File.FullName
        $obj.From = $Line.From
        $obj.To = $Line.To
        $obj.Qty = $Matches
        $Result += $obj
      

    }
    }
  Else{

      $Matches = Select-String -InputObject $Temp -Pattern ([regex]::Escape($FROM)) -AllMatches
      $Matches = $Matches.Matches.count
    
        $Temp = Get-Content -Path $File.FullName
      
        #$Temp -replace [Regex]::Escape($FROM), $TO | Set-Content -Path $File.FullName -Force -encoding ascii
        $Temp -replace $FROM, $TO | Set-Content -Path $File.FullName -Force -encoding ascii

      

    
        $obj = "" | Select-Object File,From,To,Qty
        $obj.File = $File.FullName
        $obj.From = $FROM
        $obj.To = $TO
        $obj.Qty = $Matches
        $Result += $obj
    }
  $Count++
  }
$Result

$SOURCE = ""
$RECURSIVE = ""
$CSV = ""
$FROM = ""
$TO = ""
$FILTER = ""
$OUTPUT = ""
$EXT = ""
$USECSV = ""

$GLOBAL:FOLDER = ""

Pause

 