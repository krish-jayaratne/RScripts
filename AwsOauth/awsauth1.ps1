# **********************************************************
# ***** PowerShell script example
# ***** Example for Google Storage Brows
# **********************************************************

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
        $resp = Invoke-WebRequest -uri $token_uri -Method Post -Body $param

        $jresp = ConvertFrom-Json -InputObject $resp

         $resp.StatusCode, $jresp.access_token
    }
    catch
    {
        $_.Exception.Response.StatusCode
    }

}
 
Function Get-GoogleStorageData {
    param ( 
       $uri, $Token 
    )

    try
    {   
        $res = Invoke-WebRequest -Uri $uri  -Headers @{"Authorization" = "Bearer $Token"} 
        $jres=convertfrom-json $res
        $res.StatusCode, $jres.items
    }
    catch 
    {
        $_.Exception.Response.statuscode
    }
}

Function Get-s3bucketcontent {
    param ( 
       $uri, $Token 
    )

    try
    {   
        $res = Invoke-WebRequest -Uri $uri  -Headers @{"Authorization" = "Bearer $Token"} 
        $jres=convertfrom-json $res
        $res.StatusCode, $jres.items
    }
    catch 
    {
        $_.Exception.Response.statuscode
    }
}

Function Format-DataToJson{
    
    param ( $data ) 
    $jloadinfo = 
@"
{
	"fileLoaderOptions": "TABLOCK",
	"fileParsed": true,
	"overrideLoadSQL": "",
	"overrideSourceColumns": "",
	"selectDistinctValues": false,
	"sourceFile":
          {
			"charSet": "",
			"escapeEncoding": "",
			"fieldDelimiter": "|",
			"fieldEnclosure": "\\",
			"headerLine": true,
			"name": "",
			"nonStringNullEncoding": "",
			"nullEncoding": "",
			"path":"",
			"recordDelimiter":""
		},
	"sourceSchema": "sourceSchema",
	"sourceTables": "",
	"useOverrideSourceColumns": false,
	"whereAndGroupByClauses": ""
  }
"@
$jcolumns = @"
{
	"name": "data",
	"dataType": "text",
	"dataTypeLength": 64,
	"dataTypeScale": null,
	"dataTypePrecision": null,
	"nullAllowed": true,
	"defaultValue": "",
	"displayName": "data",
	"description": "JSON data",
	"format": "",
	"additive": false,
	"numeric": false,
	"attribute": false,
	"sourceTable": "myfile",
	"sourceColumn": "1",
	"transform": "",
	"transformType": "",
	"uiConfigColumnProperites": {}
}
"@
    $psdataPref =@{	"treeViewLayout"="List"; "treeViewIcons"=@{"schema"= "database.ico"; "table"="table.ico"}}
  	$bucket = $data.Item(1).bucket
    $psdata = @{}
    $a=0

    
    foreach ($d in $data)
    {
       $columns= @()
       $columns += $(convertfrom-json $jcolumns)
       $columns[0].sourceTable=$d.name
       $loadinfo = ConvertFrom-Json $jloadinfo
       $psdata =  add-member -InputObject $psdata -NotePropertyMembers @{$d.name = @{"name"=$d.name; "description" = $d.selflink; "rowCount"=[int32]$d.size; "uiConfigLoadTableProperties"= @{}; "columns"=$columns; "loadInfo"=$loadinfo } } -PassThru
       $psdata.($d.name).loadinfo.sourcefile.name = $d.name
       $psdata.($d.name).loadinfo.sourcefile.path = $d.selflink
       $psdata.($d.name).loadinfo.sourceSchema = $d.generation
       $psdata.($d.name).loadinfo.sourceTables = $d.name
    }

    $psJsonData =  add-member -inputObject $psdataPref  -notePropertyMembers @{$bucket=$psdata } -PassThru

    $JsonData = convertto-json -Depth 7 -inputobject $psJsonData
    out-file -InputObject $JsonData -FilePath C:\temp\jsonout.txt
    
    format-json -json $JsonData
}


