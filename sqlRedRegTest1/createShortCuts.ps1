function New-Shortcut($TargetPath, $ShortcutPath, $Arguments) {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Arguments = $Arguments
    $Shortcut.Save()
}

function createShortcuts()
{

  $program_folder = $args[0]
  $pgms="med","adm","dba"

  foreach ($pgm in $pgms) 
  {
	$SCFile = $env:Public +"\Desktop\"+$pgm+"-"+$program_folder.substring($program_folder.lastIndexOf("\")+1)+".lnk"
	$SCsource = $program_folder +"\"+$pgm+".exe"
        $Arguments = ""
	New-Shortcut $SCSource $SCFile $Arguments
  }
  
  $dsnname = $args[1]
  $repouser = $args[2]
 
	 
  $SCFile = $env:Public +"\Desktop\Cur-Red-" + $program_folder.substring($program_folder.lastIndexOf("\")+1)+".lnk"
  $SCsource = $program_folder +"\med.exe"
  $Arguments =  "-NEW " + " /L " + $repouser + " /O " + $dsnname + " -a 64"
  New-Shortcut $SCSource $SCFile $Arguments
}