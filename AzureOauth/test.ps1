    

$loadinfo = 
@"
{
    "fileLoaderOptions":"TABLOCK",
    "fileParsed":true,
    "sourceFile":{
    	"headerLine":true,
		"name":"",
		"nonStringNullEncoding":"",
		"nullEncoding":"",
		"path":"mypath",
		"recordDelimiter":""
	}
 }
"@

   $po = @()

   for  ( $i=0; $i -le 3; $i++)
   {
        $c = convertFrom-json $loadinfo
        $po += $c
        $po[$i].sourceFile.name = $i
   }

   foreach ($a in $po)
   {
     $a   | select-object
   }