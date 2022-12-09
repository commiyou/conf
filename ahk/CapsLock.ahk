;=====================================================================o
;                   Feng Ruohang's AHK Script                         |
;                      CapsLock Enhancement                           |
;---------------------------------------------------------------------o
;Description:                                                         |
;    This Script is wrote by Feng Ruohang via AutoHotKey Script. It   |
; Provieds an enhancement towards the "Useless Key" CapsLock, and     |
; turns CapsLock into an useful function Key just like Ctrl and Alt   |
; by combining CapsLock with almost all other keys in the keyboard.   |
;                                                                     |
;Summary:                                                             |
;o----------------------o---------------------------------------------o
;|CapsLock;             | {ESC}  Especially Convient for vim user     |
;|CaspLock + `          | {CapsLock}CapsLock Switcher as a Substituent|
;|CapsLock + hjklwb     | Vim-Style Cursor Mover                      |
;|CaspLock + uiop       | Convient Home/End PageUp/PageDn             |
;|CaspLock + nm,.       | Convient Delete Controller                  |
;|CapsLock + zxcvay     | Windows-Style Editor                        |
;|CapsLock + Direction  | Mouse Move                                  |
;|CapsLock + Enter      | Mouse Click                                 |
;|CaspLock + {F1}~{F6}  | Media Volume Controller                     |
;|CapsLock + qs         | Windows & Tags Control                      |
;|CapsLock + ;'[]       | Convient Key Mapping                        |
;|CaspLock + dfert      | Frequently Used Programs (Self Defined)     |
;|CaspLock + 123456     | Dev-Hotkey for Visual Studio (Self Defined) |
;|CapsLock + 67890-=    | Shifter as Shift                            |
;-----------------------o---------------------------------------------o
;|Use it whatever and wherever you like. Hope it help                 |
;=====================================================================o
#SingleInstance force
DetectHiddenText On

return


~RAlt & F8::Reload
~Pause::
Suspend
Pause,,1
return
;=====================================================================o
;                       CapsLock Initializer                         ;|
;---------------------------------------------------------------------o
SetCapsLockState, AlwaysOff                                          ;|
CapsLock::return
;---------------------------------------------------------------------o
#If GetKeyState("CapsLock", "P")
<!::return
<^::return

`::
    if GetKeyState("CapsLock", "T")
        SetCapsLockState, AlwaysOff
    else
        SetCapsLockState, AlwaysOn
    KeyWait, ``
return

; caps + s + h/k/j/l/d/f      ----- mouse movement/click
s:: return
s & h:: MouseMove, -10, 0, 0, R
s & k:: MouseMove, 0, -10, 0, R
s & j:: MouseMove, 0, 10, 0, R
s & l:: MouseMove, 10, 0, 0, R
s & d::
    SendEvent  {Blind}{LButton down}
    KeyWait, d
    SendEvent  {Blind}{LButton up}
return
s & f::
    SendEvent  {Blind}{RButton down}
    KeyWait, f
    SendEvent  {Blind}{RButton up}
return

; caps + h/k/j/l              ------- direction navigator, ctrl alt compatible
*h::
    if GetKeyState("control") {
        if GetKeyState("alt")
            Send, +^{Left}
        else
            Send, ^{Left}
    }
    else {
        if GetKeyState("alt")
            Send, +{Left}
        else
            Send, {Left}
    }
return
*j::
    if GetKeyState("control") {
        if GetKeyState("alt")
            Send, +^{Down}
        else
            Send, ^{Down}
    }
    else {
        if GetKeyState("alt")
            Send, +{Down}
        else
            Send, {Down}
    }
return
*k::
    if GetKeyState("control") {
        if GetKeyState("alt")
            Send, +^{Up}
        else
            Send, ^{Up}
    }
    else {
        if GetKeyState("alt")
            Send, +{Up}
        else
            Send, {Up}
    }
return
*l::
    if GetKeyState("control") {
        if GetKeyState("alt")
            Send, +^{Right}
        else
            Send, ^{Right}
    }
    else {
        if GetKeyState("alt")
            Send, +{Right}
        else
            Send, {Right}
    }
return

; application 
a & c:: Run calc.exe   ; -- todo, for uwp

