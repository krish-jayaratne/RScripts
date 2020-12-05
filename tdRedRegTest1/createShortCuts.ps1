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
    $SCFile = [environment]::getfolderpath("Desktop")+"\"+$pgm+"-"+$program_folder.substring($program_folder.lastIndexOf("\")+1)+".lnk"
	$SCsource = $program_folder +"\"+$pgm+".exe"
	New-Shortcut $SCSource $SCFile ""
  }

  if ($args.Length -eq 4)                      
  {
     $dsnname = $args[1]
	 $repouser = $args[2]
	 $repoName = $args[3]
	 
     $SCFile = [environment]::getfolderpath("Desktop")+"\TD-Red-" + $build+$program_folder.substring($program_folder.lastIndexOf("\")+1)+".lnk"
	 $SCsource = $program_folder +"\med.exe"
	 $Arguments =  "-NEW " + " /L " + $repouser + " /D  " + $repoName + " /O " + $dsnname
	 New-Shortcut $SCSource $SCFile $Arguments
  }
   
}