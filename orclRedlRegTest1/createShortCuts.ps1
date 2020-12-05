function New-Shortcut($TargetPath, $ShortcutPath) {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Save()
}

function createShortcuts()
{

  $program_folder = $args[0]

  $pgms="med","adm","dba"

  foreach ($pgm in $pgms) 
  {
	$SCFile = [environment]::getfolderpath("Desktop")+"\"+$pgm+"-"+$program_folder.substring($program_folder.lastIndexOf("\")+1)+".lnk"
	$SCsource = $program_folder +"\"+$pgm+".exe"
	New-Shortcut $SCSource $SCFile
  }
}