; windows management
; space --- alwas on top
Space::
    ;WinGetTitle, activeWindow, A
    WinGet, windowStyle, ExStyle, A
    isWindowAlwaysOnTop := if (windowStyle & 0x8) ? true : false ; 0x8 is WS_EX_TOPMOST.
    if !isWindowAlwaysOnTop
        notificationMessage := "now always on TOP."
    else
        notificationMessage := "now no longer always on top."
    Winset, AlwaysOnTop, , A
    WinGetPos, , , width, height, A
    CoordMode, ToolTip, Window
    ToolTip, %notificationMessage%, % width/3, % height/3
    SetTimer, RemoveToolTip, -4000
return

;=====================================================================o
;                            CapsLock Editor                         ;|
;-----------------------------------o---------------------------------o
x:: Send ^x
c:: 
    SendLevel, 1
    Send !c  ; copy hotkey in mac-kbd.ahk
return
v:: 
    SendLevel, 1
    Send !v  ; paste hotkey in mac-kbd.ahk
return

d::
    Run "https://translate.google.com/#view=home&op=translate&sl=auto&tl=zh-CN&text=%clipboard%"
return
f::
    Clip := trim(clipboard)
    if RegExMatch(Clip, "https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)") = 1 {
        Run %Clip%
    } else {
        Run "http://www.google.com/search?q=%Clip%"
    }
return

; CpasLock + uiop PageUp HOME END PageDown

u:: Send, {PgUp} 
i:: Send, {Home} 
o:: Send, {End} 
p:: Send, {PgDn} 
#If

;RShift:: MsgBox, % A_Language  ; todo, show tooltip
 

RemoveToolTip:
    ToolTip
return

 

