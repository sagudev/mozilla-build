!include version.nsi
!cd mozilla-build

!include WinVer.nsh
RequestExecutionLevel highest

SetCompressor /SOLID lzma
InstallDir "C:\mozilla-build-test"

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
  Delete "$INSTDIR\start-shell-msvc2010.bat"
  Delete "$INSTDIR\start-shell-msvc2010-x64.bat"
  Delete "$INSTDIR\start-shell-msvc2012.bat"
  Delete "$INSTDIR\start-shell-msvc2012-x64.bat"
  Delete "$INSTDIR\moztools\bin\gmake.exe"
  Delete "$INSTDIR\moztools\bin\shmsdos.exe"
  Delete "$INSTDIR\moztools\bin\uname.exe"
  RMDir /r "$INSTDIR\atlthunk_compat"
  RMDir /r "$INSTDIR\blat261"
  RMDir /r "$INSTDIR\hg"
  RMDir /r "$INSTDIR\moztools\include"
  RMDir /r "$INSTDIR\moztools\lib"
  RMDir /r "$INSTDIR\moztools-x64\include"
  RMDir /r "$INSTDIR\moztools-x64\lib"
  RMDir /r "$INSTDIR\msys\lib\perl5\site_perl\5.6.1\msys"
  RMDir /r "$INSTDIR\nsis-2.33u"
  RMDir /r "$INSTDIR\upx203w"
  RMDir /r "$INSTDIR\wix-351728"
  File /r *.*
  ; Write the full path to ca-bundle.crt in wget.ini
  FileOpen $0 "$INSTDIR\wget\wget.ini" w
  FileWrite $0 "ca_certificate=$INSTDIR\msys\etc\ca-bundle.crt$\r$\n"
  FileClose $0
  ; Write the full path to ca-bundle.crt in mercurial.ini
  FileOpen $0 "$INSTDIR\python\mercurial.ini" a
  FileSeek $0 0 END
  FileWrite $0 "$\n[web]$\n"
  FileWrite $0 "cacerts=$INSTDIR\msys\etc\ca-bundle.crt$\n"
  FileClose $0
SectionEnd
