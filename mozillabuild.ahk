; This is an AutoHotKey script, tested using AHK 1.0.47.06
; http://www.autohotkey.com/
SetTitleMatchMode Regex
; MSYS setup (complicated)
WinWait, Minimal SYStem, Welcome, 600
if ErrorLevel
   Exit
WinActivate
Click, 360, 360
WinWait, Minimal SYStem, License, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, Minimal SYStem, InfoBefore, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, Minimal SYStem, SelectDir, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, Minimal SYStem, SelectComponents, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, Minimal SYStem, SelectProgramGroup, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, Minimal SYStem, Install, 10
if ErrorLevel
   Exit
Click, 360, 360
; Answer no to post-setup
WinWaitActive, ahk_class ConsoleWindowClass, , 600
if ErrorLevel
   Exit
Sleep 10000
Send, n{Enter}
Sleep 2000
Send, {Enter}
WinWait, Minimal SYStem, Finished, 10
if ErrorLevel
   Exit
Click, 185, 130
Click, 185, 155
Click, 360, 360
; MSYS DTK
WinWait, MSYS Developer Tool Kit, Welcome, 600
if ErrorLevel
   Exit
WinActivate
Click, 360, 360
WinWait, MSYS Developer Tool Kit, License, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, MSYS Developer Tool Kit, SelectDir, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, MSYS Developer Tool Kit, SelectComponents, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, MSYS Developer Tool Kit, Ready, 10
if ErrorLevel
   Exit
Click, 360, 360
WinWait, MSYS Developer Tool Kit, InfoAfter, 600
if ErrorLevel
   Exit
Click, 360, 360
WinWait, MSYS Developer Tool Kit, Finished, 10
if ErrorLevel
   Exit
Click, 360, 360
