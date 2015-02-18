@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Reset some env vars and set some others.
SET INCLUDE=
SET LIB=
SET CYGWIN=
IF NOT DEFINED MOZ_NO_RESET_PATH (
  SET PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem
)

SET MOZBUILDDIR=%~dp0
SET MOZILLABUILD=%MOZBUILDDIR%

ECHO MozillaBuild Install Directory: %MOZBUILDDIR%

REM Figure out if we're on a 32-bit or 64-bit host OS.
REM NOTE: Use IF ERRORLEVEL X to check if the last ERRORLEVEL was GEQ(greater or equal than) X.
SET WINCURVERKEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion
REG QUERY "%WINCURVERKEY%" /v "ProgramFilesDir (x86)" >nul 2>nul
IF NOT ERRORLEVEL 1 (
  SET WIN64=1
) ELSE (
  REM Bail early if the x64 MSVC start script is invoked on a 32-bit host OS.
  REM Note: We explicitly aren't supporting x86->x64 cross-compiles.
  IF "%MOZ_MSVCBITS%" == "64" (
    ECHO.
    ECHO The MSVC 64-bit toolchain is not supported on a 32-bit host OS. Exiting.
    ECHO.
    PAUSE
    EXIT /B 1
  )
  SET WIN64=0
)

REM Append moztools to PATH
IF "%WIN64%" == "1" (
  SET MOZ_TOOLS=%MOZBUILDDIR%moztools-x64
) ELSE (
  SET MOZ_TOOLS=%MOZBUILDDIR%moztools
)
SET PATH=%PATH%;%MOZ_TOOLS%\bin

REM Set up the MSVC environment if called from one of the start-shell-msvc batch files.
IF DEFINED MOZ_MSVCVERSION (
  IF NOT DEFINED VCDIR (
    REM Set the MSVC registry key.
    IF "%WIN64%" == "1" (
      SET MSVCKEY=HKLM\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\%MOZ_MSVCVERSION%.0\Setup\VC
    ) ELSE (
      SET MSVCKEY=HKLM\SOFTWARE\Microsoft\VisualStudio\%MOZ_MSVCVERSION%.0\Setup\VC
    )

    REM Find the MSVC installation directory and bail if none is found.
    REG QUERY !MSVCKEY! /v ProductDir >nul 2>nul
    IF NOT ERRORLEVEL 1 (
      FOR /F "tokens=2*" %%A IN ('REG QUERY !MSVCKEY! /v ProductDir') DO SET VCDIR=%%B
    ) ELSE (
      ECHO.
      ECHO Microsoft Visual C++ %MOZ_MSVCYEAR% was not found. Exiting.
      ECHO.
      PAUSE
      EXIT /B 1
    )
  )

  IF NOT DEFINED SDKDIR (
    REM Set the Windows SDK registry keys.
    SET SDKPRODUCTKEY=HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Products
    SET SDKROOTKEY=HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots
    IF "%WIN64%" == "1" (
      SET WIN81SDKKEY={5247E16E-BCF8-95AB-1653-B3F8FBF8B3F1}
    ) ELSE (
      SET WIN81SDKKEY={A1CB8286-CFB3-A985-D799-721A0F2A27F3}
    )

    REM Windows SDK 8.1
    REG QUERY "!SDKPRODUCTKEY!" /v "!WIN81SDKKEY!" >nul 2>nul
    IF NOT ERRORLEVEL 1 (
      FOR /F "tokens=2*" %%A IN ('REG QUERY "!SDKROOTKEY!" /v KitsRoot81') DO SET SDKDIR=%%B
	  SET SDKVER=8
  	  SET SDKMINORVER=1
    )
    REM The Installed Products key still exists even if the SDK is uninstalled.
    REM Verify that the Windows.h header exists to confirm that the SDK is installed.
    IF DEFINED SDKDIR IF NOT EXIST "!SDKDIR!\Include\um\Windows.h" (
      SET SDKDIR=
    )

    REM Bail if no Windows SDK is found.
    IF NOT DEFINED SDKDIR (
      ECHO.
      ECHO No Windows SDK found. Exiting.
      ECHO.
      PAUSE
      EXIT /B 1
    )
  )

  ECHO Visual C++ %MOZ_MSVCYEAR% Directory: !VCDIR!
  ECHO Windows SDK Directory: !SDKDIR!

  REM Prepend MSVC paths.
  IF "%WIN64%" == "1" (
    IF "%MOZ_MSVCBITS%" == "32" (
      REM Prefer cross-compiling 32-bit builds using the 64-bit toolchain if able to do so.
      IF EXIST "!VCDIR!\bin\amd64_x86\vcvarsamd64_x86.bat" (
        CALL "!VCDIR!\bin\amd64_x86\vcvarsamd64_x86.bat"
        ECHO Using the MSVC %MOZ_MSVCYEAR% 64-bit cross-compile toolchain.
      )
    ) ELSE IF "%MOZ_MSVCBITS%" == "64" (
      IF EXIST "!VCDIR!\bin\amd64\vcvars64.bat" (
        CALL "!VCDIR!\bin\amd64\vcvars64.bat"
        ECHO Using the MSVC %MOZ_MSVCYEAR% 64-bit toolchain.
      )
    )
  ) ELSE IF EXIST "!VCDIR!\bin\vcvars32.bat" (
    CALL "!VCDIR!\bin\vcvars32.bat"
    ECHO Using the MSVC %MOZ_MSVCYEAR% 32-bit toolchain.
  )

  REM LIB will be defined if vcvars has run. Bail if it isn't.
  IF NOT DEFINED LIB (
    ECHO.
    ECHO Unable to call a suitable vcvars script. Exiting.
    ECHO.
    PAUSE
    EXIT /B 1
  )
)

cd "%USERPROFILE%"
%MOZILLABUILD%\msys\bin\bash --login -i
