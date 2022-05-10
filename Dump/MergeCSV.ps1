# **********************************************************************************
# Script to merge CSV files.
# ==================================================================================
# 
# Date        Par                 Modification
# ----------  ------------------  -----------------------------------------------
# 2019-09-23  Benoit Blais        First iteration
# **********************************************************************************

# **********************************************************************************

<#
.SYNOPSIS
This is a simple Powershell script to merge many CSV into one.

.DESCRIPTION
This script can be use with or without parameters. It will merge many CSV file with
the same header into one single file. 
Note: the output file need to be outside the source folder.

.EXAMPLE
./Merge CSV.ps1

.EXAMPLE
./Merge CSV.ps1 -SOURCE C:\TEMP -RECURSIVE Yes -OUTPUT C:\TEMP\MERGE

.EXAMPLE
./Merge CSV.ps1 -SOURCE C:\TEMP -RECURSIVE Yes -Filter Temp* -OUTPUT C:\TEMP\MERGE

.PARAMETER SOURCE
This folder must contain the CSV files that will be merged into a single file.

.PARAMETER RECURSIVE
If you want to loop in subfolder, we need to specefy (Y or Yes) to use recursive option.
If the parameter is not specified, the default value is No.

.PARAMETER FILTER
If you want to filter for a specific string in the file name, we need to specefy it with the FILTER 
parameter. You need to put * for any other characters.
If the parameter is not specified, the default value is No Filter.

.PARAMETER OUTPUT
This is the CSV fille where all the data will be merged.
Note: the output file need to be outside the source folder and this script will
not create any directory. You need to specefy a valid path.

#>

# **********************************************************************************

# Parameters
Param(
  [Parameter(Mandatory=$false)]
  [String]$SOURCE,
  [Parameter(Mandatory=$false)]
  [String]$RECURSIVE,
  [Parameter(Mandatory=$false)]
  [String]$FILTER,
  [Parameter(Mandatory=$false)]
  [String]$OUTPUT
  )

# **********************************************************************************

Clear-Host

# **********************************************************************************

