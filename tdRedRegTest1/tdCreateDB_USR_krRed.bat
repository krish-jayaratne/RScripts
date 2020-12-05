@Echo off
echo.
REM *******************************************************************
REM    Description    :    Creates schema for TD repository
REM    Author         :    Krish Jayaratne, WhereScape
Rem    Date           :    10 Mar 2015
Rem    Version		  :    1
REM *******************************************************************


setlocal EnableDelayedExpansion
setlocal enableextensions

set svrUser=dbc
set svrPW=dbc
set usrPW=Wsl12345
set Red_User=kr_redUser

Set cre_user_scr=userCreate.sql
set g_user_scr=grantUser.sql
set test_acc_scr=testacc.sql

if exist %cre_user_scr% del  %cre_user_scr%
if exist %test_acc_scr% del  %test_acc_scr%
if exist %g_user_scr% del  %g_user_scr%

set DSN=
set DB=Yes
set drop=no
set schemas=


if a%2 EQU a goto msg

set svr=%1
set dbname=%2


:setpara
set cur_lable=setpara
if %3a EQU a goto setpara_done
set %3=%4
Shift
Shift
goto setpara

:setpara_done
set cur_lable=setpara_done

if /I not !db!a==Yesa (
echo db=%db% - Not creating database. Teradata DSN creation not supported. Nothing to do.
goto end)

if /I !dsnname!a==a set dsnName=DSN-!dbname!

if /I !db! EQU Yes goto create_user
if %ERRORLEVEL% NEQ 0  goto error_info
goto e_grant_usr_perm

REM *******************************************************************
Rem      if DB=Yes, Create the schema/user 
REM *******************************************************************
:create_user
set cur_lable=create_user
set RetAdr=create_user


REM ******************************************************
Rem  More manual setting related to structure of schemas.
REM ******************************************************

set setPwdString=PASSWORD=%usrPW%
set objType=database
set nested=yes

if /i %objType%a==databasea (
   set setPwdString=
   )

set parentDB=DBC
set masterSize=1000000000
set reposize=200000000
set childSize=50000000
if /i a%nested%==aYes (
   set parentDB=!dbname!
   set masterSize=1000000000
)
   
REM ********************************************************



if not exist %cre_user_scr% goto create_scr_schema

echo bteq logon !svr!/!svrUser!,!svrPW! ^< %cre_user_scr%
bteq logon !svr!/!svrUser!,!svrPW! < %cre_user_scr%
pause
if %ERRORLEVEL% NEQ 0  goto error_info
:e_create_user


REM *******************************************************************
Rem      if DB=Yes, Grant user permissions 
REM *******************************************************************
:grant_usr_perm
set cur_lable=grant_usr_perm
set RetAdr=grant_usr_perm

if not exist %g_user_scr% goto create_scr_user_grants

echo bteq logon !svr!/!svrUser!,!svrPW! ^< %g_user_scr%
bteq logon !svr!/!svrUser!,!svrPW! < %g_user_scr%


:test_account
set cur_lable=test_account
set RetAdr=test_account

if not exist %test_acc_scr% goto create_test_acc_script

if %ERRORLEVEL% NEQ 0  goto error_info
echo  bteq logon !svr!/%red_user%,%usrPW% ^< %test_acc_scr%
bteq logon !svr!/%red_user%,%usrPW% < %test_acc_scr%
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



goto end

:msg
echo.
echo Usage:  
echo    %0 'ServerIP' 'schema/db Name' DSNName={DSN to use}  		  
echo       -Creates databases and set permissions for a master 
echo.
echo    Other Parameters:   
echo       svrUser=userName   -Overrides server username dbc
echo       svrPW=password     -Overrides server password of default dbc
echo       usrPW=password     -Overrrides user password of default Wsl12345
echo       drop=Yes           -Drops db (master and schema) before create
echo       schemas=sc1/sc2/.. -Creates p to 5 schemas, seperated by '/'
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

Rem create drop option - this is much more clearer than using statement blocks.

if /i !drop!==yes (
REM     echo DELETE DATABASE  %dbname%_USER;  >> %cre_user_scr%
    echo DELETE DATABASE  %dbname%_REPO;  >> %cre_user_scr%
	for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
   	    if NOT %%ia==a echo DELETE DATABASE  %dbname%_%%i;  >> %cre_user_scr%
		if NOT %%ja==a echo DELETE DATABASE  %dbname%_%%j;  >> %cre_user_scr%
		if NOT %%ka==a echo DELETE DATABASE  %dbname%_%%k;  >> %cre_user_scr%
		if NOT %%la==a echo DELETE DATABASE  %dbname%_%%l;  >> %cre_user_scr%
		if NOT %%ma==a echo DELETE DATABASE  %dbname%_%%m;  >> %cre_user_scr%
	)

REM    echo DROP USER %dbname%_USER;  >> %cre_user_scr%
	for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
		if NOT %%ia==a echo DROP %objType% %dbname%_%%i;  >> %cre_user_scr%
		if NOT %%ja==a echo DROP %objType% %dbname%_%%j;  >> %cre_user_scr%
		if NOT %%ka==a echo DROP %objType% %dbname%_%%k;  >> %cre_user_scr%
		if NOT %%la==a echo DROP %objType% %dbname%_%%l;  >> %cre_user_scr%
		if NOT %%ma==a echo DROP %objType% %dbname%_%%m;  >> %cre_user_scr%
	)
    echo DROP DATABASE  %dbname%_REPO;  >> %cre_user_scr%
	echo DELETE DATABASE %dbname%; >> %cre_user_scr%
	echo DROP DATABASE %dbname%; >> %cre_user_scr%
)