;
;
;;=====================================================================o
;;                     CapsLock Home/End Navigator                    ;|
;;-----------------------------------o---------------------------------o
;;                      CapsLock + i |  Home                          ;|
;;                      CapsLock + o |  End                           ;|
;;                      Ctrl, Alt Compatible                          ;|
;;-----------------------------------o---------------------------------o
;CapsLock & i::                                                       ;|
;if GetKeyState("control") = 0                                        ;|
;{                                                                    ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, {Home}                                                 ;|
;    else                                                             ;|
;        Send, +{Home}                                                ;|
;    return                                                           ;|
;}                                                                    ;|
;else {                                                               ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, ^{Home}                                                ;|
;    else                                                             ;|
;        Send, +^{Home}                                               ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & o::                                                       ;|
;if GetKeyState("control") = 0                                        ;|
;{                                                                    ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, {End}                                                  ;|
;    else                                                             ;|
;        Send, +{End}                                                 ;|
;    return                                                           ;|
;}                                                                    ;|
;else {                                                               ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, ^{End}                                                 ;|
;    else                                                             ;|
;        Send, +^{End}                                                ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                      CapsLock Page Navigator                       ;|
;;-----------------------------------o---------------------------------o
;;                      CapsLock + u |  PageUp                        ;|
;;                      CapsLock + p |  PageDown                      ;|
;;                      Ctrl, Alt Compatible                          ;|
;;-----------------------------------o---------------------------------o
;CapsLock & u::                                                       ;|
;if GetKeyState("control") = 0                                        ;|
;{                                                                    ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, {PgUp}                                                 ;|
;    else                                                             ;|
;        Send, +{PgUp}                                                ;|
;    return                                                           ;|
;}                                                                    ;|
;else {                                                               ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, ^{PgUp}                                                ;|
;    else                                                             ;|
;        Send, +^{PgUp}                                               ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & p::                                                       ;|
;if GetKeyState("control") = 0                                        ;|
;{                                                                    ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, {PgDn}                                                 ;|
;    else                                                             ;|
;        Send, +{PgDn}                                                ;|
;    return                                                           ;|
;}                                                                    ;|
;else {                                                               ;|
;    if GetKeyState("alt") = 0                                        ;|
;        Send, ^{PgDn}                                                ;|
;    else                                                             ;|
;        Send, +^{PgDn}                                               ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                     CapsLock Mouse Controller                      ;|
;;-----------------------------------o---------------------------------o
;;                   CapsLock + Up   |  Mouse Up                      ;|
;;                   CapsLock + Down |  Mouse Down                    ;|
;;                   CapsLock + Left |  Mouse Left                    ;|
;;                  CapsLock + Right |  Mouse Right                   ;|
;;    CapsLock + Enter(Push Release) |  Mouse Left Push(Release)      ;|
;;-----------------------------------o---------------------------------o
;CapsLock & Up::    MouseMove, 0, -10, 0, R                           ;|
;CapsLock & Down::  MouseMove, 0, 10, 0, R                            ;|
;CapsLock & Left::  MouseMove, -10, 0, 0, R                           ;|
;CapsLock & Right:: MouseMove, 10, 0, 0, R                            ;|
;;-----------------------------------o                                ;|
;CapsLock & Enter::                                                   ;|
;SendEvent {Blind}{LButton down}                                      ;|
;KeyWait Enter                                                        ;|
;SendEvent {Blind}{LButton up}                                        ;|
;return                                                               ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                           CapsLock Deletor                         ;|
;;-----------------------------------o---------------------------------o
;;                     CapsLock + n  |  Ctrl + Delete (Delete a Word) ;|
;;                     CapsLock + m  |  Delete                        ;|
;;                     CapsLock + ,  |  BackSpace                     ;|
;;                     CapsLock + .  |  Ctrl + BackSpace              ;|
;;-----------------------------------o---------------------------------o
;CapsLock & ,:: Send, {Del}                                           ;|
;CapsLock & .:: Send, ^{Del}                                          ;|
;CapsLock & m:: Send, {BS}                                            ;|
;CapsLock & n:: Send, ^{BS}                                           ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                            CapsLock Editor                         ;|
;;-----------------------------------o---------------------------------o
;;                     CapsLock + z  |  Ctrl + z (Cancel)             ;|
;;                     CapsLock + x  |  Ctrl + x (Cut)                ;|
;;                     CapsLock + c  |  Ctrl + c (Copy)               ;|
;;                     CapsLock + v  |  Ctrl + z (Paste)              ;|
;;                     CapsLock + a  |  Ctrl + a (Select All)         ;|
;;                     CapsLock + y  |  Ctrl + z (Yeild)              ;|
;;                     CapsLock + w  |  Ctrl + Right(Move as [vim: w]);|
;;                     CapsLock + b  |  Ctrl + Left (Move as [vim: b]);|
;;-----------------------------------o---------------------------------o
;CapsLock & z:: Send, ^z                                              ;|
;; clipboard manager
;CapsLock & x::
;/*
;Loop, Files, %A_Desktop%\Ditto*
;{
;    Run, %A_LoopFileLongPath% /open
;    ;FileGetShortcut, %A_LoopFileLongPath%, OutTarget
;    ;Run, %OutTarget% /Open
;    break
;}
;*/
;Send, ^+!v
;return
;
;
;#IfWinActive, ahk_exe Hyper.exe
;CapsLock & c:: Send, ^+c                                              ;|
;;#c:: Send, ^+c
;CapsLock & v:: Send, ^+v                                              ;|
;;#v:: Send, ^+v
;#If
;
;CapsLock & c:: Send, ^c                                              ;|
;CapsLock & v:: Send, ^v                                              ;|
;CapsLock & a:: Send, ^a                                              ;|
;CapsLock & y:: Send, ^y                                              ;|
;CapsLock & w:: Send, ^{Right}                                        ;|
;CapsLock & b:: Send, ^{Left}                                         ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                       CapsLock Media Controller                    ;|
;;-----------------------------------o---------------------------------o
;;                    CapsLock + F1  |  Volume_Mute                   ;|
;;                    CapsLock + F2  |  Volume_Down                   ;|
;;                    CapsLock + F3  |  Volume_Up                     ;|
;;                    CapsLock + F3  |  Media_Play_Pause              ;|
;;                    CapsLock + F5  |  Media_Next                    ;|
;;                    CapsLock + F6  |  Media_Stop                    ;|
;;-----------------------------------o---------------------------------o
;CapsLock & F1:: Send, {Volume_Mute}                                  ;|
;CapsLock & F2:: Send, {Volume_Down}                                  ;|
;CapsLock & F3:: Send, {Volume_Up}                                    ;|
;CapsLock & F4:: Send, {Media_Play_Pause}                             ;|
;CapsLock & F5:: Send, {Media_Next}                                   ;|
;CapsLock & F6:: Send, {Media_Stop}                                   ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                      CapsLock Window Controller                    ;|
;;-----------------------------------o---------------------------------o
;;                     CapsLock + s  |  Ctrl + Tab (Swith Tag)        ;|
;;                     CapsLock + q  |  Ctrl + W   (Close Tag)        ;|
;;   (Disabled)  Alt + CapsLock + s  |  AltTab     (Switch Windows)   ;|
;;               Alt + CapsLock + q  |  Ctrl + Tab (Close Windows)    ;|
;;                     CapsLock + g  |  AppsKey    (Menu Key)         ;|
;;-----------------------------------o---------------------------------o
;;CapsLock & s::Send, ^{Tab}                                           ;|
;;-----------------------------------o                                ;|
;CapsLock & q::                                                       ;|
;if GetKeyState("alt") = 0                                            ;|
;{                                                                    ;|
;    Send, ^w                                                         ;|
;}                                                                    ;|
;else {                                                               ;|
;    Send, !{F4}                                                      ;|
;    return                                                           ;|
;}                                                                    ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & g:: Send, {AppsKey}                                       ;|
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                        CapsLock Self Defined Area                  ;|
;;-----------------------------------o---------------------------------o
;;                     CapsLock + d  |  Alt + d(Dictionary)           ;|
;;                     CapsLock + f  |  Alt + f(Search via Everything);|
;;                     CapsLock + e  |  Open Search Engine            ;|
;;                     CapsLock + r  |  Open Shell                    ;|
;;                     CapsLock + t  |  Open Text Editor              ;|
;;-----------------------------------o---------------------------------o
;CapsLock & d::
;    Run "https://translate.google.cn/#view=home&op=translate&sl=auto&tl=zh-CN&text=%clipboard%"
;return
;
;CapsLock & f::
;    ;WinActive("A") ; sets last found window
;    ;ControlGetFocus, ctrl
;    ;ControlGet, text, Selected,, %ctrl%
;    ;MsgBox, %text%`n%clipboard%
;    ; MsgBox RegExMatch("%clipboard%", "https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)")
;    Clip = %clipboard%
;    if RegExMatch(Clip, "https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)") = 1 {
;        Run %clipboard%
;    } else {
;        Run "http://www.google.com/search?q=%clipboard%"
;    }
;return
;
;/*
;RShift::
;w := DllCall("GetForegroundWindow")
;pid := DllCall("GetWindowThreadProcessId", "UInt", w, "Ptr", 0)
;l := DllCall("GetKeyboardLayout", "UInt", pid)
;if (l = en) {
;    PostMessage 0x50, 0, %ch%,, A
;} else {
;    PostMessage 0x50, 0, %en%,, A
;}
;return
;*/
;
;;---------------------------------------------------------------------o
;
;
;;=====================================================================o
;;                        CapsLock Char Mapping                       ;|
;;-----------------------------------o---------------------------------o
;;                     CapsLock + ;  |  Enter (Cancel)                ;|
;;                     CapsLock + '  |  =                             ;|
;;                     CapsLock + [  |  Back         (Visual Studio)  ;|
;;                     CapsLock + ]  |  Goto Define  (Visual Studio)  ;|
;;                     CapsLock + /  |  Comment      (Visual Studio)  ;|
;;                     CapsLock + \  |  Uncomment    (Visual Studio)  ;|
;;                     CapsLock + 1  |  Build and Run(Visual Studio)  ;|
;;                     CapsLock + 2  |  Debuging     (Visual Studio)  ;|
;;                     CapsLock + 3  |  Step Over    (Visual Studio)  ;|
;;                     CapsLock + 4  |  Step In      (Visual Studio)  ;|
;;                     CapsLock + 5  |  Stop Debuging(Visual Studio)  ;|
;;                     CapsLock + 6  |  Shift + 6     ^               ;|
;;                     CapsLock + 7  |  Shift + 7     &               ;|
;;                     CapsLock + 8  |  Shift + 8     *               ;|
;;                     CapsLock + 9  |  Shift + 9     (               ;|
;;                     CapsLock + 0  |  Shift + 0     )               ;|
;;-----------------------------------o---------------------------------o
;CapsLock & `;:: Send, {Enter}                                        ;|
;CapsLock & ':: Send, =                                               ;|
;CapsLock & [:: Send, ^-                                              ;|
;CapsLock & ]:: Send, {F12}                                           ;|
;;-----------------------------------o                                ;|
;CapsLock & /::                                                       ;|
;Send, ^e                                                             ;|
;Send, c                                                              ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & \::                                                       ;|
;Send, ^e                                                             ;|
;Send, u                                                              ;|
;return                                                               ;|
;;-----------------------------------o                                ;|
;CapsLock & 1:: Send,^{F5}                                            ;|
;CapsLock & 2:: Send,{F5}                                             ;|
;CapsLock & 3:: Send,{F10}                                            ;|
;CapsLock & 4:: Send,{F11}                                            ;|
;CapsLock & 5:: Send,+{F5}                                            ;|
;;-----------------------------------o                                ;|
;CapsLock & 6:: Send,+6                                               ;|
;CapsLock & 7:: Send,+7                                               ;|
;CapsLock & 8:: Send,+8                                               ;|
;CapsLock & 9:: Send,+9                                               ;|
;;---------------------------------------------------------------------o