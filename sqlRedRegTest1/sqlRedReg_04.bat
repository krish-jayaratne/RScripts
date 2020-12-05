@echo off
REM *******************************************************************
REM    Description    :    Setup the SQL environment (Create database, repo then loads app)
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    15 Jan 2015
Rem    Version		  :    1	
Rem    updated 	      :    12 Jul 2017 
Rem
REM 				  : Changed command line to 
REM *******************************************************************

setlocal EnableDelayedExpansion
setlocal enableextensions

set debug=off

Rem Red application file for application load
set AppPath=\\192.168.60.232\devShare\Share\Krish\TestData\Apps\

set parameters=dbName schemas svrUser svrPW dsnName installFolder buildNumber drop msiName redExe usrPW appNo Trusted OdbcDrv buildBranch echoOnly installOnly svrName buildPath arch ODBCDrvName AppName

set RedApp0=
set RedApp1=app_sql_train_test_v7\app_id_sql_train_03_v7.wst
set RedApp2=app_sql_schedTest_1_v10\app_id_sqlsched_v10.wst
set RedApp3=app_sql_schedTest_1_schema_v10\app_id_sql_sc_schem_v10.wst
set RedApp4=app_sql_sched_sV17\app_id_sql_sched_s_v17.wst
set RedApp5=app_sql_sql_hive_cus_gp_v19\app_id_sql_all_hgcs_v19.wst
set RedApp6=app_sql_sched_v19\app_id_sql_sched_v19.wst
set RedApp7=3DApps\RED_RedModel-DV-Tutorial_from_2.10.0.0.xml
set RedApp8=app_full_170530CL_all\app_id_app_all_tgt_v1.wst
set RedApp9=sqlS17_190711RCLI_all\app_id_sql_sch_v1.wst

set appNo=2

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
set appNo=
set buildBranch=
set svrName=
set buildPath=
set paraError=0
set arch=bit64

if not exist C:\Temp mkdir C:\Temp

if %1a==a goto print_info

set intParameters=m_buildPath 

Rem    Get build path and first take off quotation marks. Then remove spaces so that file name expansion 
Rem    can handle it, then create another without hyphen since SQL doesn't like it.
Rem    process build path by removing spaces, dashes, dots  etc to create a simple valid installation path and dbname

Rem Then parse the rest

Rem Save the command line
if not exist C:\data mkdir C:\data
echo %date% %time%:  %0 %* >> c:\data\RedAutomationLog.txt

:ParsePara
set cur_lable=ParsePara
if /i %debug%a==ona echo "AT: %cur_Lable%"
if %1a EQU a goto ParsePara_done
echo %parameters% | find /i "%1" >nul
IF %ERRORLEVEL%==0 goto setPara
set paraError=1
goto print_info

:setPara
set %1=%2
Shift
Shift
goto ParsePara

:ParsePara_done
if a%buildPath%==a set paraError=2
if a%svrName%==a set paraError=3
if not %paraError%==0 goto print_info

:ProcessPara


set buildPath=%buildPath:"=%
set m_buildPath=%buildPath: =_%
for /F %%f in ("%m_buildPath%") do set buildNumber=%%~nxf
set buildNumber=%buildNumber:-=_%
set buildNumber=%buildNumber:.=_%


set cur_lable=ParsePara_done
if /i %debug%a==ona echo "AT: %cur_Lable%"

if not defined dbName set dbName=reg_%buildNumber%
if not defined schemas set schemas=load/stage/fact
if not defined dsnName set dsnName=SQL-%dbName%
if not defined msiName set msiName=red.msi
if not defined redExe set redExe=red.exe
if not defined db set db=yes
if not defined dsn set dsn=yes
if not defined appNo set appNo=1
if not defined OdbcDrv set OdbcDrv=1

if not defined svrUser set svrUser=Red1
if not defined svrPW set svrPW=Wsl12345
if /i %Trusted%a==Yesa (
set svrUser=
set svrPW=
)


set archArg=--meta-dsn-arch 64
if %arch%a==bit32a set archArg= 

if /i %installOnly%a==Yesa (
   set db=no
   set dsn=no
)


