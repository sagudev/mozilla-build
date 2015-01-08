@echo off

SETLOCAL
SET MOZ_MSVCVERSION=14
SET MOZBUILDDIR=%~dp0
SET MOZILLABUILD=%MOZBUILDDIR%

echo "Mozilla tools directory: %MOZBUILDDIR%"

REM Get MSVC paths
call "%MOZBUILDDIR%guess-msvc.bat"

REM Use the "new" moztools-static
set MOZ_TOOLS=%MOZBUILDDIR%moztools

rem append moztools to PATH
SET PATH=%PATH%;%MOZ_TOOLS%\bin

if "%VC14DIR%"=="" (
    ECHO "Microsoft Visual C++ version 14 (2015) was not found. Exiting."
    pause
    EXIT /B 1
)

rem Prepend MSVC paths
rem By default, the Windows 8.1 SDK should be automatically included via vcvars32.bat.
rem Prefer cross-compiling 32-bit builds using the 64-bit toolchain if able to do so.
if exist "%VC14DIR%\bin\amd64_x86\vcvarsamd64_x86.bat" (
    call "%VC14DIR%\bin\amd64_x86\vcvarsamd64_x86.bat"
    ECHO Using the VC 2013 64-bit toolchain and built-in Windows 8.1 SDK
) else (
    call "%VC14DIR%\bin\vcvars32.bat"
    ECHO Using the VC 2013 32-bit toolchain and built-in Windows 8.1 SDK
)

cd "%USERPROFILE%"

"%MOZILLABUILD%\msys\bin\bash" --login -i
