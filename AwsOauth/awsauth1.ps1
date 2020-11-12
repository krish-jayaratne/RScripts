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
        $resp = Invoke-WebRequest -uri https://oauth2.googleapis.com/token -Method Post -Body $param

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
$cid="687147849267-reoeac2tpgromo7kvif4mc0u5ps3p5k1.apps.googleusercontent.com"
$cse="fwHh0r7R1ozkv9F97Mo_YR7A&"
$ruri="https://127.0.0.1"
$rtkn="1//0g0hP-aL84l8kCgYIARAAGBASNwF-L9Iry55vb8-tESVJZMHs-c0nAW5-PlphaU-0s6KFGlbFnZUnPkaJSGe7pH2m9xJ08KuPumU"
$duri = "https://storage.googleapis.com/storage/v1/b/krishtestbucket1/o"
$turi = "https://oauth2.googleapis.com/token"

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
$templogfile=$env:TEMP+"\googlebrowslog.txt"
$tempoutfile=$env:Temp + "\googlebrowsout.txt"
$AccTokenFile=$env:Temp + "\GoogleAcctoken.dat"


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

    $RetCode, $data = Get-GoogleStorageData -uri $duri -Token $AccToken
    $loopcount++

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
