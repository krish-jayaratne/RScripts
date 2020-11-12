##################################################################
#     Download object
#################################################################


Function Format-Json 
{
    param ( $json )

    ($json -split '\r\n' |
    % {
      $line = $_
      if ($_ -match '^ +') {
        $len  = $Matches[0].Length / 8  #assuming 8 space tab, which is the default of PS
        $line = ' ' + ' ' * $len + $line.TrimStart()
      }
      $line
    }) -join "`r`n"
}



function Get-AccessToken {
    param (
        $clent_id, $clent_secret, $token_uri, $redirct_uri, $refresh_token
    )

    $param = @"
grant_type=refresh_token&
client_id=$cid&
client_secret=$cse&
redirect_uri=$ruri&
refresh_token=$rtkn
"@
    $param = $param -replace("\r\n","")

    try
    {
        $resp = Invoke-WebRequest -uri https://oauth2.googleapis.com/token -Method Post -Body $param

        $jresp = ConvertFrom-Json -InputObject $resp

         $resp.StatusCode, $jresp.access_token
    }
    catch
    {
        $_.Exception.Response.StatusCode
    }

}
 

Function Receive-File {
    Param
    (
       $uri, $Token  
    )
    
    try
    {   
        $res = Invoke-WebRequest -Uri $uri  -Headers @{"Authorization" = "Bearer $Token"} -OutFile  $env:TEMP"\googledata.txt"
        $jres=convertfrom-json $res


        $res.StatusCode
        write-host "test"
    }
    catch 
    {
        $_.Exception.Response.statuscode
    }
}

Function Receive-FileWCLient{
    param
    (
        $uri, $token
    )
    try
    {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Authorization", "Bearer $Token")
        $resp = $wc.DownloadFile($uri,  $env:TEMP+"\googledatad.txt")
        "", "File downloaded"
    }
    catch
    {    
      $_.Exception.Hresult, $_.Exception.Message 
    }
     
    write-host $resp
}

#Remove below for Red 
$cid="687147849267-reoeac2tpgromo7kvif4mc0u5ps3p5k1.apps.googleusercontent.com"
$cse="fwHh0r7R1ozkv9F97Mo_YR7A&"
$ruri="https://127.0.0.1"
$rtkn="1//0g0hP-aL84l8kCgYIARAAGBASNwF-L9Iry55vb8-tESVJZMHs-c0nAW5-PlphaU-0s6KFGlbFnZUnPkaJSGe7pH2m9xJ08KuPumU"
$duri = "https://storage.googleapis.com/storage/v1/b/krishtestbucket1/o"
$turi = "https://oauth2.googleapis.com/token"
$mediaUri = "https://storage.googleapis.com/download/storage/v1/b/krishtestbucket1/o/r.json?generation=1602653213621322&alt=media"

#Comment below for local run, uncomment for Red
<#
$cid="$env:WSL_SRCCFG_ClientId"  
$cse="$env:WSL_SRCCFG_ClientSecret"
$turi="$env:WSL_SRCCFG_TokenUrl" 
$ruri="$env:WSL_SRCCFG_RdirUri"
$duri="$env:WSL_SRCCFG_storagepath"
$rtkn="$env:WSL_SRCCFG_RefreshToken"
#>


$loopcount=0
$logdata=""
$retcode=
$retmessage=""
try
  {
      $accToken = Get-Content -Path $AccTokenFile -ErrorAction stop
      $logdata += "`n" + "Read token from disk"
  }
catch
{
    $accToken=""
}

Do
{

    if ($accToken.length -eq 0 )
    {
        $retCode, $AccToken=Get-AccessToken -clent_id $cid -clent_secret $cse -token_uri $turi  -redirct_uri $ruri -refresh_token $rtkn
        $logdata += "`n"  + "Get-AccessToken returned: " + $retCode
        if ($RetCode -eq "200")
        {
           Set-Content $AccTokenFile -Value $accToken -ErrorAction stop
           try 
           {
              $logdata += "`n" + "Wrote token to disk"
           }
           Catch
           {
              $logdata += "`n" + "Warning:failed to write token to disk"
           }
        }
    }
#        $RetCode = Receive-File -uri $mediaUri -Token $accToken
        $RetCode, $retmessage = Receive-FileWCLient -uri $mediaUri -Token $accToken

    if ( $RetCode.length -eq 0)
    {
         $logdata += "`n" + $retmessage
        Get-Content -Path  $env:TEMP"\googledatad.txt" -tail 1
    }
    else
    {
       $logdata += "`n"  + $retmessage +"Ret code: "  + $RetCode

       if ( ($retmessage -match "\(401\) Unauthorized") -and $loopcount -lt 1)
       {
           $logdata += "`n"  + "Setting to get a new access token"
           $AccToken=""
       }
       else
       {
          if ($loopcount -eq 1) {$logdata += "`n" + "Getting access token failed "}
          else { $logdata += "`n" + "Unknown error message from server "}
       }

    } 

    $loopcount++


} until ( $RetCode.length -eq 0 -or  $loopcount -gt 1 )
$logdata

