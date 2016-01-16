name "Mozilla Build @VERSION@"
OutFile "..\MozillaBuildSetup@VERSION@.exe"

# Install to a unique directory by default if this is a test build.
Function .onInit
StrCpy $0 "@VERSION@" 3 -4
${If} $0 == "pre"
  StrCpy $INSTDIR "C:\mozilla-build-@VERSION@"
${Else}
  StrCpy $INSTDIR "C:\mozilla-build"
${EndIf}
FunctionEnd

