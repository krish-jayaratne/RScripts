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
        Write-Host "Exception at Get-GoogleStorageData"
        $_.Exception.Response.statuscode
    }
}

Function Show-Data{
    
    param ( $data ) 


    $loadinfo = [pscustomobject]@{
		"fileLoaderOptions"= "TABLOCK";
		"fileParsed"= $true;
		"overrideLoadSQL"= "";
		"overrideSourceColumns"= "";
		"selectDistinctValues"= $false;
		"sourceFile"= [pscustomobject]@{
				"charSet"= "";
				"escapeEncoding"= "";
				"fieldDelimiter"= "|";
				"fieldEnclosure"= "\";
				"headerLine"= $true;
				"name"= "$file";
				"nonStringNullEncoding"= "";
				"nullEncoding"= "";
				"path"= "mypath";
				"recordDelimiter"= ""
			};
		"sourceSchema"= "sourceSchema";
		"sourceTables"= "myfile";
		"useOverrideSourceColumns"= $false;
		"whereAndGroupByClauses"= ""
	};

    $psdataPref =[pscustomobject]@{	"treeViewLayout"="List"; "treeViewIcons"=@{"schema"= "database.ico"; "table"="table.ico"}}
	$bucket = $data.Item(1).bucket
    $psdata = @()
    
    foreach ($d in $data)
    {
       $psdata =  add-member -InputObject $psdata -NotePropertyMembers @{$d.name = @{"name"=$d.name; "description" = $d.description; "rowcount"=$d.size; "loadinfo"=$loadinfo } } -PassThru
    }

    $psJsonData =  add-member -inputObject $psdataPref  -notePropertyMembers @{$bucket=$psdata } -PassThru


    convertto-json -Depth 5 -inputobject ( $psJsonData  ) 


}



$cid="687147849267-reoeac2tpgromo7kvif4mc0u5ps3p5k1.apps.googleusercontent.com"
$cse="fwHh0r7R1ozkv9F97Mo_YR7A&"
$ruri="https://127.0.0.1"
$rtkn="1//0g0hP-aL84l8kCgYIARAAGBASNwF-L9Iry55vb8-tESVJZMHs-c0nAW5-PlphaU-0s6KFGlbFnZUnPkaJSGe7pH2m9xJ08KuPumU"
$duri = "https://storage.googleapis.com/storage/v1/b/krishtestbucket1/o"



$data=""
$loopcount=0
Do
{

    if ($accToken.length -eq 0 )
    {
        $AccToken=Get-AccessToken -clent_id $cid -clent_secret $cse -redirct_uri $ruri -refresh_token $rtkn
    }

    $RetCode, $data = Get-GoogleStorageData -uri $duri -Token $AccToken
    $loopcount++

    if ( $RetCode -eq "200")
    {
         Show-Data -data $data
    }
    else
    {
       write-host "failed to access data, return code:" $RetCode

       if ($RetCode -eq "Unauthorized" -and $loopcount -lt 2)
       {
           write-host "Setting to get a new access token"
           $AccToken=""
       }
    } 
} until ( $RetCode -eq "200" -or  $loopcount -gt 1 )