Function Validate-Source([string]$Path){
  # Validate if the parameter is empty or not. If it's empty, we will exit the 
  # function with false value.
  If($Path -ne ""){ 
    # Validate if the path exist. If the path does not exist, we will exit the 
    # function with false value.
    If(Test-Path -Path $Path){ 
      # Validate if the variable contain a folder.
      # If it's a folder, we set the global variable folder to true and exist the 
      # function with true value. Otherwise, we will exit the function with false value.
      If((Get-Item $Path) -is [System.IO.DirectoryInfo]){
        Return $True
      }
      Else{
        Write-Host "You need to specify a folder." -ForegroundColor Red
        Write-Host "`n"
        Return $False
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

Function Validate-Output{
    Param
        (
            [Parameter(Mandatory=$false, Position=0)]
            $SOURCE,
            [Parameter(Mandatory=$false, Position=1)]
            $OUTPUT
        )
    # Validate if the parameter is empty or not. If it's empty, we will exit the 
    # function with false value.
    If(!($OUTPUT -like "")){
        # Validate if the path exist. If the path does not exist, we will exit the 
        # function with false value. If the path exist, we will validate if it's a 
        # CSV file. If it's the case, we will exist the function with a true value. 
        # Otherwise, we will exit the function with false value.
        $OutputFolder = $OUTPUT.substring(0,$OUTPUT.LastIndexOf('\'))
        If(Test-Path -Path $OutputFolder){

            #IF ($SOURCE -notmatch '.+?\\$'){
            #    $SOURCE += "\*"
            #}
            #Else{
            #    $SOURCE += "*"
            #}
            If ($OUTPUT -notcontains $SOURCE){
                $extn = [IO.Path]::GetExtension($OUTPUT)
                If($extn -eq ".csv" ){
                    If (!(Test-Path $OUTPUT)){
                        Return $True
                    }
                    Else{
                        Write-Host "Warning: The output file already exist." -ForegroundColor Red
                        Write-Host "Do you want to replace the existing file?" -ForegroundColor Cyan
                        Write-Host "[Y] Yes " -ForegroundColor Cyan -NoNewline
                        Write-Host "[N] No " -ForegroundColor Yellow -NoNewline
                        Write-Host "(default is N): " -ForegroundColor Cyan -NoNewline
                        $REPLACE = Read-Host
                        switch($REPLACE.ToLower()){
                                            ""      {Write-Host "No" -ForegroundColor White -NoNewline
                                                     Write-Host "`n"
                                                     Return $False}
                                            "y"     {Write-Host "`n"
                                                     Try{
                                                         Remove-Item –path $OUTPUT -ErrorAction 'Stop'
                                                         Return $True
                                                     }
                                                     Catch{
                                                         Write-Host "Warning: Error when deleting file." -ForegroundColor Red
                                                         Write-Host "You need to specify another output file." -ForegroundColor Red
                                                         Return $False
                                                     }
                                                    }
                                            "yes"   {Write-Host "`n"
                                                     Try{
                                                         Remove-Item –path $OUTPUT -ErrorAction 'Stop'
                                                         Return $True
                                                     }
                                                     Catch{
                                                         Write-Host "Warning: Error when deleting file." -ForegroundColor Red
                                                         Write-Host "You need to specify another output file." -ForegroundColor Red
                                                         Return $False
                                                     }
                                                    }
                                            "n"     {Write-Host "`n"
                                                     Return $False}
                                            "no"    {Write-Host "`n"
                                                     Return $False}
                                            default {Write-Host "`n"
                                                     Return $False}
                                            }
                    }
                }
            Else{
                Write-Host "The specified file is not a CSV file." -ForegroundColor Red
                Write-Host "`n"
                Return $False
            }
        }
        Else{
          Write-Host "The output file need to be outside the source folder." -ForegroundColor Red
          Write-Host "`n"
          Return $False
        }
      }
    Else{
      Write-Host "The parent folder does not exist." -ForegroundColor Red
      Write-Host "`n"
      Return $False
      }
    }
  Else{
    Write-Host "You need to specify a CSV file for the output." -ForegroundColor Red
    Write-Host "`n"
    Return $False
    }
}

# **********************************************************************************

If (($SOURCE -ne "") -and ($OUTPUT -ne "")) {
    $PARAM = $True
}
Else {
    $PARAM = $False
}

While(!(Validate-Source $SOURCE)){
    Write-Host "Enter the location of the sources file(s)." -ForegroundColor Cyan
    Write-Host "Source location: " -ForegroundColor Gray -NoNewline
    $SOURCE = Read-Host
    Write-Host "`n" 
}

:Recurse While(($RECURSIVE -eq "") -and ($PARAM -ne $True)){
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

:Filter While (($FILTER -eq "") -and ($PARAM -ne $True)){
  Write-Host "Do you want to add filter for the file name?" -ForegroundColor Cyan
  Write-Host "[Y] Yes " -ForegroundColor Cyan -NoNewline
  Write-Host "[N] No " -ForegroundColor Yellow -NoNewline
  Write-Host "(default is N): " -ForegroundColor Cyan -NoNewline
  $FILTER = Read-Host
  switch($FILTER.ToLower()){
    ""      {Write-Host "No" -ForegroundColor White -NoNewline
             Write-Host "`n"
             $FILTER = $False
             Break Filter}
    "y"     {Do {Write-Host "`n"
                 Write-Host "Type the filter string." -ForegroundColor Cyan
                 Write-Host "Example: Test*" -ForegroundColor Cyan
                 Write-Host "Filter string: " -ForegroundColor Gray -NoNewline
                 $FILTER = Read-Host
                 } While ($FILTER -eq "")
                 Break Filter
            }
    "yes"   {Do {Write-Host "`n"
                 Write-Host "Type the filter string." -ForegroundColor Cyan
                 Write-Host "Example: Test*" -ForegroundColor Cyan
                 Write-Host "Filter string: " -ForegroundColor Gray -NoNewline
                 $FILTER = Read-Host
                 } While ($FILTER -like "")
                 Break Filter
            }
    "n"     {Write-Host "`n"
             $FILTER = $False
             Break Filter}
    "no"    {Write-Host "`n"
             $FILTER = $False
             Break Filter}
    default {Write-Host "`n"
             $FILTER = ""}
    }
}

While(!(Validate-Output $SOURCE $OUTPUT)){
    Write-Host "Enter the location of the output file." -ForegroundColor Cyan
    Write-Host "Source location: " -ForegroundColor Gray -NoNewline
    $OUTPUT = Read-Host
    Write-Host "`n"}


IF ($SOURCE -notmatch '*\'){
    $SOURCE += "\*"
}
Else{
$SOURCE += "*"
}

If ($RECURSIVE -like "True"){
    If ($FILTER -like "False") {
        Try {$ITEM = Get-ChildItem -Path $SOURCE -Recurse -Include *.csv -ErrorAction Stop}
        Catch{
            Write-Host "Warning: Error when getting source files." -ForegroundColor Red
            Exit
        }
    }
    Else{
        Try {$ITEM = Get-ChildItem -Path $SOURCE -Recurse -Include *.csv -Filter $FILTER -ErrorAction Stop}
        Catch{
            Write-Host "Warning: Error when getting source files." -ForegroundColor Red
            Exit
        }
    }
}
Else{
    If ($FILTER -like "False") {
        Try {$ITEM = Get-ChildItem -Path $SOURCE -Include "*.csv" -ErrorAction Stop}
        Catch {
            Write-Host "Warning: Error when getting source files." -ForegroundColor Red
            Exit
        }
    }
    Else{
        Try {$ITEM = Get-ChildItem -Path $SOURCE -Include *.csv -Filter $FILTER -ErrorAction Stop}
        Catch {
            Write-Host "Warning: Error when getting source files." -ForegroundColor Red
            Exit
        }
    }
}

If ($Item.Count > 0) {
    $ITEM | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $OUTPUT -NoTypeInformation -Append
}
Else{
    Write-Host "Warning: No file to merge." -ForegroundColor Red
    Exit
}