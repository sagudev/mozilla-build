@echo off

SETLOCAL
SET MOZ_MSVCVERSION=14
SET MOZBUILDDIR=%~dp0
SET MOZILLABUILD=%MOZBUILDDIR%

echo Mozilla tools directory: %MOZBUILDDIR%

REM Get MSVC paths
call "%MOZBUILDDIR%guess-msvc.bat"

REM Use the "new" moztools-static
set MOZ_TOOLS=%MOZBUILDDIR%moztools-x64

rem append moztools to PATH
SET PATH=%PATH%;%MOZ_TOOLS%\bin

if "%VC14DIR%"=="" (
    ECHO "Microsoft Visual C++ version 14 (2015) was not found. Exiting."
    pause
    EXIT /B 1
)

if "%SDKDIR%"=="" (
    ECHO "No Windows SDK found. Exiting."
    pause
    EXIT /B 1
)

rem Prepend MSVC paths
rem By default, the Windows 8.1 SDK should be automatically included via vcvars64.bat.
if exist "%VC14DIR%\bin\amd64\vcvars64.bat" (
    call "%VC14DIR%\bin\amd64\vcvars64.bat"
    ECHO Using the MSVC 2015 64-bit toolchain.
) else (
    ECHO Unable to find a suitable vcvars batch script. Exiting.
    pause
    EXIT /B 1
)
ECHO Using the built-in Windows 8.1 SDK.

cd "%USERPROFILE%"

"%MOZILLABUILD%\msys\bin\bash" --login -i
