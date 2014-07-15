!include version.nsi
!cd mozilla-build

!include WinVer.nsh
RequestExecutionLevel highest

SetCompressor /SOLID lzma
InstallDir "C:\mozilla-build"

LicenseData "..\license.rtf"
Page license
Page directory
Page instfiles

Section "MozillaBuild"
  MessageBox MB_YESNO|MB_ICONQUESTION "Previous installations in $INSTDIR will be overwritten (user-created files will be preserved). Do you want to continue?" /SD IDYES IDYES continue
  SetErrors
  return
  continue:
  SetOutPath $INSTDIR
  Delete "$INSTDIR\start-l10n.bat"
  Delete "$INSTDIR\start-msvc71.bat"
  Delete "$INSTDIR\start-msvc8.bat"
  Delete "$INSTDIR\start-msvc8-x64.bat"
  Delete "$INSTDIR\start-msvc9.bat"
  Delete "$INSTDIR\start-msvc9-x64.bat"
  Delete "$INSTDIR\start-msvc10.bat"
  Delete "$INSTDIR\start-msvc10-x64.bat"
  Delete "$INSTDIR\start-msvc11.bat"
  Delete "$INSTDIR\start-msvc11-x64.bat"
  Delete "$INSTDIR\start-msvc12.bat"
  Delete "$INSTDIR\start-msvc12-x64.bat"
  Delete "$INSTDIR\moztools\bin\gmake.exe"
  Delete "$INSTDIR\moztools\bin\shmsdos.exe"
  Delete "$INSTDIR\moztools\bin\uname.exe"
  RMDir /r "$INSTDIR\blat261"
  RMDir /r "$INSTDIR\moztools\include"
  RMDir /r "$INSTDIR\moztools\lib"
  RMDir /r "$INSTDIR\moztools-x64\include"
  RMDir /r "$INSTDIR\moztools-x64\lib"
  RMDir /r "$INSTDIR\nsis-2.33u"
  RMDir /r "$INSTDIR\upx203w"
  File /r *.*
  ; write the full path to ca-bundle.crt in wget.ini
  FileOpen $0 "$INSTDIR\wget\wget.ini" w
  FileWrite $0 "ca_certificate=$INSTDIR\wget\ca-bundle.crt$\r$\n"
  FileClose $0
  ; write the full path to cacert.pem in 
  FileOpen $0 "$INSTDIR\hg\hgrc.d\Paths.rc" w
  FileWrite $0 "[web]$\r$\n"
  FileWrite $0 "cacerts=$INSTDIR\hg\hgrc.d\cacert.pem"
  FileClose $0
SectionEnd
