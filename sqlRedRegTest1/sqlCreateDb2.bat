
REM *******************************************************************
REM    Description    :    Creates schema, DSN for SQL repository
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    19 Jan 2015
Rem    Version		  :    .9	
REM *******************************************************************

@echo off
setlocal EnableDelayedExpansion
setlocal enableextensions

Set cre_db_scr=userCreate.sql
Set g_user_scr=grant_perm.sql
Set test_acc_scr=test_account.sql
set DSN=
set DSNNAME=
set DB=
set drop=
set schemas=
set ODBC_DRV_1="SQL Server Native Client 11.0"
set ODBC_DRV_2="ODBC Driver 17 for SQL Server"
set ODBC_DRV_3="SQL Server"
set ODBC_DRV=
set arch=bit64

set parameters=DB DSN svrPW svrUser sqlLogin schemas drop dbname dsnName OdbcDrv arch odbcDrvName

if exist !cre_db_scr! del  !cre_db_scr!
if exist !g_user_scr! del  !g_user_scr!
if exist !test_acc_scr! del  !test_acc_scr!

if a%2 EQU a goto msg

set svr=%1
set dbname=%2

:ParsePara
set cur_lable=ParsePara
if %3a EQU a goto ParsePara_done
echo %parameters% | find /i "%3" > nul
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
if %db%%DSN%a EQU a (
set db=Yes
set DSN=Yes
)

Rem set ODBC driver
if %OdbcDrv%a==a (
set ODBC_DRV=%ODBC_DRV_2%
) ELSE (
set ODBC_DRV=!ODBC_DRV_%OdbcDrv%!
)

Rem if the driver name is given, overwrite
if NOT %OdbcDrvName%a==a (
set ODBC_DRV=%OdbcDrvName%
)


if !dsnname!a == a set dsnName=SQL-!dbname!

if %svrUser%%svrPW%a EQU a (       
set svrCred=-E
set Trusted=Yes
) ELSE (
if NOT defined svrPW set svrPW=Wsl12345
if NOT defined  svrUser set svrUser=sa
set  svrCred=-U !svrUser! -P !svrPW!
set Trusted=No
)

if /I !db! EQU Yes goto create_db
if %ERRORLEVEL% NEQ 0  goto error_info
goto e_grant_usr_perm


REM *******************************************************************
Rem      if DB=Yes, Create the schema/db/usrPW 
REM *******************************************************************
:create_db
set cur_lable=create_db
set RetAdr=create_db

if not exist %cre_db_scr% goto create_scr_db

echo sqlcmd %svrCred% -S !svr! db_name="!dbname!" -i %cre_db_scr%
sqlcmd %svrCred% -S !svr! -v db_name="!dbname!" -i %cre_db_scr%
if %ERRORLEVEL% NEQ 0  goto error_info
pause
:e_create_db


REM *******************************************************************
Rem      if DB=Yes, Grant user permissions 
REM *******************************************************************
:grant_usr_perm
set cur_lable=grant_usr_perm
set RetAdr=grant_usr_perm

if not exist %g_user_scr% goto create_scr_user_grants

echo sqlcmd %svrCred% -S !svr! -v sql_login="!sqlLogin!" -i  %g_user_scr%
sqlcmd %svrCred% -S !svr! -v sql_login="!sqlLogin!"  -i  %g_user_scr%

:test_account
set cur_lable=test_account
set RetAdr=test_account

if not exist %test_acc_scr% goto create_test_acc_script

echo sqlcmd %svrCred% -S !svr! -i  %test_acc_scr%
sqlcmd %svrCred% -S !svr! -i %test_acc_scr%

if %ERRORLEVEL% NEQ 0  goto error_info

:e_grant_usr_perm

if /i !Dsn! EQU Yes goto create_dsn
goto e_create_dsn

REM *******************************************************************
Rem      If DSN=Yes, Create ODBC DSN (if DSN=Yes)
REM *******************************************************************
:create_dsn
set %cur_lable=create_dsn

if %arch%a==bit32a (
echo c:\windows\Syswow64\odbcconf.exe  CONFIGSYSDSN %ODBC_Drv% "DSN=!dsnName!|Description=SQL Connection for !svr!.!dbname!|SERVER=!svr!|Trusted_Connection=!Trusted!|Database=!dbname!"
  c:\windows\Syswow64\odbcconf.exe  CONFIGSYSDSN %ODBC_Drv% "DSN=!dsnName!|Description=SQL Connection for !svr!.!dbname!|SERVER=!svr!|Trusted_Connection=!Trusted!|Database=!dbname!"
) ELSE (
  echo c:\windows\system32\odbcconf.exe  CONFIGSYSDSN %ODBC_Drv% "DSN=!dsnName!|Description=SQL Connection for !svr!.!dbname!|SERVER=!svr!|Trusted_Connection=!Trusted!|Database=!dbname!"
  c:\windows\system32\odbcconf.exe  CONFIGSYSDSN %ODBC_Drv% "DSN=!dsnName!|Description=SQL Connection for !svr!.!dbname!|SERVER=!svr!|Trusted_Connection=!Trusted!|Database=!dbname!"
)

