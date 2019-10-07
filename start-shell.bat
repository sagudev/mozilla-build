@ECHO OFF

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Reset some env vars.
SET CYGWIN=
SET INCLUDE=
SET LIB=
SET GITDIR=

REM mintty is available as an alternate terminal, but is not enabled by default due
REM to various usability regressions. Set USE_MINTTY to 1 to enable it.
IF NOT DEFINED USE_MINTTY (
  SET USE_MINTTY=
)

SET MOZILLABUILD=%~dp0

REM Find the Git bin directory so we can add it to the PATH.
IF NOT DEFINED MOZ_NO_GIT_DETECT (
  REM Try Windows PATH first
  FOR /F "tokens=*" %%A IN ('where git 2^>NUL') DO SET GITDIR=%%~dpA
  REM Current User 64-bit
  IF NOT DEFINED GITDIR (
    FOR /F "tokens=2*" %%A IN ('REG QUERY HKCU\Software\GitForWindows /v InstallPath 2^>NUL') DO SET "GITDIR=%%B\bin"
  )
  REM Current User 32-bit
  IF NOT DEFINED GITDIR (
    FOR /F "tokens=2*" %%A IN ('REG QUERY HKCU\Software\Wow6432Node\GitForWindows /v InstallPath 2^>NUL') DO SET "GITDIR=%%B\bin"
  )
  REM Local Machine 64-bit
  IF NOT DEFINED GITDIR (
    FOR /F "tokens=2*" %%A IN ('REG QUERY HKLM\Software\GitForWindows /v InstallPath 2^>NUL') DO SET "GITDIR=%%B\bin"
  )
  REM Local Machine User 32-bit
  IF NOT DEFINED GITDIR (
    FOR /F "tokens=2*" %%A IN ('REG QUERY HKLM\Software\Wow6432Node\GitForWindows /v InstallPath 2^>NUL') DO SET "GITDIR=%%B\bin"
  )
)

REM Reset to a known clean path, appending the path to Git if we found it.
IF NOT DEFINED MOZ_NO_RESET_PATH (
  SET PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem
)
IF DEFINED GITDIR (
  SET "PATH=%PATH%;!GITDIR!"
  SET GITDIR=
)

REM Start shell.
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
