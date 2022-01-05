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

REM Start shell.
IF "%*%" == "" (
    IF DEFINED MOZILLABUILD_USE_DEFAULT_WINDOWS_CONSOLE (
        %MOZILLABUILD%msys2\msys2_shell.cmd -defterm -full-path
    ) ELSE (
        %MOZILLABUILD%msys2\msys2_shell.cmd -full-path
    )
) ELSE (
    %MOZILLABUILD%msys2\usr\bin\bash --login -i -c "%*"
)
EXIT /B
