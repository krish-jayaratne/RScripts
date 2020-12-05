@Echo off
REM *******************************************************************
REM    Description    :    Creates schema, DSN for Oracle repository
REM    Author         :    Krish Jayaratne, WhereScape - Internal use only
Rem    Date           :    15 Jan 2015
Rem    Version		  :    1.0	
REM *******************************************************************

setlocal EnableDelayedExpansion
setlocal enableextensions

set svrUser=sys
set svrPW=Wsl12345
set usrPW=Wsl12345

set parameters=dbName db schemas svrUser svrPW usrPW dsnName dsn  Master echoOnly installFolder drop

Set cre_user_scr=userCreate.sql
set g_user_scr=grantUser.sql
set test_acc_scr=testacc.sql
set g_master_scr=grantMaster.sql

if exist %cre_user_scr% del  %cre_user_scr%
if exist %g_master_scr% del  %g_master_scr%
if exist %test_acc_scr% del  %test_acc_scr%
if exist %g_user_scr% del  %g_user_scr%

set DSN=
set DB=
set drop=
set schemas=


if a%2 EQU a goto msg

set svr=%1
set dbname=%2


:ParsePara
set cur_lable=ParsePara
if debug==on  echo "AT: %cur_Lable%"
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

if %db%%DSN%a EQU a (
set db=Yes
set DSN=Yes
)


if NOT defined Master (
   set Master=Yes
   if !schemas!a==a set Master=No 
)

if !dsnname!a==a set dsnName=ORCL-!dbname!

if /I !db! EQU Yes goto create_user
if %ERRORLEVEL% NEQ 0  goto error_info
goto e_grant_usr_perm

REM *******************************************************************
Rem      if DB=Yes, Create the schema/user 
REM *******************************************************************
:create_user
set cur_lable=create_user
set RetAdr=create_user

if not exist %cre_user_scr% goto create_scr_schema

echo sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!
sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!
pause
if %ERRORLEVEL% NEQ 0  goto error_info
pause

for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
    echo if NOT %%ia==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%i
    if NOT %%ia==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%i

    echo if NOT %%ja==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%j
    if NOT %%ja==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%j

    echo if NOT %%ka==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%k
    if NOT %%ka==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%k

    echo if NOT %%la==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%l
    if NOT %%la==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%l

    echo if NOT %%ma==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%m
    if NOT %%ma==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%cre_user_scr% !dbname!_%%m
)
:e_create_user


REM *******************************************************************
Rem      if DB=Yes, Grant user permissions 
REM *******************************************************************
:grant_usr_perm
set cur_lable=grant_usr_perm
set RetAdr=grant_usr_perm

if not exist %g_user_scr% goto create_scr_user_grants

echo sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!
sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!

for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
    echo if NOT %%ia==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%i
    if NOT %%ia==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%i

    echo if NOT %%ja==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%j
    if NOT %%ja==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%j

    echo if NOT %%ka==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%k
    if NOT %%ka==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%k

    echo if NOT %%la==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%l
    if NOT %%la==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%l

    echo if NOT %%ma==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%m
    if NOT %%ma==a sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_user_scr% !dbname!_%%m
)

:test_account
set cur_lable=test_account
set RetAdr=test_account

if not exist %test_acc_scr% goto create_test_acc_script

if %ERRORLEVEL% NEQ 0  goto error_info
echo sqlplus !dbname!/"!usrPW!"@!svr! @%test_acc_scr%
sqlplus !dbname!/"!usrPW!"@!svr! @%test_acc_scr%
if %ERRORLEVEL% NEQ 0  goto error_info

:e_grant_usr_perm

if /i !Dsn! EQU Yes goto create_dsn
goto e_create_dsn

REM *******************************************************************
Rem      If DSN=Yes, Create ODBC DSN (if DSN=Yes)
REM *******************************************************************
:create_dsn
set %cur_lable=create_dsn

if /i %PROCESSOR_ARCHITECTURE% EQU AMD64 (
echo c:\windows\SYSWOW64\odbcconf  CONFIGSYSDSN "Microsoft ODBC for Oracle" "DSN=!dsnName!|Description=ORACLE SCHEMA !dbname!|SERVER=!svr!"
c:\windows\SYSWOW64\odbcconf  CONFIGSYSDSN "Microsoft ODBC for Oracle" "DSN=!dsnName!|Description=ORACLE SCHEMA !dbname!|SERVER=!svr!"
) ELSE (
echo c:\windows\system32\odbcconf  CONFIGSYSDSN "Microsoft ODBC for Oracle" "DSN=!dsnName!|Description=ORACLE SCHEMA !dbname!|SERVER=!svr!"
c:\windows\system32\odbcconf  CONFIGSYSDSN "Microsoft ODBC for Oracle" "DSN=!dsnName!|Description=ORACLE SCHEMA !dbname!|SERVER=!svr!"
)
if %ERRORLEVEL% NEQ 0  goto error_info

:e_create_dsn
if /i !Master!!DB! EQU YesYes goto create_master
goto e_create_master

REM *******************************************************************
Rem      If Master=Yes, Grant db wide permissions (if DB=Yes)
REM *******************************************************************
:create_master
set cur_lable=create_master
set RetAdr=!cur_lable!

