function Get-AccessToken {
    param (
        $clent_id, $clent_secret, $redirct_uri, $refresh_token
    )

    $param = @"
grant_type=refresh_token&
client_id=$cid&
client_secret=$cse&
redirect_uri=$ruri&
refresh_token=$rtkn
"@
    $param = $param -replace("\r\n","")
    $resp = Invoke-WebRequest -uri https://oauth2.googleapis.com/token -Method Post -Body $param


    $jresp = ConvertFrom-Json -InputObject $resp
    #$jresp | format-list

    $jresp.access_token

}
 
Function Get-GoogleStorageData {
    param ( 
       $uri, $Token 
    )

    try
    {   
        #$Token="Bad"
        
        $res = Invoke-WebRequest -Uri $uri  -Headers @{"Authorization" = "Bearer $Token"} 
        #$res
        $jres=convertfrom-json $res
        #$jres
        $res.StatusCode, $jres.items
    }
    catch 
    {
        Write-Host "Exception cought"
        $_.Exception.Response.statuscode
    }
}



$cid="687147849267-reoeac2tpgromo7kvif4mc0u5ps3p5k1.apps.googleusercontent.com"
$cse="fwHh0r7R1ozkv9F97Mo_YR7A&"
$ruri="https://127.0.0.1"
$rtkn="1//0g0hP-aL84l8kCgYIARAAGBASNwF-L9Iry55vb8-tESVJZMHs-c0nAW5-PlphaU-0s6KFGlbFnZUnPkaJSGe7pH2m9xJ08KuPumU"
$duri = "https://storage.googleapis.com/storage/v1/b/krishtestbucket1/o"


#$AccToken=""
if ($accToken.length -eq 0 )
{
    $AccToken=Get-AccessToken -clent_id $cid -clent_secret $cse -redirct_uri $ruri -refresh_token $rtkn
    Write-Host "access token=" $AccToken
}

$data=""
$RetCode, $data = Get-GoogleStorageData -uri $duri -Token $accToken
if ( $RetCode -eq "200")
{
     convertto-json -inputobject ( $data | Select-Object -Property name,size,bucket ) 
}
else
{
   write-host "failed" 
   $RetCode
   if ($RetCode -eq "Unauthorized")
   {
       write-host "Obtaining another access token"
       $AccToken=Get-AccessToken -clent_id $cid -clent_secret $cse -redirct_uri $ruri -refresh_token $rtkn

       $RetCode, $data = Get-GoogleStorageData -uri $duri -Token $accToken

       if ( $RetCode -eq "200")
       {
          convertto-json -inputobject $data.name
       }
       else
       {
          write-host "Second token failed too"
       }

   }
}