echo CREATE DATABASE %dbname% FROM DBC AS PERM = %masterSize%  NO BEFORE JOURNAL NO AFTER JOURNAL;  >> %cre_user_scr%
REM echo CREATE USER %dbname%_USER FROM %dbname% AS PERM = %childsize%  NO BEFORE JOURNAL NO AFTER JOURNAL PASSWORD=%usrPW% ;  >> %cre_user_scr%
echo CREATE DATABASE %dbname%_REPO FROM %dbname% AS PERM = %reposize%  NO BEFORE JOURNAL NO AFTER JOURNAL;  >> %cre_user_scr%

for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
	if NOT %%ia==a echo CREATE %objType% %dbname%_%%i FROM %dbname% AS PERM = %childsize% NO BEFORE JOURNAL NO AFTER JOURNAL %setPwdString%;  >> %cre_user_scr%
	if NOT %%ja==a echo CREATE %objType% %dbname%_%%j FROM %dbname% AS PERM = %childsize% NO BEFORE JOURNAL NO AFTER JOURNAL %setPwdString%;  >> %cre_user_scr%
	if NOT %%ka==a echo CREATE %objType% %dbname%_%%k FROM %dbname% AS PERM = %childsize% NO BEFORE JOURNAL NO AFTER JOURNAL %setPwdString%;  >> %cre_user_scr%
	if NOT %%la==a echo CREATE %objType% %dbname%_%%l FROM %dbname% AS PERM = %childsize% NO BEFORE JOURNAL NO AFTER JOURNAL %setPwdString%;  >> %cre_user_scr%
	if NOT %%ma==a echo CREATE %objType% %dbname%_%%m FROM %dbname% AS PERM = %childsize% NO BEFORE JOURNAL NO AFTER JOURNAL %setPwdString%;  >> %cre_user_scr%
)

echo .LOGOFF  >> %cre_user_scr%
echo .QUIT >> %cre_user_scr%
goto %RetAdr%


Rem *******************************************************************
Rem  Create User permission grant script
Rem *******************************************************************
:create_scr_user_grants
echo GRANT SELECT, INSERT, UPDATE, DELETE, TABLE, VIEW, SHOW, MACRO, PROCEDURE, STATISTICS, EXECUTE, EXECUTE PROCEDURE ON %dbname%_REPO TO %Red_User%;  >> %g_user_scr%
echo GRANT EXECUTE PROCEDURE ON %dbname%_REPO TO %dbname%_REPO WITH GRANT OPTION;  >> %g_user_scr%

echo GRANT SELECT ON DBC.TABLESV TO %Red_User%;  >> %g_user_scr%
echo GRANT SELECT ON DBC.COLUMNSV TO  %Red_User%;  >> %g_user_scr%
echo GRANT SELECT ON SYSLIB.SQLRESTRICTEDWORDS TO %Red_User%;  >> %g_user_scr%
echo GRANT SELECT ON DBC.ErrorMsgs TO %Red_User%;  >> %g_user_scr%

set Schemas1=%schemas%

for /F "delims=/ tokens=1-5" %%i in ("!schemas!") do (
    if NOT %%ia==a echo GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON %dbname%_%%i TO %dbname%_REPO;  >> %g_user_scr%
    if NOT %%ja==a echo GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON %dbname%_%%j TO %dbname%_REPO;  >> %g_user_scr%
    if NOT %%ka==a echo GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON %dbname%_%%k TO %dbname%_REPO;  >> %g_user_scr%
    if NOT %%la==a echo GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON %dbname%_%%l TO %dbname%_REPO;  >> %g_user_scr%
    if NOT %%ma==a echo GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON %dbname%_%%m TO %dbname%_REPO;  >> %g_user_scr%
)

for /F "delims=/ tokens=1-5" %%i in ("!schemas1!") do (
    if NOT %%ia==a echo GRANT SELECT, INSERT, UPDATE, DELETE, TABLE, VIEW, SHOW, STATISTICS ON %dbname%_%%i TO %Red_User%;  >> %g_user_scr%
    if NOT %%ja==a echo GRANT SELECT, INSERT, UPDATE, DELETE, TABLE, VIEW, SHOW, STATISTICS ON %dbname%_%%j TO %Red_User%;  >> %g_user_scr%
    if NOT %%ka==a echo GRANT SELECT, INSERT, UPDATE, DELETE, TABLE, VIEW, SHOW, STATISTICS ON %dbname%_%%k TO %Red_User%;  >> %g_user_scr%
    if NOT %%la==a echo GRANT SELECT, INSERT, UPDATE, DELETE, TABLE, VIEW, SHOW, STATISTICS ON %dbname%_%%l TO %Red_User%;  >> %g_user_scr%
    if NOT %%ma==a echo GRANT SELECT, INSERT, UPDATE, DELETE, TABLE, VIEW, SHOW, STATISTICS ON %dbname%_%%m TO %Red_User%;  >> %g_user_scr%
)

echo .LOGOFF  >> %g_user_scr%
echo .QUIT >> %g_user_scr%
goto %RetAdr%


Rem *******************************************************************
Rem  Create Test account script
Rem *******************************************************************
:create_test_acc_script
rem echo SELECT DATABASENAME FROM DATABASES WHERE DATABASENAME LIKE '%dbname%'; > %test_acc_scr%
echo .LOGOFF >> %test_acc_scr%
echo .QUIT >> %test_acc_scr%
goto %RetAdr%


:end
rem if exist %cre_user_scr% del  %cre_user_scr%
rem if exist %g_user_scr% del  %g_user_scr%
if exist %test_acc_scr% del  %test_acc_scr%

endLocal
rem for /f "usebackq tokens=1 delims==" %i in (`set %z1dbssnpf%`) do set %i=
rem set set z1dbssnpf=