if not exist %g_master_scr% goto create_scr_master_grants

echo sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_master_scr% !dbname!
sqlplus "!svrUser!/!svrPW!@!svr! as sysdba" @%g_master_scr% !dbname!
if %ERRORLEVEL% NEQ 0  goto error_info

:e_create_master


goto end

:msg
echo.
echo Usage:  
echo    %0 'tnsName' 'schema/db Name'  		  
echo       -Creates a database and dsn (dsn name set to  dsn-schemaname)
echo        This is equalant to DSN=Yes DB=Yes
echo.
echo    %0 tnsName schemaName  DSN=Yes 
echo       -Creates only DSN name as 'DSN-Schema'
echo.
echo    %0 tnsName schemaName  DB=Yes 
echo       -Creates ony the Database
echo.
echo    Other Parameters:   
echo       svrUser=user       -Overrides server admin user (default sys)
echo       svrPW=password     -Overrides server password (default Wsl12345)
echo       usrPW=password     -Overrrides schema password (default Wsl12345)
echo       Master=Yes         -In oracle, it makes the schema the master	
echo       dsnName=name       -overrides the DSN Name (defalut ORCL-dbname)							
echo       drop=Yes           -Drops db (master and schema) before create
echo       schemas=sc1/sc2/.. -Creates up to 5 schemas, seperated by '/'
goto end

:error_info
echo.
echo **** ERROR ***
echo.
echo Error at !cur_lable!
echo.
echo ++++++++
for /f %%i in  (%parameters%) echo %%i
echo ++++++++
goto end


Rem *******************************************************************
Rem  Create Schema/db create script
Rem *******************************************************************
:create_scr_schema
if /i !drop!==yes echo drop user ^&1 cascade; > %cre_user_scr%
echo create user ^&1 identified by "!usrPW!"; >> %cre_user_scr%
echo exit;  >> %cre_user_scr%
goto %RetAdr%


Rem *******************************************************************
Rem  Create User permission grant script
Rem *******************************************************************
:create_scr_user_grants
echo grant create session to ^&1;  >  %g_user_scr%
echo grant create procedure to ^&1;  >>  %g_user_scr%
echo grant create sequence to ^&1;  >>  %g_user_scr%
echo grant create database link to ^&1;  >>  %g_user_scr%
echo grant create table to ^&1;  >>  %g_user_scr%
echo grant create view to ^&1;  >>  %g_user_scr%
echo grant create materialized view to ^&1;  >>  %g_user_scr%
echo grant query rewrite to ^&1;  >>  %g_user_scr%
echo grant global query rewrite to ^&1;  >>  %g_user_scr%
echo grant select any table to ^&1;  >>  %g_user_scr%
echo grant select on sys.v_$session to ^&1;  >>  %g_user_scr%
echo grant drop any table to ^&1;  >>  %g_user_scr%
echo grant execute on sys.dbms_lock to ^&1;  >>  %g_user_scr%
echo grant unlimited tablespace to ^&1;  >>  %g_user_scr%
echo exit; >>  %g_user_scr%
goto %RetAdr%


Rem *******************************************************************
Rem  Create Master permission grant script
Rem *******************************************************************
:create_scr_master_grants
echo grant select any table to ^&1;  > %g_master_scr%
echo grant create any view to ^&1;  >> %g_master_scr%
echo grant drop any view to ^&1;  >> %g_master_scr%
echo grant create any table to ^&1;  >> %g_master_scr%
echo grant drop any table to ^&1;  >> %g_master_scr%
echo grant delete any table to ^&1;  >> %g_master_scr%
echo grant insert any table to ^&1;  >> %g_master_scr%
echo grant update any table to ^&1;  >> %g_master_scr%
echo grant alter any table to ^&1;  >> %g_master_scr%
echo grant global query rewrite to ^&1;  >> %g_master_scr%
echo grant create any materialized view to ^&1;  >> %g_master_scr%
echo grant drop any materialized view to ^&1;  >> %g_master_scr%
echo grant alter any materialized view to ^&1;  >> %g_master_scr%
echo grant create any index to ^&1;  >> %g_master_scr%
echo grant drop any index to ^&1;  >> %g_master_scr%
echo grant alter any index to ^&1;  >> %g_master_scr%
echo grant select any sequence to ^&1;  >> %g_master_scr%
echo grant create any sequence to ^&1;  >> %g_master_scr%
echo grant drop any sequence to ^&1;  >> %g_master_scr%
echo grant analyze any to ^&1;  >> %g_master_scr%

Rem for OLH loads
echo grant select_catalog_role to ^&1;  >> %g_master_scr%    
echo exit;  >> %g_master_scr%
goto %RetAdr%


Rem *******************************************************************
Rem  Create Test account script
Rem *******************************************************************
:create_test_acc_script
echo HELP INDEX; > %test_acc_scr%
echo exit >> %test_acc_scr%
goto %RetAdr%


:end
if exist %cre_user_scr% del  %cre_user_scr%
if exist %g_user_scr% del  %g_user_scr%
if exist %test_acc_scr% del  %test_acc_scr%
if exist %g_master_scr% del  %g_master_scr%

endLocal
