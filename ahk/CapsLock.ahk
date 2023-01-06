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
#Persistent
#InstallKeybdHook
#SingleInstance force
SendMode Input 
SetTitleMatchMode 2
SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1
DetectHiddenText On

#Include, lib/AccModel.ahk
#Include, lib/HyperSearch.ahk


global Mouse_HJKL := false
global TMouse_DPIRatio :=  A_ScreenDPI / 96
global mouseSimulation := new AccModel2D(Func("MouseSimulation"), 0.1, TMouse_DPIRatio * 120 * 2 * 1)

; 解决多屏 DPI 问题
DllCall("Shcore.dll\SetProcessDpiAwareness", "UInt", 2)


~F2::Reload
~F3::
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
s:: 
  Mouse_HJKL := !Mouse_HJKL
  ToolTip, Mouse_HJKL status %Mouse_HJKL%
  SetTimer, RemoveToolTip, -1500
  if Mouse_HJKL {
    ;SetTimer, ToggleMouseHJKL, -5000
  }
return

ToggleMouseHJKL:
Mouse_HJKL := false
ToolTip, Mouse_HJKL status %Mouse_HJKL%
SetTimer, RemoveToolTip, -1500
return

s & d::
  SendEvent  {Blind}{LButton down}
  SendEvent  {Blind}{LButton up}
return

s & f::
  SendEvent  {Blind}{RButton down}
  KeyWait, f
  SendEvent  {Blind}{RButton up}
return

; caps + h/k/j/l              ------- direction navigator, ctrl alt compatible
*h::
  if Mouse_HJKL {
    mouseSimulation.PressLeft("h")
    SetTimer, ToggleMouseHJKL, -5000
    return
  }

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
  if Mouse_HJKL {
    mouseSimulation.PressDown("j")
    SetTimer, ToggleMouseHJKL, -5000
    return
  }
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
  if Mouse_HJKL {
    mouseSimulation.PressUp("k")
    SetTimer, ToggleMouseHJKL, -5000
    return
  }
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
  if Mouse_HJKL {
    mouseSimulation.PressRight("l")
    SetTimer, ToggleMouseHJKL, -5000
    return
  }
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
a & c:: Run calc.exe   ; -- 
a & b:: Run Chrome.exe   ; -- todo, for uwp
a & o:: Send ^!z ; qq
a & h:: Run https://quickref.me/%clipboard%



; windows management
; space --- alwas on top
Space::
  ;WinGetTitle, activeWindow, A
  WinGet, windowStyle, ExStyle, A
  isWindowAlwaysOnTop := if (windowStyle & 0x8) ? true : false ; 0x8 is WS_EX_TOPMOST.
  if !isWindowAlwaysOnTop
    notificationMessage := "always on TOP."
  else
    notificationMessage := "NO longer always on top."
  Winset, AlwaysOnTop, , A
  WinGetPos, , , width, height, A
  CoordMode, ToolTip, Window
  ToolTip, %notificationMessage%, % width/3, % height/3
  SetTimer, RemoveToolTip, -4000
return

;=====================================================================o
;                            CapsLock Editor                         ;|
;-----------------------------------o---------------------------------o

d::
  if (Mouse_HJKL) {
    SendEvent  {Blind}{LButton down}
    KeyWait, d
    SendEvent  {Blind}{LButton up}
    return
  }
  ;Run "https://translate.google.com/#view=home&op=translate&sl=auto&tl=zh-CN&text=%clipboard%"
   ret := Translate(clipboard, "cgdict")
   tooltip, % ret
   SetTimer, RemoveToolTip, -5000
return
f::
  if (Mouse_HJKL) {
    SendEvent  {Blind}{RButton down}
    KeyWait, f
    SendEvent  {Blind}{RButton up}
    return
  }
  HyperSearch(clipboard)
  ;Clip := trim(clipboard)
  ;if RegExMatch(Clip, "https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)") = 1 {
  ;  Run %Clip%
  ;} else {
  ;  Run "http://www.google.com/search?q=%Clip%"
  ;}L
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


CursorHandleGet()
{
    VarSetCapacity(PCURSORINFO, 20, 0) ;为鼠标信息 结构 设置出20字节空间
    NumPut(20, PCURSORINFO, 0, "UInt") ;*声明出 结构 的大小cbSize = 20字节
    DllCall("GetCursorInfo", "Ptr", &PCURSORINFO) ;获取 结构-光标信息
    if (NumGet(PCURSORINFO, 4, "UInt") == 0 ) ;当光标隐藏时，直接输出特征码为0
    Return 0
    Return NumGet(PCURSORINFO, 8)
}

CursorShapeChangedQ()
{
    static lA_Cursor := CursorHandleGet()
    if (lA_Cursor == CursorHandleGet()) {
        Return 0
    }
    lA_Cursor := CursorHandleGet()
    Return 1
}

; copy & modify from https://github.com/snolab/CapsLockX
MouseSimulation(dx, dy, State){
    if (State != "Move") {
        return
    }
    ; Shift 减速 =1
    if (GetKeyState("Shift", "P")) {
        sleep 100
        dx := dx == 0 ?  0 : (dx > 0 ? 1 : -1 )
        dy := dy == 0 ?  0 : (dy > 0 ? 1 : -1 )
    }
        ; 支持64位AHK！
    ;tooltip, moving %dx% %dy%
    ;MouseMove, %dx%, %dy%, 0, R
    SendInput_MouseMove(dx, dy)
    
    ; TODO: 撞到屏幕边角就停下来
    ; if(TMouse_StopAtScreenEdge )
    ; MouseGetPos, xb, yb
    ; MouseSimulation.横速 *= dx && xa == xb ? 0 : 1
    ; MouseSimulation.纵速 *= dy && ya == yb ? 0 : 1
    
    
    ; 在各种按钮上减速，进出按钮时减速80%
    if (CursorShapeChangedQ()) {
        MouseSimulation.LateralSpeed *= 0.2
        MouseSimulation.LongitudeSpeed *= 0.2
    }
}

SendInput_MouseMove(x, y)
{
    ; (20211105)终于支持64位了
    ; [SendInput function (winuser.h) - Win32 apps | Microsoft Docs]( https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput )
    ; [INPUT (winuser.h) - Win32 apps | Microsoft Docs]( https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-input )
    ; [MOUSEINPUT (winuser.h) - Win32 apps | Microsoft Docs]( https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-mouseinput )
    size := A_PtrSize+4*4+A_PtrSize*2
    VarSetCapacity(mi, size, 0)
    NumPut(x, mi, A_PtrSize, "Int")   ; int dx
    NumPut(y, mi, A_PtrSize+4, "Int")  ; int dy
    NumPut(0x0001, mi, A_PtrSize+4+4+4, "UInt")   ; DWORD dwFlags MOUSEEVENTF_MOVE
    DllCall("SendInput", "UInt", 1, "Ptr", &mi, "Int", size )
}
