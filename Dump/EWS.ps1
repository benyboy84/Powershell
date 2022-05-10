#------------SCRIPT STARTS HERE-----------

 

 

 

        function TestExternalEWS () {

 

        param($emailaddress)

 

        Add-Type -Path 'C:\Program Files (x86)\Microsoft\Exchange\Web Services\2.0\Microsoft.Exchange.WebServices.dll'

     

        write-host "=> Retrieving your credentials for EWS connectivity (Domain\User and password) ..." -ForegroundColor Green

        $autod = New-Object Microsoft.Exchange.WebServices.Autodiscover.AutodiscoverService

       

 

        $Credentials = (Get-Credential)

       

       

       

        $creds=New-Object System.Net.NetworkCredential($Credentials.UserName.ToString(),$Credentials.GetNetworkCredential().password.ToString())

 

        $autod.Credentials=$creds

        $autod.EnableScpLookup = $false

        $autod.RedirectionUrlValidationCallback = {$true}

        $autod.TraceEnabled = $TraceEnabled

       

        write-host "=> Retrieving external EWS URL via Autodiscover service for the given smtp address '$emailaddress' ..." -ForegroundColor Green

        Write-Host

       

       

                try {

       

                $response = $autod.GetUserSettings(

                      $emailaddress,

                      [Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalMailboxServer,

                      [Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalEcpUrl,

                      [Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalEwsUrl,

                      [Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalOABUrl,

                      [Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalUMUrl,

                      [Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalWebClientUrls

                    )

 

 

                $ExternalEwsUrl = $response.Settings[[Microsoft.Exchange.WebServices.Autodiscover.UserSettingName]::ExternalEwsUrl]

           

                 

                 if($ExternalEwsUrl -eq $NULL) {

           

                    write-host "=> Successfully contacted Exchange Autodiscover service but couldn't retrieve autodiscovery settings for the given smtp address '$emailaddress'" -ForegroundColor Red

                    write-host "Error code:" $response.errormessage

                    Write-Host 

                    return

                    }

               

                    else {

                   

                    write-host "=> Successfully contacted Autodiscover service and retrieved the external EWS URL for the given smtp address '$emailaddress'" -ForegroundColor green

                    write-host  $externalEwsUrl -ForegroundColor Magenta

                    write-host

                   

                    }

               

               

               

        

                }

 

                catch {

 

 

 

                write-host "There was an error calling GetUserSettings() function, the error returned:" $_.exception.message -ForegroundColor Red

                Write-Host

                return

       

                }

 

# Got the EWS URL information, now testing EWS access

 

 

                write-host "=> Now making a test call (retrieving given user's OOF settings) to Exchange Web Service to test external EWS connectivity against '$externalEwsUrl' ..." -ForegroundColor Green

                Write-Host

       

               $service = new-object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_sp1)

               $uri=[system.URI] $ExternalEwsUrl

               $service.Url = $uri

       

                try {

                   

                    $oofsettings = $service.GetUserOofSettings($emailaddress)

                    Write-host "=> Successfully retrieved OOF settings." -foreground Green

                    write-host

                    write-host "OOF state: " $oofsettings.State

                    write-host "External OOF reply:"

                    write-host "============================================================================================================================================="

                    write-host $oofsettings.externalreply

                    write-host "============================================================================================================================================="

       

                }

 

                catch {

 

                    write-host "There was an error calling GetUserOofSettings() function, the error returned:" $_.exception.message -ForegroundColor Red

                    Write-Host

                }

       

 

                }

 

 

                if(($args[0] -eq $NULL))

 

                {

 

                Write-host "Please specify e-mail address to test"

                Write-Host "Example: testlyncext.ps1 user-email@contoso.com"

               

                return

 

                }

 

 

               

                $emailaddress = $args[0]

 

                TestExternalEWS($emailaddress)

 

 

 

#------------SCRIPT ENDS HERE-----------
