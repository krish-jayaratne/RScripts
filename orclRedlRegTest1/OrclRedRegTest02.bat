@echo off
REM *******************************************************************
REM    Description    :    Setup the Oracle environment (Create database, repo then loads app)
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    15 Jan 2015
Rem    Version		  :    1	
REM *******************************************************************
setlocal EnableDelayedExpansion
setlocal enableextensions

set debug=off
if %1a==a goto print_info
Rem Red application file for application load
set redApp=\\192.168.60.232\devShare\Share\Krish\Automation\Apps\app-orcl124t2-full\app_id_FullDWH_v1.wst

set DSN=
set DB=
set dbname=
set dsnName=
set drop=No
set schemas=
set installFolder=
set svrUser=
set msiName=
set redExe=



if not exist C:\Temp mkdir C:\Temp
set parameters=dbName schemas svrUser svrPW dsnName echoOnly installFolder drop redExe msiName installonly
set intParameters=buildNumber  buildPath m_buildPath

Rem get svrName and buildNumber first
set svrName=%1

Rem    Get build path and first take off quotation marks. Then remove spaces so that file name expansion 
Rem    can handle it, then create another without hyphen since SQL doesn't like dash.
Rem    process build path by removing spaces, dashes, dots  etc to create a simple valid installation path and dbname
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
goto error_info

:setPara
set %3=%4
Shift
Shift
goto ParsePara

:ParsePara_done
set cur_lable=ParsePara_done
if /i %debug%a==ona echo "AT: %cur_Lable%"

if not defined dbName set dbName=reg_%buildNumber%
if not %svrName% == %svrName:12=% set dbname=C##%dbname%

if not defined svrUser set svrUser=Red1
if not %svrName% == %svrName:12=% set svrUser=C##Red1

if not defined schemas set schemas=load/stage/fact
if not defined svrPW set svrPW=Wsl12345
if not defined usrPW set usrPW=Wsl12345

if not defined dsnName set dsnName=OR-%dbName%
if not defined msiName set msiName=red.msi
if not defined redExe set redExe=red.exe

if not defined db set db=yes
if not defined dsn set dsn=yes

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

echo call orclCreateDB.bat !svrName! %dbName% svrUser=%svrUser% svrPW=%svrPW% schemas=%schemas% usrpw=%usrPW% master=yes drop=%drop% dsn=%dsn% db=%db%
call orclCreateDB.bat !svrName! %dbName% svrUser=%svrUser% svrPW=%svrPW% schemas=%schemas% usrpw=%usrPW% master=yes drop=%drop% dsn=%dsn% db=%db%

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

Rem  Create shortcuts using PowerShell. Probably they should go to a folder in desktop instead desktop/
:CreateShourtcut
set cur_Lable=CreateShortcut
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts !buildNumber!}"
start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts !buildNumber!}"

if /i %installOnly%a==yesa goto installSched

Rem Create a Quick Repository. This does not load the defatul application
:CreateQRepo
set cur_Lable=CreateQRepo
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "ADM" /wait "!installFolder!\adm.exe" -QR -SN %dsnName% -SL %dbName% -SP %usrPW%
start "ADM" /wait "!installFolder!\adm.exe" -QR -SN %dsnName% -SL %dbName% -SP %usrPW% -DS Users -MS Users -IS Users

:createSetXML
set cur_Lable=createSetXML
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Construct the settings xml file. First 3 lines contain the credentials and DSN.
echo 	^<UserID^>%dbName%^</UserID^> > c:\temp\up1.txt
echo 	^<Password^>%usrPW%^</Password^> >> c:\temp\up1.txt
echo 	^<DSN^>%dsnName%^</DSN^> >> c:\temp\up1.txt 
copy .\WslAppLoadOptions.xmp1 + c:\temp\up1.txt + .\WslAppLoadOptions.xmp1 C:\temp\WslAppLoadOptions.xml

:loadDefApp
set cur_Lable=loadDefApp
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Load default application
echo "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_WSLT_base_1.wst" /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF "%installFolder%\Application\app_id_WSLT_base_1.wst" /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 

:installSched
echo Installing scheduler ....
echo "ADM" /wait "!installFolder!\adm.exe" -WS -ID %schedName% -IN W0%buildNumber:~2,4%%RANDOM:~0,1% -SN %dsnName% -SL %dbname% -SP %usrPW%
start "ADM" /wait "!installFolder!\adm.exe" -WS -ID %schedName% -IN W0%buildNumber:~2,4%%RANDOM:~0,1% -SN %dsnName% -SL %dbname% -SP %usrPW%
echo.
if /i %installOnly%a==yesa goto RunRed2

Rem Run Red and allow user to update repository
:runRed1
set cur_Lable=runRed1
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "med" /wait "!installFolder!\med.exe" -NEW /O %dsnName% /L %dbName%
start "med" /wait "!installFolder!\med.exe" -NEW /O %dsnName% /L %dbName%
Pause "Create schemas in Red"

Rem Load Red application
:loadTestApp
set cur_Lable=loadTestAppApp
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
start "ADM" /wait "!installFolder!\adm.exe" /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 


:RunRed2
echo start "Med" "!installFolder!\med.exe" /O %dsnName% /U %dbName%
start "Red" "!installFolder!\med.exe" /O %dsnName% /U %dbName%


goto end_Reg_setup

Rem print Environment
:printEnv
set cur_Lable=printEnv
if /i %debug%a==ona echo "AT: %cur_Lable%"

@echo svrName=%svrName%
@echo bildNumber=%buildNumber%
@echo dbName=%dbname%
@echo schemas=%schemas%
@echo svrUser=%svrUser%
@echo svrPW=%svrPW%
@echo dsnName=%dsnName%
@echo.
@echo buildNumber=%buildNumber%
@echo installFolder=%installFolder%
@echo buildPath=%buildPath%
@echo m_buildPath=%m_buildPath%

goto end_Reg_setup

:print_info
echo.
echo Usage:
echo %0 TNSName Pathto_msi
echo Creates a Red Repo in 'TNSName' 
echo Parameters 
echo     SvrUser=admin user        (default Red1)
echo     SvrPW=Password            (default Wsl12345)
echo     usrPW=passward for schema (default Wsl12345)
echo     dbname=master schema      (default reg_buildnumber)
echo     Schemas=sc1/sc2/../sc5.   (deafult load/stage/fact)
echo     dsnName=DsnName           (default ORCL-reg_{buildNumber})
echo     installFolder={folder}    (default build-{buildNumber} )
echo     msiName=name of msi file  (default red.msi)
echo.
echo ***********  IMPORTANT ************
echo It expects a folder program files\Wherescape /"Program files (x86)\Wherescape" 
echo to be present. 
echo.
echo msi file should be in a sub folder ddmmyy-hhmmss, which use to generate the
echo dbname. For example X:\builds\150109-200303\red.msi

:end_Reg_setup

EndLocal
