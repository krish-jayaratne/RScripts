@echo off
REM *******************************************************************
REM    Description    :    Setup the Teradata environment (Create database, repo then loads app)
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    10  March 2015
Rem    Version		  :    1.0
Rem    Updates
Rem    17 Mar 2015    : Updated Powershell to create a shortcut pointing to the TD schema. Updated PS script to
Rem                     Read the DSNName as second argument
REM *******************************************************************

setlocal EnableDelayedExpansion
setlocal enableextensions

if %1a==a goto print_info

Rem Red application file for application  
set redApp=\\192.168.60.232\devShare\Share\Krish\Automation\Apps\app-td-train1\app_id_td-training_1.wst

set debug=off
set DSN=
set DB=
set dbname=
set dsnName=
set drop=
set schemas=
set installFolder=
set svrUser=
set msiName=
if not exist C:\Temp mkdir C:\Temp
 
Rem    Get build path and first take off quotation marks. Then remove spaces so that file name expansion 
Rem    can handle it, then create another without hyphen since SQL doesn't like it.
set parameters=dbName schemas svrUser svrPW dsnName echoOnly repoUser reponame installFolder buildNumber drop msiName redExe installOnly usrPW
set intParameters=buildPath m_buildPath

Rem get svrName and buildNumber first
set svrName=%1

set buildPath=%2
set buildPath=%buildPath:"=%
set m_buildPath=%buildPath: =_%
for /F %%f in ("%m_buildPath%") do set buildNumber=%%~nxf
set buildNumber=%buildNumber:-=_%
set buildNumber=%buildNumber:.=_%

Rem Then parse the rest

:ParsePara
set cur_lable=ParsePara
if /i %debug%a==ona echo "AT: %cur_Lable%"
if %3a EQU a goto ParsePara_done
echo %parameters% | find /i "%3" >nul
IF %ERRORLEVEL%==0 goto setPara
echo Unknown Parameter: %3
echo Supported parameters:  %parameters%
goto print_info

:setPara
set %3=%4
Shift
Shift
goto ParsePara

:ParsePara_done
set cur_lable=ParsePara_done
if /i %debug%a==ona echo "AT: %cur_Lable%"


if not defined db set db=Yes
set dsn=no
if not defined dbName set dbName=reg_%buildNumber%
if not defined schemas set schemas=load/stage/fact
if not defined svrUser set svrUser=dbc
if not defined svrPW set svrPW=dbc
if not defined dsnName set dsnName=TD-%dbName%
if not defined repoUser set repouser=%dbname%
if not defined repoName set reponame=%dbname%
if not defined usrPW set usrPW=Wsl12345
if not defined msiName set msiName=red.msi
if not defined redExe set redExe=red.exe
if /i %installOnly%a==Yesa (
   set db=no
   set dsn=no
)

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

Rem Create database
:create_Database
set cur_Lable=create_Database
if /i %debug%a==ona echo "AT: %cur_Lable%"

echo call tdCreateDB_2 !svrName! %dbName% schemas=%schemas% dsnName=%dsnName% usrPW=%usrPW% dsn=!dsn! db=!db! drop=!drop!
call tdCreateDB_2 !svrName! %dbName% schemas=%schemas% dsnName=%dsnName% usrPW=%usrPW% dsn=!dsn! db=!db! drop=!drop!

Rem Install Red
:installRed
set cur_Lable=installRed
if /i %debug%a==ona echo "AT: %cur_Lable%"
if not exist "%buildPath%\!redExe!" goto useMSI

echo start /wait "install" "%buildPath%\!redExe!" /qr APPDIR="!installFolder!"
start /wait "install" "%buildPath%\!redExe!" /qr APPDIR="!installFolder!"
goto endInstall

:useMSI
echo start /wait msiexec /qr /i "%buildPath%\!msiName!" APPDIR="!installFolder!"
start /wait msiexec /qr /i "%buildPath%\!msiName!" APPDIR="!installFolder!"

:endInstall
Rem  Create shortcuts using PowerShell. Probably they should go to a folder in desktop instead desktop

:CreateShourtcut
set cur_Lable=CreateShortcut
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts !buildNumber! !dsnName! !dbname!}"
start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts !buildNumber! !dsnName! !repoUser! !repoName!}"

if /i %installOnly%a==yesa goto installSched

