function Get-AuthToken {
    param (
        $user_name, $password, $auth_uri, $scope, $client_id
    )

    $param = @"
client_id=$client_id&
scope=$scope&
username=$user_name&
password=$password&
grant_type=password&
client_secret=lgQ2CvkEi4KAB0Z_s5J9wKOkc8gF__C-8A
"@
    $param = $param -replace("\r\n","")
    Write-Host $param


        $resp = Invoke-WebRequest -uri $auth_uri -Method Post -Body $param
        write-host $resp

        $jresp = ConvertFrom-Json -InputObject $resp

         $resp.StatusCode, $jresp
         write-host $jresp


    <#
client_id=6731de76-14a6-49ae-97bc-6eba6914391e
&scope=user.read%20openid%20profile%20offline_access
&username=MyUsername@myTenant.com
&password=SuperS3cret
&grant_type=password
    #>

}

$p="K@n7h0ruw%"
$u="krish.mpn@r2cc.com"
$url="https://login.microsoftonline.com/02a27947-ac14-4683-b109-a71ecf6474c2/oauth2/v2.0/token"
$scope="https://database.windows.net/.default offline_access"
$c="b6680082-a981-4639-89dc-8574b5df1aa7"

$s, $j = Get-AuthToken -user_name $u -password $p -auth_uri $url -scope $scope -client_id $c
$s
convertto-json $j