Rem Assign Application
set redApp=%AppPath%!redApp%appNo%!

Rem overwrite the app if a name is given
if NOT %appname%a==a (
set redApp=%AppName%
)

Rem Derive install folder

if not defined installFolder set installFolder=build-!buildNumber!%buildBranch%

set installFolder="C:\program files\Wherescape\%installFolder%"

rem Not installing on 32bit machines
rem if /i %PROCESSOR_ARCHITECTURE% EQU AMD64 if /i %arch%a EQU b32a (
rem    set installFolder=%installFolder:program files=program files (x86)%
rem )


set installFolder=%installFolder:"=%
set schedName=%dbName%_%buildNumber:~2,4%_%RANDOM:~0,2%

if /i %EchoOnly%a==Yesa goto printEnv

Rem Create database
:create_Database
set cur_Lable=create_Database
if /i %debug%a==ona echo "AT: %cur_Lable%"

if %Trusted%a==a (
echo call sqlCreateDB2 !svrName! %dbName% svrUser=%svrUser% schemas=%schemas% drop=!drop! dsnname=%dsnname% dsn=yes db=%db% OdbcDrv=%OdbcDrv% odbcDrvName=%ODBCDrvName%
call sqlCreateDB2 !svrName! %dbName% svrUser=%svrUser% schemas=%schemas% drop=!drop! dsnname=%dsnname% dsn=%dsn% db=%db% OdbcDrv=%OdbcDrv% arch=%arch% odbcDrvName=%ODBCDrvName%
) Else (
echo call sqlCreateDB2 !svrName! %dbName% svrUser=%svrUser% schemas=%schemas% drop=!drop! dsnname=%dsnname% dsn=yes db=%db% OdbcDrv=%OdbcDrv% odbcDrvName=%ODBCDrvName%
call sqlCreateDB2 !svrName! %dbName% schemas=%schemas% drop=!drop! dsnname=%dsnname% dsn=%dsn% db=%db% OdbcDrv=%OdbcDrv% arch=%arch% odbcDrvName=%ODBCDrvName%
)

Rem Install Red
:installRed
set cur_Lable=installRed
if /i %debug%a==ona echo "AT: %cur_Lable%"

if not exist "%buildPath%\!redExe!" goto useMSI

echo start /wait "install" "%buildPath%\!redExe!" /qb APPDIR="!installFolder!"
start /wait "install" "%buildPath%\!redExe!" /qb APPDIR="!installFolder!"
goto endInstall

:useMSI
echo start /wait msiexec /qb /i "%buildPath%\!msiName!" APPDIR="!installFolder!"
start /wait msiexec /qb /i "%buildPath%\!msiName!" APPDIR="!installFolder!"

:endInstall

Rem  Create shortcuts using PowerShell. Probably they should go to a folder in desktop instead desktop/
:CreateShourtcut
set cur_Lable=CreateShortcut
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts '!InstallFolder!' !dsnName! !svrUser!}"
start /wait powershell -ExecutionPolicy Bypass  -command "& {. .\createShortCuts.ps1; createShortcuts '!InstallFolder!' !dsnName! !svrUser!}"

if /i %installOnly%a==yesa goto installSched

Rem Create a Quick Repository. This does not load the defatul application
:CreateQRepo
set cur_Lable=CreateQRepo
if /i %debug%a==ona echo "AT: %cur_Lable%"
echo start "ADM" /wait "!installFolder!\adm.exe" %ArchArg% -QR -SN %dsnName% -SL %svrUser% -SP %svrPW%
start "ADM" /wait "!installFolder!\adm.exe" %ArchArg% -QR -SN %dsnName% -SL %svrUser% -SP %svrPW%

:createSetXML
set cur_Lable=createSetXML
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Construct the settings xml file. First 3 lines contain the credentials and DSN.
echo 	^<UserID^>%svrUser%^</UserID^> > c:\temp\up1.txt
echo 	^<Password^>%svrPW%^</Password^> >> c:\temp\up1.txt
echo 	^<DSN^>%dsnName%^</DSN^> >> c:\temp\up1.txt
echo 	^<DSNArchitecture^>64^</DSNArchitecture^> >> c:\temp\up1.txt
copy .\WslAppLoadOptions.xmp1 + c:\temp\up1.txt + .\WslAppLoadOptions.xmp1 C:\temp\WslAppLoadOptions.xml

