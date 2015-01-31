REM -*- Mode: fundamental; tab-width: 8; indent-tabs-mode: 1 -*-
@ECHO OFF

set CYGWIN=
if not defined MOZ_NO_RESET_PATH (
    set PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem
)

REM if DISPLAY is set, rxvt attempts to load libX11.dll and fails to start
REM (see mozilla bug 376828)
SET DISPLAY=

SET INCLUDE=
SET LIB=

SET WINCURVERKEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion
REG QUERY "%WINCURVERKEY%" /v "ProgramFilesDir (x86)" >nul 2>nul
IF NOT ERRORLEVEL 1 (
  SET MSVCROOTKEY=HKLM\SOFTWARE\Wow6432Node\Microsoft\VisualStudio
  SET MSVCEXPROOTKEY=HKLM\SOFTWARE\Wow6432Node\Microsoft\VCExpress
  SET WIN64=1
) else (
  SET MSVCROOTKEY=HKLM\SOFTWARE\Microsoft\VisualStudio
  SET MSVCEXPROOTKEY=HKLM\SOFTWARE\Microsoft\VCExpress
  SET WIN64=0
)

SET MSVC12KEY=%MSVCROOTKEY%\12.0\Setup\VC
SET MSVC12EXPRESSKEY=%MSVCEXPROOTKEY%\12.0\Setup\VC
SET MSVC14KEY=%MSVCROOTKEY%\14.0\Setup\VC

REM First see if we can find MSVC, then set the variable
REM NOTE: delims=<tab><space>
REM NOTE: Use IF ERRORLEVEL X to check if the last ERRORLEVEL was GEQ(greater or equal than) X

if "%VC12DIR%"=="" (
  REG QUERY "%MSVC12KEY%" /v ProductDir >nul 2>nul
  IF NOT ERRORLEVEL 1 (
    FOR /F "tokens=2*" %%A IN ('REG QUERY "%MSVC12KEY%" /v ProductDir') DO SET VC12DIR=%%B
  )
)

if "%VC12EXPRESSDIR%"=="" (
  REG QUERY "%MSVC12EXPRESSKEY%" /v ProductDir >nul 2>nul
  IF NOT ERRORLEVEL 1 (
    FOR /F "tokens=2*" %%A IN ('REG QUERY "%MSVC12EXPRESSKEY%" /v ProductDir') DO SET VC12EXPRESSDIR=%%B
  )
)

if "%VC14DIR%"=="" (
  REG QUERY "%MSVC14KEY%" /v ProductDir >nul 2>nul
  IF NOT ERRORLEVEL 1 (
    FOR /F "tokens=2*" %%A IN ('REG QUERY "%MSVC14KEY%" /v ProductDir') DO SET VC14DIR=%%B
  )
)

REM Look for Installed SDKs
SET SDKPRODUCTKEY=HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Products
SET SDKROOTKEY=HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots

REM Just a base value to compare against
SET SDKDIR=
SET SDKVER=0
SET SDKMINORVER=0

REM Support a maximum version of the Windows SDK to use, to support older
REM branches and older compilers.  (Note that this is unrelated to the configure
REM option on which version of Windows to support.)
IF NOT DEFINED MOZ_MAXWINSDK (
  REM Maximum WinSDK version to use; 2 digits for major, 2 for minor, 2 for revision
  REM Revivsion is A = 01, B = 02, etc.
  SET MOZ_MAXWINSDK=999999
)

REM Windows Software Development Kit DirectX Remote (SDK 8.1)
if "%SDKDIR%"=="" IF %MOZ_MAXWINSDK% GEQ 80100 (
  if "%WIN64%" == "1" (
    REG QUERY "%SDKPRODUCTKEY%" /v "{5247E16E-BCF8-95AB-1653-B3F8FBF8B3F1}" >nul 2>nul
  ) else (
    REG QUERY "%SDKPRODUCTKEY%" /v "{A1CB8286-CFB3-A985-D799-721A0F2A27F3}" >nul 2>nul
  )
  IF NOT ERRORLEVEL 1 (
    FOR /F "tokens=2*" %%A IN ('REG QUERY "%SDKROOTKEY%" /v KitsRoot81') DO SET SDKDIR=%%B
	SET SDKVER=8
	SET SDKMINORVER=1
  )
)

REM The Installed Products key still exists even if the SDK is uninstalled.
REM Verify that the Windows.h header exists to confirm that the SDK is
REM installed.
IF "%SDKDIR%" NEQ "" IF NOT EXIST "%SDKDIR%\Include\um\Windows.h" (
  SET SDKDIR=
)

if defined VC12DIR ECHO Visual C++ 12 directory: %VC12DIR%
if defined VC12EXPRESSDIR ECHO Visual C++ 12 Express directory: %VC12EXPRESSDIR%
if defined VC14DIR ECHO Visual C++ 14 directory: %VC14DIR%


setlocal enableextensions enabledelayedexpansion
if "!SDKDIR!"=="" (
    SET SDKDIR=!PSDKDIR!
    SET SDKVER=%PSDKVER%
) else (
    ECHO Windows SDK directory: !SDKDIR!
    ECHO Windows SDK version: %SDKVER%.%SDKMINORVER%
)
if not "!PSDKDIR!"=="" (
    ECHO Platform SDK directory: !PSDKDIR!
    ECHO Platform SDK version: %PSDKVER%
)

setlocal disableextensions disabledelayedexpansion
