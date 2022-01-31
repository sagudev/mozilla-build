@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Reset some env vars.
SET CYGWIN=
SET INCLUDE=
SET LIB=
SET GITDIR=
REM Opt into "ConPTY" support, which enables usage of win32 console binaries from MSYS2.
SET MSYS=enable_pcon
SET MOZILLABUILD=%~dp0

FOR /F "tokens=* USEBACKQ" %%F IN (`where ssh 2^>NUL`) DO (
    SET EXTERNAL_TO_MOZILLABUILD_SSH_DIR=%%~dpF
)

REM Start shell.
%MOZILLABUILD%msys2\msys2_shell.cmd -full-path %*
EXIT /B
