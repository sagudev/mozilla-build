rem This script is specific to the paths on the mozillabuild-builder vm.
rem Alter to suit your environment.

set VCDIR=C:\Program Files\Microsoft Visual Studio 10.0
set PYTHONDIR=C:\Python27
set SRCDIR=%~dp0%

call "%VCDIR%\VC\bin\vcvars32.bat"

cd %SRCDIR%
%PYTHONDIR%\python.exe packageit.py --msys c:\msys --output c:\stage

pause
