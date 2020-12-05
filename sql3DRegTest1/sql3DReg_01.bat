@echo off
REM *******************************************************************
REM    Description    :    Setup 3D and use a pre-created repository
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    15 Jan 2015
Rem    Version		  :    1	
Rem    updated 	      :    28 Sep 2016 
REM *******************************************************************

setlocal EnableDelayedExpansion
setlocal enableextensions

set debug=off

Rem Red application file for application load
set AppPath=\\192.168.60.232\devShare\Share\Krish\TestData\Apps\
set repoSrcPath=\\192.168.60.232\devShare\Share\Krish\TestData\3D\
set repoPath=C:\data\3dRepos\
set repoZipFile=Regression_3D_GP_1.zip
set repoIni=ws_repo_locations.xml


if %1a==a goto print_info

set DSN=
set DB=
set dbname=
set dsnName=
set drop=No
set schemas=
set installFolder=
set svrUser=
set msiName=
set ThreeDEXE=WhereScapeSuiteInstaller_8310.exe
set appNo=

if not exist C:\Temp mkdir C:\Temp

Rem Save the command line
if not exist C:\data mkdir C:\data
if not exist C:\data\3d mkdir C:\data\3d
if not %3a==a  echo %date%:  %0 %* >> c:\data\RedAutomationLog.txt

set parameters=echoOnly installFolder buildNumber installOnly repoSrcPath repoName winUser 
set intParameters=buildPath m_buildPath

Rem get svrName and buildNumber first	

Rem    Get build path and first take off quotation marks. Then remove spaces so that file name expansion 
Rem    can handle it, then create another without hyphen since SQL doesn't like it.
Rem    process build path by removing spaces, dashes, dots  etc to create a simple valid installation path and dbname
set buildPath=%1
set buildPath=%buildPath:"=%
set m_buildPath=%buildPath: =_%
for /F %%f in ("%m_buildPath%") do set buildNumber=%%~nxf
for /F  "tokens=* USEBACKQ" %%f in (`dir /b "%buildPath%\3d*.exe"`) do (
 set ThreeDEXE=%%f
)
set buildNumber=%buildNumber:-=_%
set buildNumber=%buildNumber:.=_%

Rem Then parse the rest

:ParsePara
set cur_lable=ParsePara
if /i %debug%a==ona echo "AT: %cur_Lable%"
if %2a EQU a goto ParsePara_done
echo %parameters% | find /i "%2" >nul
IF %ERRORLEVEL%==0 goto setPara
echo Unknown Parameter: %2
echo Supported parameters:  %parameters%
goto print_info

:setPara
set %2=%3
Shift
Shift
goto ParsePara

:ParsePara_done
set cur_lable=ParsePara_done
if /i %debug%a==ona echo "AT: %cur_Lable%"


Rem Assign Application - This is not used yet, leaving for future use
set Repo3D=%AppPath%!repoName%appNo%!

Rem Derive install folder
if not defined installFolder set installFolder=build-!buildNumber!
if /i %PROCESSOR_ARCHITECTURE% EQU AMD64 (
  set installFolder="C:\program files (x86)\Wherescape\%installFolder%"
  ) ELSE (
  set installFolder="C:\program files\Wherescape\%installFolder%"
)
set installFolder=%installFolder:"=%
set schedName=%dbName%_%buildNumber:~2,4%

if /i %EchoOnly%a==Yesa goto printEnv


Rem Install 3D
:install3D
set cur_Lable=install3D
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "install"  /wait "%buildPath%\%ThreeDEXE%" /qr
start  "install" /wait "%buildPath%\%ThreeDEXE%" /qr


goto endInstall

:endInstall


Rem Copy the repo to the location
:CopyRepo
set cur_Lable=CreateQRepo
if exist %repoPath% rmdir  /s %repopath%
mkdir %repoPath%
echo unzip %repoSrcpath%%RepoZipFile% -d %repoPath%
unzip %repoSrcpath%%RepoZipFile% -d %repoPath%

:CopyIni
echo copy %repoSrcpath%%repoIni% %USERPROFILE%\WhereScape\3D
copy %repoSrcpath%%repoIni% %USERPROFILE%\WhereScape\3D

