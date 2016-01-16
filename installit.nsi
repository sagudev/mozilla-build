!include LogicLib.nsh
!include WinVer.nsh

!include version.nsi

!cd mozilla-build

RequestExecutionLevel highest
SetCompressor /SOLID lzma

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
  Delete "$INSTDIR\guess-msvc.bat"
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
  Delete "$INSTDIR\start-shell-l10n.bat"
  Delete "$INSTDIR\start-shell-msvc2010.bat"
  Delete "$INSTDIR\start-shell-msvc2010-x64.bat"
  Delete "$INSTDIR\start-shell-msvc2012.bat"
  Delete "$INSTDIR\start-shell-msvc2012-x64.bat"
  Delete "$INSTDIR\moztools\bin\gmake.exe"
  Delete "$INSTDIR\moztools\bin\shmsdos.exe"
  Delete "$INSTDIR\moztools\bin\uname.exe"
  RMDir /r "$INSTDIR\atlthunk_compat"
  RMDir /r "$INSTDIR\blat261"
  RMDir /r "$INSTDIR\emacs-24.2"
  RMDir /r "$INSTDIR\emacs-24.3"
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
  ; Replace occurrences of @INSTDIR@ in mercurial.ini with $INSTDIR
  Push @INSTDIR@
  Push $INSTDIR
  Push all
  Push all
  Push "$INSTDIR\python\mercurial.ini"
    Call AdvReplaceInFile
SectionEnd

# From http://nsis.sourceforge.net/More_advanced_replace_text_in_file
Function AdvReplaceInFile
Exch $0 ;file to replace in
Exch
Exch $1 ;number to replace after
Exch
Exch 2
Exch $2 ;replace and onwards
Exch 2
Exch 3
Exch $3 ;replace with
Exch 3
Exch 4
Exch $4 ;to replace
Exch 4
Push $5 ;minus count
Push $6 ;universal
Push $7 ;end string
Push $8 ;left string
Push $9 ;right string
Push $R0 ;file1
Push $R1 ;file2
Push $R2 ;read
Push $R3 ;universal
Push $R4 ;count (onwards)
Push $R5 ;count (after)
Push $R6 ;temp file name
 
  GetTempFileName $R6
  FileOpen $R1 $0 r ;file to search in
  FileOpen $R0 $R6 w ;temp file
   StrLen $R3 $4
   StrCpy $R4 -1
   StrCpy $R5 -1
 
loop_read:
 ClearErrors
 FileRead $R1 $R2 ;read line
 IfErrors exit
 
   StrCpy $5 0
   StrCpy $7 $R2
 
loop_filter:
   IntOp $5 $5 - 1
   StrCpy $6 $7 $R3 $5 ;search
   StrCmp $6 "" file_write1
   StrCmp $6 $4 0 loop_filter
 
StrCpy $8 $7 $5 ;left part
IntOp $6 $5 + $R3
IntCmp $6 0 is0 not0
is0:
StrCpy $9 ""
Goto done
not0:
StrCpy $9 $7 "" $6 ;right part
done:
StrCpy $7 $8$3$9 ;re-join
 
IntOp $R4 $R4 + 1
StrCmp $2 all loop_filter
StrCmp $R4 $2 0 file_write2
IntOp $R4 $R4 - 1
 
IntOp $R5 $R5 + 1
StrCmp $1 all loop_filter
StrCmp $R5 $1 0 file_write1
IntOp $R5 $R5 - 1
Goto file_write2
 
file_write1:
 FileWrite $R0 $7 ;write modified line
Goto loop_read
 
file_write2:
 FileWrite $R0 $R2 ;write unmodified line
Goto loop_read
 
exit:
  FileClose $R0
  FileClose $R1
 
   SetDetailsPrint none
  Delete $0
  Rename $R6 $0
  Delete $R6
   SetDetailsPrint lastused
 
Pop $R6
Pop $R5
Pop $R4
Pop $R3
Pop $R2
Pop $R1
Pop $R0
Pop $9
Pop $8
Pop $7
Pop $6
Pop $5
;These values are stored in the stack in the reverse order they were pushed
Pop $0
Pop $1
Pop $2
Pop $3
Pop $4
FunctionEnd
