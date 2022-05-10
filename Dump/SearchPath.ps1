Param(
    [Parameter(Mandatory=$true)]
    [string]
    $NoCompany,
    
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    [string]
    $path="\\ad.cascades.com\apps\CTX-Apps\$($NoCompany)\Amtech\NewBizWorkflow\Data\Amtech_$($NoCompany)",

    [Parameter(Mandatory=$true)]
    [string]
    $text,

    #[Parameter(Mandatory=$true)]
    [string]
    $extension='any',

    [string]
    $exclusion='',
    
    [string]
    $PathExclusion='Logs',

    [int]
    $LenghtMax=10*1024*1024,

    [bool]
    $out=1,

    [string]
    $resultsFilePath=$path

)

#Variables :
#$path='C:\Temp\test'
#$text='Hello'
#$extension='any'
#$exclusion='csv,txt'
#$out=1
$resultsFile=$resultsFilePath + "\results-" + (Get-Date).tostring("yyyyMMdd_HHmm") + ".csv"
$XML_Result_Attachment = @()
$XML_Result_CADNumber = @()
$Count = 1

Write-Host "Start Date : " (Get-Date).tostring("yyyy-MM-dd HH:mm")

If($path.Length -eq 0)
{
    $path = $PSScriptRoot
}

If($extension.ToLower() -eq "any")
{
    $extensionToSearch = "*.*";
}
Else{
    $extension = $extension.Replace(".","");
    $extensionToSearch = "*." + $extension;
}

If($exclusion.Length -ne 0) 
{
    If($exclusion.Contains(','))
    {
    $exclusion= ('*.' + $exclusion.Replace(',',',*.')) -split ","
    }
    Else
    {
    $exclusion = $exclusion.Replace(".","")
    $exclusion = "*." + $exclusion
    }

}

$dirs = Get-ChildItem -Path $path -Recurse -Directory | where {$fn = $_.FullName; ($PathExclusion | where {$fn -like $_}).count -eq 0}
foreach($dir in $dirs) {
$Files += Get-ChildItem $dir.PsPath
}
$Files = Get-ChildItem $Path -Exclude $exclusion -Filter $extensionToSearch | Where {$_.Length -lt $LenghtMax -and $_.Directory -notcontains $PathExclusion }
$XML_Files = $Files | Where {$_.Extension -eq '.xml'} | Select-String -Pattern $text 
$OtherFiles = $Files | Where {$_.Extension -ne '.xml'} | Select-String -Pattern $text 
       
$Result = $XML_Files |Select Path,Filename,LineNumber,Line,Pattern,@{Name="Replace"; Expression={$_.Line -replace $text,$replace}}
$Result += $OtherFiles |Select Path,Filename,LineNumber,Line,Pattern,@{Name="Replace"; Expression={$_.Line -replace $text,$replace}}

foreach($File in $XML_Files){
    Write-Progress -Activity "Verifying XML files..." -Status "Checking: $($File.Name)"  -PercentComplete ($Count/$XML_Files.count*100)
    try{
        $XMLData = [xml](Get-Content $File.FullName -Encoding UTF8)
    }
    catch{
        $obj = "" | Select-Object XML_Path,Request_ID,Creation_Date,Primary_Status,Attachments
        $obj.XML_Path = $File.FullName
        $obj.Request_ID = "ERROR IMPORT XML"
        $obj.Creation_Date = "ERROR IMPORT XML"
        $obj.Primary_Status = "ERROR IMPORT XML"
        $obj.Attachments = "ERROR IMPORT XML"
        $XML_Result_Attachment += $obj

        $obj = "" | Select-Object XML_Path,Request_ID,Creation_Date,Primary_Status,Cad_Number
        $obj.XML_Path = $File.FullName
        $obj.Request_ID = "ERROR IMPORT XML"
        $obj.Creation_Date = "ERROR IMPORT XML"
        $obj.Primary_Status = "ERROR IMPORT XML"
        $obj.Cad_Number = "ERROR IMPORT XML"
        $XML_Result_CADNumber += $obj
    }
    # Check Attachments
    foreach($Part in $XMLData.REQUEST.PART){
        if($Part.PRINTING.ATTACHMENTS){
            $obj = "" | Select-Object XML_Path,Request_ID,Creation_Date,Primary_Status,Part,Attachments
            $obj.XML_Path = $File.FullName
            $obj.Request_ID = $XML.Request.id
            $obj.Creation_Date = $XML.Request.creation_date
            $obj.Primary_Status = $XML.Request.primary_status
            $obj.Part = $Part.id
            $obj.Attachments = $Part.PRINTING.ATTACHMENTS -join " "
            $XML_Result_Attachment += $obj
        }
        # Check CAD Number
        if($Part.DESIGN.cad_number){
            $obj = "" | Select-Object XML_Path,Request_ID,Creation_Date,Primary_Status,Part,Cad_Number
            $obj.XML_Path = $File.FullName
            $obj.Request_ID = $XML.Request.id
            $obj.Creation_Date = $XML.Request.creation_date
            $obj.Primary_Status = $XML.Request.primary_status
            $obj.Part = $Part.id
            $obj.Cad_Number = $Part.DESIGN.cad_number -join " "
            $XML_Result_CADNumber += $obj
        }
    }
    $Count++
}

if($XML_Result_Attachment){
    $XML_Result_Attachment | Export-Csv -Path ".\XML_Paths_$($NoCompany)-Attachments.csv" -NoTypeInformation
}

if($XML_Result_CADNumber){
    $XML_Result_CADNumber | Export-Csv -Path ".\XML_Paths_$($NoCompany)-Cad_Number.csv" -NoTypeInformation
}


If($Result.count -gt 0)
{
    Write-Host "Files that meet search criteria:"
    $Result | Select Path,Line
}
Else{
    Write-Host "No results for '$text'" -ForegroundColor DarkRed
}

If($out -and $Result.count -gt 0)
{
    $Result | Export-Csv -NoTypeInformation -Path $resultsFile
}

Write-Host "End Date : " (Get-Date).tostring("yyyy-MM-dd HH:mm")