#Remove below for Red 
$cid="2l83qes1eogie8g6noaejlvqtq"
$cse="1iin6lca6kd7ln0go8nvf5ftpodqi2f24311an27fbstohmuaiv1"
$ruri="https://127.0.0.1/"
$rtkn="eyJjdHkiOiJKV1QiLCJlbmMiOiJBMjU2R0NNIiwiYWxnIjoiUlNBLU9BRVAifQ.HWE29oRUNwtJfvWk_MKu43N9hGcRjNHizaOLiS2UFrRAshrdBBdgih8ji9FKK_xR9EwZ9kBV6eQHwWwC98TboU9XmDKADLQeSs9gBogxp9e_gK7TKKo5qxQayGJPjhaG9zVtlYTzI8mZ0LihZ18-ogcVh1r-iVJtdDJo0KIYIUlwIeVrRNP0mxI4RDfvj_2-Y4Ao-owf5dqKSV8tXyMx-xC8Wc5ynAAxbnRP80Q4pxj-asQYglsyPHSJ8j4KoV9yD1H75-jrePtitUG1EVFRQf5-1XUHJL4bHpuc2wzqPoraQAO84UK3PFYLg2SbvVTwYIhF2HTxhfIF78qq8kG5_g.GjRtRG0pGOWQcCNe.zb2yHlB0mETysceV5LJcdMD5cZelZ9lyonE3nZtYD2Km3PSxQoCyMWZhOjHEuypO0WLQnE8UY7N5Un3C2C11N38bMDErH-yaDwaEXO-ItdBFeb3knfrgq3bG86XDFruXukqyjk4OjuMCjndZdb9G4St4NdJGiF7Ei_7U3707pqAsji3HlRrrSRUwQihd7jixNYUwijbD-DORxSS4ZHZC-mlzFwbgfDoV2e3yNGkeGHzNrDppIdDfbfycPSbcndmGjkinoqnCcAFIqW3ePdbpb8jNezCzDQ6-Ub1ytN6MiKYS1cEKBA-yt65S9_8ssxLGlEGU2RRAfFROD21FAUsGG2HAKxmx9A-SMCc7AKO16bg685kQpXEeEyiclOR6W3_dZ7-3wSzIkd4_sNu_c08lKOK8HY0-qbySZYDQNzYSdUJCIjVYrLGg89EChLqxfN-awJSp6b9_6eYjaMXy0sUcXaI9Y6PaKV-BhfPxMAcidGeN-F9gAn0Z4Zxzpia_W6lmd5Taw5KiDQpBQHFjReaDP7uU0EKIdbM7qX6TKL03ZwivSrn-aX6XU8ra7fn_qaJAPLj4bb3p2czWyp1xtN5pDi2f3PgaS52wq4GayjN_TAEBD8omDU3fgOkKPKhsuk0FswenkLbxDWIdPF5VQinVWUyE4IS-HkvmQzUkirr0eXRxJjhrM5W_KIIXB0bSu2gd9wlLgctA3AYPTOmN7dYg_YI-j1qrKZcmoxbx8_YQVkH1gZ-W-G_p7p23zTWfb6zYbqMEwfRxrx0y7wGWgbHQYR8miZythbP999owoJsd9flN1bwd_8QFANPLI5FmlpBVsXJvl7ZALVg8HHgOGI8VNVyM3NO8RElcytTQagwnw-XpzE1bdTMSIShLoFwJa38n84sXOu0UXNhX3zWS4S7WhkG2Ek7-0u0skJ1DcR4JNZlHbDFuxTba1PEmKnoOhx6aEV-xvQ3597pGqWLxdwDMe45HaeW4QJv7SCVEYf9cq1nFZfPns38Dn1zN4CE4OnSfnztKCXp24jQS_snYSeX31mARI00j7QlhRyqAEr1XNl98p-k7d0GPdVrAsmn4efFAcnz5Vw-x0IbHH2oP67Uwt6PMKpEnCEs7HeNocuY1VL3FxRE6TtAZziVOFza-7auUD_11zsgQwEAZZ5cCojp_zRugcTQt9fml9Ru06XObSNEP9em16hNftY5Np9YDBKWzJ8cbSvvq8FS2p5nAYilMqGvHm3u9zg6cPXxY8iaJDSGFCiIhfP7IvpL3qvKXDqvF15aEL7bi.OAl9r087YCV9F_2HjtQhoA"
$duri = ""
$turi = "https://krtest.auth.ap-southeast-2.amazoncognito.com/oauth2/token"

#Comment below for local run, uncomment for Red
<#
$cid="$env:WSL_SRCCFG_ClientId"  
$cse="$env:WSL_SRCCFG_ClientSecret"
$turi="$env:WSL_SRCCFG_TokenUrl" 
$ruri="$env:WSL_SRCCFG_RdirUri"
$duri="$env:WSL_SRCCFG_storagepath"
$rtkn="$env:WSL_SRCCFG_RefreshToken"
#>


$data=""
$OutData=""
$loopcount=0
$accToken = ""
$logdata = ""
$templogfile=$env:TEMP+"\s3log.txt"
$tempoutfile=$env:Temp + "\s3browsout.txt"
$AccTokenFile=$env:Temp + "\s3Acctoken.dat"


<#
try
  {
      $accToken = Get-Content -Path $AccTokenFile -ErrorAction stop
      $logdata += "`n" + "Read token from disk"
  }
  catch
  {
     $accToken=""
  }
#>

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
   $loopcount++

<#
    $RetCode, $data = Get-GoogleStorageData -uri $duri -Token $AccToken

    if ( $RetCode -eq "200")
    {
         $outData = Format-DataToJson -data $data
    }
    else
    {
       $logdata += "`n"  + "Get-GoogleStorageData returned: " + $RetCode

       if ($RetCode -eq "Unauthorized" -and $loopcount -lt 2)
       {
           $logdata += "`n"  + "Setting to get a new access token"
           $AccToken=""
       }
    } 
#>
} until ( $RetCode -eq "200" -or  $loopcount -gt 1 )



If ( $RetCode -eq "200" )
   {
       Write-Output 1
       Write-Output $($OutData -replace "\r\n",'')
       Out-File -InputObject $OutData -FilePath $tempoutfile
       Out-File -InputObject $logdata -FilePath $templogfile
   }
else {
    write-output -2
    Write-output "Operation failed"
    write-output $logdata
}