goto end_Reg_setup

:createSetXML
set cur_Lable=createSetXML
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Construct the settings xml file. First 3 lines contain the credentials and DSN.
echo 	^<UserID^>%svrUser%^</UserID^> > c:\temp\up1.txt
echo 	^<Password^>%svrPW%^</Password^> >> c:\temp\up1.txt
echo 	^<DSN^>%dsnName%^</DSN^> >> c:\temp\up1.txt
copy .\WslAppLoadOptions.xmp1 + c:\temp\up1.txt + .\WslAppLoadOptions.xmp1 C:\temp\WslAppLoadOptions.xml

:loadDefApp
set cur_Lable=loadDefApp
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Load default application
echo "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_SQLT_base_1.wst" /LF c:\temp\%buildNumber%base.log /PF C:\temp\WslAppLoadOptions.xml
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_SQLT_base_1.wst" /LF c:\temp\%buildNumber%base.log /PF C:\temp\WslAppLoadOptions.xml

:loadTemplateApp
echo "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_SQLT_templates.wst" /LF c:\temp\%buildNumber%template.log /PF C:\temp\WslAppLoadOptions.xml
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_SQLT_templates.wst" /LF c:\temp\%buildNumber%template.log /PF C:\temp\WslAppLoadOptions.xml

:installSched
if Sched==No goto run_red1
echo Installing scheduler ....
echo "ADM" /wait "!installFolder!\adm.exe" -WS -ID %schedName% -IN W0%buildNumber:~2,4%%RANDOM:~0,1% -SN %dsnName% -SL %svrUser% -SP %SvrPW%
start "ADM" /wait "!installFolder!\adm.exe" -WS -ID %schedName% -IN W0%buildNumber:~2,4%%RANDOM:~0,1% -SN %dsnName% -SL %svrUser% -SP %SvrPW%
echo. 
if /i %installOnly%a==yesa goto runRed2

Rem Run Red and allow user to update repository
:runRed1
set cur_Lable=runRed1
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo  "RED" "!installFolder!\med.exe" -NEW /O %dsnName% /L !svrUser!
start "RED" "!installFolder!\med.exe" -NEW /O %dsnName% /L !svrUser!


Rem Load Red application
:loadTestApp
set cur_Lable=loadTestAppApp
if /i %debug%a==ona echo "AT: %cur_Lable%"


Rem Check if application load is not required
if %AppNo%==0 goto EndOperations
echo.
echo  Create schemas in Red, or change any setups. Then Press Any Key
echo  Close and Open or Refresh Red then
pause > nul

echo start "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
:runRed2
echo "RED" "!installFolder!\med.exe" /O %dsnName% /L !svrUser!
start "RED" "!installFolder!\med.exe" /O %dsnName% /L !svrUser!



:EndOperations
echo.
echo ********************  Installation Complete   ***********************
echo.
echo.


goto end_Reg_setup

Rem print Environment
:printEnv
set cur_Lable=printEnv
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo.
@echo svrName         %svrName%
@echo buildNumber     %buildNumber%
@echo db              %db%
@echo dbName          %dbname%
@echo schemas         %schemas%
@echo svrUser         %svrUser%
@echo svrPW           %svrPW%
@echo dsn             %dsn%
@echo dsnName         %dsnName%
@echo InstallOnly     %installonly%
@echo echoonly        %echoonly%
@echo buildNumber     %buildNumber%
@echo. 
@echo installFolder   %installFolder%
@echo buildPath       %buildPath%
@echo schedName       %schedName%
@echo m_buildPath     %m_buildPath%
@echo W0%buildNumber:~2,4%%RANDOM:~0,1%

echo.

set

goto end_Reg_setup

:print_info
echo.
echo Usage:
echo %0 Pathto_build
echo Installs 3D
echo   Defaults
echo     repoSrcPath  \\192.168.60.232\devShare\Share\Krish\TestData\3D\
echo     repoName     
echo.
echo.
echo Apps:
echo.
for %%a in (1 2 3 4) do echo %%a. !RedApp%%a!
echo.


:end_Reg_setup


