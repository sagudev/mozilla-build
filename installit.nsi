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
  MessageBox MB_YESNO|MB_ICONQUESTION "This will overwrite everything in $INSTDIR. Do you want to continue?" /SD IDYES IDYES continue
  SetErrors
  return
  continue:
  SetOutPath $INSTDIR
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