Rem Create a Quick Repository. This does not load the defatul application
:CreateQRepo
set cur_Lable=CreateQRepo
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "ADM" /wait "!installFolder!\adm.exe" -QR -SN %dsnName% -SL %repoUser% -SP %usrPW% -DI !svrName! -MS %repoName%
start "ADM" /wait "!installFolder!\adm.exe" -QR -SN %dsnName% -SL %repoUser% -SP %usrPW% -DI !svrName! -MS %repoName%

:createSetXML
set cur_Lable=createSetXML
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Construct the settings xml file. First 3 lines contain the credentials and DSN.
echo 	^<UserID^>!repoUser!^</UserID^> > c:\temp\up1.txt
echo 	^<Password^>%usrPW%^</Password^> >> c:\temp\up1.txt
echo 	^<DSN^>%dsnName%^</DSN^> >> c:\temp\up1.txt
echo    ^<Teradata_Metadata_Database^>!repoName!^</Teradata_Metadata_Database^> >> c:\temp\up1.txt
copy .\WslAppLoadOptions.xmp1 + c:\temp\up1.txt + .\WslAppLoadOptions.xmp2 C:\temp\WslAppLoadOptions.xml

Echo About to load default app and install scheduler
echo Option XML file created in C:\Temp
pause

:loadDefApp
set cur_Lable=loadDefApp
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Load default application
echo start "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_TERT_base_1.wst" /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml -DI !svrName! 
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_TERT_base_1.wst" /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml -DI !svrName! 

:installSched
echo Installing scheduler ....
echo "ADM" /wait "!installFolder!\adm.exe" -WS -ID %schedName% -IN W0%buildNumber:~2,4%%RANDOM:~0,1% -SN %dsnName% -SL %repoUser% -SP %usrPW% -MS %repoName%
start "ADM" /wait "!installFolder!\adm.exe" -WS -ID %schedName% -IN W0%buildNumber:~2,4%%RANDOM:~0,1% -SN %dsnName% -SL %repoUser% -SP %usrPW% -MS %repoName%
echo.
if /i %installOnly%a==yesa goto runRed2

Rem Run Red and allow user to update repository
:runRed1
set cur_Lable=runRed1
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "RED" /wait "!installFolder!\med.exe" -NEW /O %dsnName% /D %repoName% /L %repoUser%
start "Red" /wait "!installFolder!\med.exe" -NEW /O %dsnName% /D %repoName% /L %repoUser%
Pause "Create schemas in Red"

Rem Load Red application
:loadTestApp
set cur_Lable=loadTestAppApp
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo  "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 

:runRed2
echo "Red" /wait "!installFolder!\med.exe" /O %dsnName% /D %repoName% /L %repoUser%
start "Red" /wait "!installFolder!\med.exe" /O %dsnName% /D %repoName% /L %repoUser%


goto end_Reg_setup

Rem print Environment
:printEnv
set cur_Lable=printEnv
if /i %debug%a==ona echo "AT: %cur_Lable%"
@echo.
@echo svrName=%svrName%
@echo dbName=%dbname%
@echo dsnName=%dsnName%
@echo bildNumber=%buildNumber%
@echo schemas=%schemas%
@echo svrUser=%svrUser%
@echo repoUser=%repoUser%
@echo repoName=%repoName%
@echo usrPW=%usrPW%
@echo svrPW=%svrPW%
@echo.
@echo buildNumber=%buildNumber%
@echo installFolder=%installFolder%
@echo buildPath=%buildPath%
@echo m_buildPath=%m_buildPath%
@echo schedname%schedName%
@echo randomname=W0%buildNumber:~2,4%%RANDOM:~0,1%

goto end_Reg_setup

:print_info
echo.
echo Usage:
echo %0 Svr Pathto_build dsnName={Teradata DSN Name}
echo Creates a Red Repo in 'Svr' 
echo   Defaults
echo     dbname         reg_buildnumber		  
echo     svrUser        dbc
echo     svrPW          dbc
echo     usrName        ^<dbname^>
echo     usrPW          Wsl12345
echo     repoName       ^<dbname^>
echo     schemas        load/stage/fact
echo     InstallFolder  {programFolder}\Wherescap\build-{buildNumber}
echo     msiName        red.msi
echo     redExe         red.exe
echo     db             Yes
echo     installonly    No
echo     echoonly       No 
echo.
:end_Reg_setup