if %ERRORLEVEL% NEQ 0  goto error_info

:e_create_dsn


goto end

:msg
echo.
echo Usage:  
echo    %0 'svrName' 'database'  		  
echo       -Creates a database and dsn (dsn name set to  dsn-dbname)
echo        This is equalant to DSN=Yes DB=Yes
echo.
echo    %0 'svrName' 'database'  DSN=Yes 
echo       -Creates the DSN name as 'DSN-Schema'
echo.
echo    %0 'svrName' 'database'  DB=Yes 
echo       -Creates the Database
echo.
echo    Other Parameters:   
echo       svrPW, svrUser          -if not set, trusted connection
echo       svrPW=password          -no trusted conn, server user=sa
echo       svrUser=user            -no trusted conn, server password is Wsl12345
echo       sqlLogin=sqluser        -Add sql login sql user, set role to db_owner
echo       schemas=sch1/sch2/..    -Create schemas sch1, sch2 under DB (upto 5)
echo       drop=Yes                -Drop datbase before creating
echo       dsnName=name            -overrides the defalut dsn name "dsn-dbname"
ecoo       ODBCDrv=1               -Override ODBCDriver, Eg setting 2 means it use ODBC_DRV_2
echo       arch=bit64              -Default is bit64, use bit32 for 32bit env (32bit environments)

goto end

:error_info
echo.
echo **** ERROR ***
echo.
echo Error at !cur_lable!
echo.
echo ++++++++
echo "!parameters!"
for /f %%i in  ("%parameters%") do echo %%i=!%%i!
echo ++++++++
goto end

goto end


Rem *******************************************************************
Rem  Create Schema/db create script
Rem *******************************************************************
:create_scr_db
echo use master  > %cre_db_scr%
if /i !drop!==Yes (
  echo ALTER DATABASE $(db_name^) set SINGLE_USER with rollback IMMEDIATE  >> %cre_db_scr%
  echo go  >> %cre_db_scr%
  echo drop database $(db_name^)  >> %cre_db_scr%
  echo go  >> %cre_db_scr%
)
echo create database $(db_name)  >> %cre_db_scr%
echo go  >> %cre_db_scr%

if NOT %schemas%a==a  (
  echo use $(db_name^) >> %cre_db_scr%
  echo go >> %cre_db_scr%
  for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
    if NOT %%ia==a @echo create schema [%%i]  >> %cre_db_scr%
    if NOT %%ia==a @echo go  >> %cre_db_scr%
    if NOT %%ja==a @echo create schema [%%j]  >> %cre_db_scr%
    if NOT %%ja==a @echo go  >> %cre_db_scr%
    if NOT %%ka==a @echo create schema [%%k]  >> %cre_db_scr%
    if NOT %%ka==a @echo go  >> %cre_db_scr%
    if NOT %%la==a @echo create schema [%%l]  >> %cre_db_scr%
    if NOT %%la==a @echo go  >> %cre_db_scr%
    if NOT %%ma==a @echo create schema [%%m]  >> %cre_db_scr% 
    if NOT %%ma==a @echo go  >> %cre_db_scr%
	)
)
goto %RetAdr%


Rem *******************************************************************
Rem  Create User permission grant script
Rem *******************************************************************
:create_scr_user_grants
echo use !dbname!   > %g_user_scr%
echo go  >> %g_user_scr%
if defined sqlLogin echo create user $(sql_login) for login $(sql_login)  >> %g_user_scr%
if defined sqlLogin echo go  >> %g_user_scr%
if defined sqlLogin echo sp_addrolemember 'db_owner','$(sql_login)'  >> %g_user_scr%
if defined sqlLogin echo go  >> %g_user_scr%
if defined sqlLogin echo sp_changedbowner 'sa'  >> %g_user_scr%
if defined sqlLogin echo go  >> %g_user_scr%
echo use master  >> %g_user_scr%
goto %RetAdr%

Rem *******************************************************************
Rem  Create Test account script
Rem *******************************************************************
:create_test_acc_script
echo use !dbname! > %test_acc_scr%
goto %RetAdr%

:end
if exist !cre_db_scr! del  !cre_db_scr!
if exist !g_user_scr! del  !g_user_scr!
if exist !test_acc_scr! del  !test_acc_scr!
rem for /f "usebackq tokens=1 delims==" %i in (`set %z1dbssnpf%`) do set %i=
rem set set z1dbssnpf=
