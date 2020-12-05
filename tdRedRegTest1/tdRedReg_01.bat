REM *******************************************************************
REM    Description    :    Setup the Teradata environment (Create database, repo then loads app)
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    10  March 2015
Rem    Version		  :    1.0
Rem    Updates
Rem    17 Mar 2015    : Updated Powershell to create a shortcut pointing to the TD schema. Updated PS script to
Rem                     Read the DSNName as second argument
REM *******************************************************************

@echo off
setlocal EnableDelayedExpansion
setlocal enableextensions

if %1a==a goto print_info

Rem Red application file for application load
set redApp=\\192.168.60.232\devShare\Share\Krish\Automation\Apps\app-td-train1\app_id_td-training_1.wst

set debug=on
set DSN=
set DB=
set dbname=
set dsnName=
set drop=
set schemas=
set installFolder=
set svrUser=
set msiName=
  

Rem    Get build path and first take off quotation marks. Then remove spaces so that file name expansion 
Rem    can handle it, then create another without hyphen since SQL doesn't like it.
set parameters=dbName schemas svrUser svrPW dsnName echoOnly installFolder drop usrPW msiName
set intParameters=buildNumber  buildPath m_buildPath

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
if defined  debug echo "AT: %cur_Lable%"
if %3a EQU a goto ParsePara_done
echo %parameters% | find /i "%3" >nul
IF %ERRORLEVEL%==0 goto setPara
echo Unknown Parameter: %3
echo Supported parameters:  %parameters%
goto error_info

:setPara
set %3=%4
Shift
Shift
goto ParsePara

:ParsePara_done
set cur_lable=ParsePara_done
if defined  debug echo "AT: %cur_Lable%"

if not defined dbName set dbName=reg_%buildNumber%
if not defined schemas set schemas=load/stage/fact
if not defined svrUser set svrUser=dbc
if not defined svrPW set svrPW=dbc
if not defined dsnName set dsnName=TD-%dbName%
if not defined usrPW set usrPW=Wsl12345
if not defined msiName set msiName=red.msi

Rem Derive install folder
if not defined installFolder set installFolder=build-!buildNumber!
if /i %PROCESSOR_ARCHITECTURE% EQU AMD64 (
  set installFolder="C:\program files (x86)\Wherescape\%installFolder%"
  ) ELSE (
  set installFolder="C:\program files\Wherescape\%installFolder%"
)
set installFolder=%installFolder:"=%

if /i %EchoOnly%a==Yesa goto printEnv

Rem Create database
:create_Database
set cur_Lable=create_Database
if defined  debug echo "AT: %cur_Lable%"

call tdCreateDB !svrName! %dbName% schemas=%schemas% dsnName=%dsnName% usrPW=%usrPW% drop=!drop!

Rem Install Red
:installRed
set cur_Lable=installRed
if defined  debug echo "AT: %cur_Lable%"

echo start /wait msiexec /qr /i "%buildPath%\!msiName!" APPDIR="!installFolder!"
start /wait msiexec /qr /i "%buildPath%\!msiName!" APPDIR="!installFolder!"

Rem  Create shortcuts using PowerShell. Probably they should go to a folder in desktop instead desktop/
:CreateShourtcut
set cur_Lable=CreateShortcut
if defined  debug echo "AT: %cur_Lable%"
echo start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts !buildNumber! !dsnName!}"
start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts !buildNumber! !dsnName!}"


Rem Create a Quick Repository. This does not load the defatul application
:CreateQRepo
set cur_Lable=CreateQRepo
if defined  debug echo "AT: %cur_Lable%"
echo start "ADM" /wait "!installFolder!\adm.exe" -QR -SN %dsnName% -SL %dbName% -SP %usrPW% -DI !svrName! -MS %dbName%
start "ADM" /wait "!installFolder!\adm.exe" -QR -SN %dsnName% -SL %dbName% -SP %usrPW% -DI !svrName! -MS %dbName%

:createSetXML
set cur_Lable=createSetXML
if defined  debug echo "AT: %cur_Lable%"
Rem Construct the settings xml file. First 3 lines contain the credentials and DSN.
echo 	^<UserID^>!dbname!^</UserID^> > c:\temp\up1.txt
echo 	^<Password^>%usrPW%^</Password^> >> c:\temp\up1.txt
echo 	^<DSN^>%dsnName%^</DSN^> >> c:\temp\up1.txt
echo    ^<Teradata_Metadata_Database^>!dbname!^</Teradata_Metadata_Database^> >> c:\temp\up1.txt
copy .\WslAppLoadOptions.xmp1 + c:\temp\up1.txt + .\WslAppLoadOptions.xmp2 C:\temp\WslAppLoadOptions.xml

:loadDefApp
set cur_Lable=loadDefApp
if defined  debug echo "AT: %cur_Lable%"
Rem Load default application
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_TERT_base_1.wst" /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml -DI !svrName! 

Rem Run Red and allow user to update repository
:runRed1
set cur_Lable=runRed1
if defined  debug echo "AT: %cur_Lable%"
echo start "ADM" /wait "!installFolder!\med.exe" -NEW /O %dsnName% /D %dbName%
start "Red" /wait "!installFolder!\med.exe" -NEW /O %dsnName% /D %dbName% /L %dbName%
Pause "Create schemas in Red"

Rem Load Red application
:loadTestApp
set cur_Lable=loadTestAppApp
if defined  debug echo "AT: %cur_Lable%"
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 

start "Red" /wait "!installFolder!\med.exe" /O %dsnName% /D %dbName% /L %dbName%


goto end_Reg_setup

Rem print Environment
:printEnv
set cur_Lable=printEnv
if defined  debug echo "AT: %cur_Lable%"
@echo.
@echo svrName=%svrName%
@echo dbName=%dbname%
@echo dsnName=%dsnName%
@echo bildNumber=%buildNumber%
@echo schemas=%schemas&
@echo svrUser=%svrUser%
@echo usrPW=%usrPW%
@echo svrPW=%svrPW%
@echo.
@echo buildNumber=%buildNumber%
@echo installFolder=%installFolder%
@echo buildPath=%buildPath%
@echo m_buildPath=%m_buildPath%

goto end_Reg_setup

:print_info
echo.
echo Usage:
echo %0 Svr Pathto_build dsnName={Teradata DSN Name}
echo Creates a Red Repo in 'Svr' 
echo   Defaults
echo     svrUser        dbc
echo     svrPW:         dbc
echo     usrPW:         Wsl12345
echo     dbname:        reg_buildnumber		  
echo     schemas:       load/stage/fact
echo     InstallFolder  {programFolder}\Wherescap\build-{buildNumber}
echo     msiName        red.msi
echo     EchoOnly:      No
echo.
:end_Reg_setup
