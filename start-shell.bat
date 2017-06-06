@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Reset some env vars and set some others.
SET CYGWIN=
SET INCLUDE=
SET LIB=
IF NOT DEFINED MOZ_NO_RESET_PATH (
  SET PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem
)

REM mintty is available as an alternate terminal, but is not enabled by default due
REM to various usability regressions. Set USE_MINTTY to 1 to enable it.
IF NOT DEFINED USE_MINTTY (
  SET USE_MINTTY=
)

SET MOZILLABUILD=%~dp0

REM Figure out if we're on a 32-bit or 64-bit host OS.
REM NOTE: Use IF ERRORLEVEL X to check if the last ERRORLEVEL was GEQ(greater or equal than) X.
SET WINCURVERKEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion
REG QUERY "%WINCURVERKEY%" /v "ProgramFilesDir (x86)" >nul 2>nul
IF NOT ERRORLEVEL 1 (
  SET WIN64=1
) ELSE (
  SET WIN64=0
)

REM Set up LLVM if present.
SET LLVMDIR=
IF "%WIN64%" == "1" (
  SET LLVMKEY=HKLM\SOFTWARE\Wow6432Node\LLVM\LLVM
) ELSE (
  SET LLVMKEY=HKLM\SOFTWARE\LLVM\LLVM
)
REM Find the LLVM installation directory
REG QUERY "!LLVMKEY!" /ve >nul 2>nul
IF NOT ERRORLEVEL 1 (
  FOR /F "tokens=2*" %%A IN ('REG QUERY "!LLVMKEY!" /ve') DO SET LLVMDIR=%%B
  SET PATH="%PATH%;!LLVMDIR!\bin"
)

IF "%USE_MINTTY%" == "1" (
  START %MOZILLABUILD%msys\bin\mintty -e %MOZILLABUILD%msys\bin\console %MOZILLABUILD%msys\bin\bash --login
) ELSE (
  IF "%*%" == "" (
    %MOZILLABUILD%msys\bin\bash --login -i
  ) ELSE (
    %MOZILLABUILD%msys\bin\bash --login -i -c "%*"
  )
)
EXIT /B