:loadDefApp
set cur_Lable=loadDefApp
if /i %debug%a==ona echo "AT: %cur_Lable%"
Rem Load default application
echo "ADM" /wait "!installFolder!\adm.exe"   /AL /AF "%installFolder%\Application\app_id_SQLT_base_1.wst" /LF c:\temp\%buildNumber%base.log /PF C:\temp\WslAppLoadOptions.xml
start "ADM" /wait "!installFolder!\adm.exe"  /AL /AF "%installFolder%\Application\app_id_SQLT_base_1.wst" /LF c:\temp\%buildNumber%base.log /PF C:\temp\WslAppLoadOptions.xml 

:loadTemplateApp
echo "ADM" /wait "!installFolder!\adm.exe"  /AL /AF "%installFolder%\Application\app_id_SQLT_templates.wst" /LF c:\temp\%buildNumber%template.log /PF C:\temp\WslAppLoadOptions.xml 
start "ADM" /wait "!installFolder!\adm.exe"  /AL /AF "%installFolder%\Application\app_id_SQLT_templates.wst" /LF c:\temp\%buildNumber%template.log /PF C:\temp\WslAppLoadOptions.xml 

:installSched
if Sched==No goto run_red1
echo Installing scheduler ....
echo "ADM" /wait "!installFolder!\adm.exe"  %ArchArg%  -WS -ID %schedName% -IN W%buildNumber:~2,4%%RANDOM:~0,2% -SN %dsnName% -SL %svrUser% -SP %SvrPW% 
start "ADM" /wait "!installFolder!\adm.exe" %ArchArg%  -WS -ID %schedName% -IN W%buildNumber:~2,4%%RANDOM:~0,2% -SN %dsnName% -SL %svrUser% -SP %SvrPW% 
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

echo start "ADM" /wait "!installFolder!\adm.exe"  /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
start "ADM" /wait "!installFolder!\adm.exe"  /AL /AF %redApp% /LF c:\temp\%buildNumber%.log /PF C:\temp\WslAppLoadOptions.xml 
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


goto end_Reg_setup

:print_info
echo.
echo.
echo -----------------------------------------------------------------------------
if %paraError%==2 echo Please specify a server name using svrName parameter
if %paraError%==3 echo Please specify path to red executable using buildPath parameter
if %paraError%==1 (
echo Unknown Parameter: %1
echo.
)
echo Supported parameters:
echo.
for %%p in ( %parameters%) do echo       %%p

echo.
pause
echo.
echo Usage:
echo %0 ^<SvrName^> ^<Path_to_build^>
echo.
echo Example: Install build and Create a repo in 'QA_Sql_2016'
echo.
echo %0 svrName=QA_Sql_2016 buildpath="S:\RED Daily Build\Build 6.9.1.0\170613-174742" svruser=sa svrPW=wsl
echo.
echo   Defaults
echo     Trusted        No
echo     SvrUser:       Red1
echo     SvrPW:         Wsl12345
echo     dbname:        reg_buildnumber		  
echo     schemas:       load/stage/fact
echo     dsnName:       SQL_^<dbName^>
echo     buildNumber    substring after last "\" in path to build
echo     InstallFolder  {programFolder}\Wherescap\build-{buildNumber}
echo     buildBranch    default blank, if set add it to build folder
echo     exeName        red.exe
echo     EchoOnly:      No
echo     InstallOnly    No
echo     AppNo          1  - Set to 0 to skip application install
echo.
echo Defualts can be overwritten by setting keyword=value in command line
echo.
echo Apps:
echo Application path: %AppPath%
echo.
for %%a in (1 2 3 4 5 6 7 8 9) do echo %%a. !RedApp%%a!
echo. 
echo -----------------------------------------------------------------------------


:end_Reg_setup


