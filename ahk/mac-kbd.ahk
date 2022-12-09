#Persistent
#SingleInstance, Force
#InstallKeybdHook
SendMode Input 
SetTitleMatchMode 2
SetWorkingDir, %A_ScriptDir%
SetBatchLines,-1


OnClipboardChange("FuncOnClipChanged", 1)
global ALT_V_STATUS := 0  ; 1 pressed, 0 released
global clipManager := {}
clipManager.max_cnt := 25
clipManager.pushClip := Func("pushClip")
clipManager.removeClip:= Func("removeClip")
clipManager.clear := Func("clear")
clipManager.find := Func("find")
clipManager.content:= Func("content")
clipManager.label:= Func("label")
clipManager.len:= Func("len")
clipManager.next:= Func("next")
clipManager.previous:= Func("previous")
clipManager.debugStr:= Func("debugStr")
clipManager.clear()

Gui +Resize
Gui, searchPane:New
Gui, searchPane:+LastFound +AlwaysOnTop -Caption +ToolWindow
;Gui, searchPane:+LastFound -Caption +ToolWindow
Gui, searchPane:Add, Edit,  x1 y1 w220 R2 vsearchText gSearchClipAction -VScroll,
Gui, searchPane:Add, Text, x+5 yp w45 r1 vsearchResultCnt 
Gui ,searchPane:Add, ListView, x1  r20 w300 vclipContents, Index|Content


GroupAdd, terminals, ahk_exe ubuntu.exe
GroupAdd, terminals, ahk_exe ubuntu2004.exe
GroupAdd, terminals, ahk_exe ConEmu.exe
GroupAdd, terminals, ahk_exe ConEmu64.exe
GroupAdd, terminals, ahk_exe powershell.exe
GroupAdd, terminals, ahk_exe WindowsTerminal.exe
GroupAdd, terminals, ahk_exe Hyper.exe
GroupAdd, terminals, ahk_exe mintty.exe
GroupAdd, terminals, ahk_exe Cmd.exe
GroupAdd, terminals, ahk_exe box.exe
GroupAdd, terminals, ahk_exe Terminus.exe
GroupAdd, terminals, Fluent Terminal ahk_class ApplicationFrameWindow
GroupAdd, terminals, ahk_class Console_2_Main

GroupAdd, posix, ahk_exe ubuntu.exe
GroupAdd, posix, ahk_exe ubuntu2004.exe
GroupAdd, posix, ahk_exe ConEmu.exe
GroupAdd, posix, ahk_exe ConEmu64.exe
GroupAdd, posix, ahk_exe Hyper.exe
GroupAdd, posix, ahk_exe mintty.exe
GroupAdd, posix, ahk_exe Terminus.exe
GroupAdd, posix, Fluent Terminal ahk_class ApplicationFrameWindow
GroupAdd, posix, ahk_class Console_2_Main
GroupAdd, posix, ahk_exe WindowsTerminal.exe

GroupAdd, ConEmu, ahk_exe ConEmu.exe
GroupAdd, ConEmu, ahk_exe ConEmu64.exe

GroupAdd, ExcPaste, ahk_exe Cmd.exe
GroupAdd, ExcPaste, ahk_exe mintty.exe

GroupAdd, editors, ahk_exe sublime_text.exe
GroupAdd, editors, ahk_exe VSCodium.exe
GroupAdd, editors, ahk_exe Code.exe

GroupAdd, browsers, ahk_exe chrome.exe
GroupAdd, browsers, ahk_exe opera.exe
GroupAdd, browsers, ahk_exe firefox.exe
GroupAdd, browsers, ahk_exe msedge.exe

; Disable Key Remapping for Virtual Machines
; Disable for Remote desktop solutions too
GroupAdd, remotes, ahk_exe VirtualBoxVM.exe
GroupAdd, remotes, ahk_exe mstsc.exe
GroupAdd, remotes, ahk_exe msrdc.exe
GroupAdd, remotes, ahk_exe nxplayer.bin
GroupAdd, remotes, ahk_exe vmconnect.exe
GroupAdd, remotes, ahk_exe RemoteDesktopManagerFree.exe
GroupAdd, remotes, ahk_exe vncviewer.exe
GroupAdd, remotes, Remote Desktop ahk_class ApplicationFrameWindow

; Disabled Edge for now - no ability to close all instances
; GroupAdd, browsers, Microsoft Edge ahk_class ApplicationFrameWindow

GroupAdd, vscode, ahk_exe VSCodium.exe
GroupAdd, vscode, ahk_exe Code.exe

GroupAdd, vstudio, ahk_exe devenv.exe

GroupAdd, intellij, ahk_exe idea.exe
GroupAdd, intellij, ahk_exe idea64.exe

Menu, Tray, Icon, %A_ScriptDir%\icons\mac.ico
return


;~RAlt & F8::
~F2::
  Tooltip, reload %A_scriptName%
  sleep, 700
  Reload
  Tooltip
return
;~Pause::
~F3::
  Suspend
  Pause,,1
return


; #########################################################################
; #############   START OF FINDER MODS FOR FILE MANAGERS   ################
; #########################################################################
; Finder Mods for Windows File Explorer (explore.exe)
#IfWinActive ahk_class CabinetWClass ahk_exe explorer.exe
<!i::Send !{Enter}           ; Cmd+i: Get Info / Properties
<!r::Send {F5}               ; Cmd+R: Refresh view (Not actually a Finder shortcut? But works in Linux file browsers too.)
<!1::Send ^!2                ; Cmd+1: View as Icons
<!2::Send ^!6                ; Cmd+2: View as List (Detailed)
<!3::Send ^!5                ; Cmd+3: View as List (Compact)
<!4::Send ^!1                ; Cmd+4: View as Gallery
<!Up::Send !{Up}             ; Cmd+Up: Up to parent folder
<!Left::Send !{Left}         ; Cmd+Left: Go to prior location in history
<!Right::Send !{Right}       ; Cmd+Right: Go to next location in history
<!Down::                     ; Cmd-Down: Navigate into the selected directory
  For window in ComObjCreate("Shell.Application").Windows
  If WinActive() = window.hwnd
  For item in window.document.SelectedItems {
    window.Navigate(item.Path)
    Return
  }
Return
<![::Send !{Left}            ; Cmd+Left_Brace: Go to prior location in history
<!]::Send !{Right}           ; Cmd+Right_Brace: Go to next location in history
<!<+o::Send ^{Enter}          ; Cmd+Shift+o: Open in new window (tabs not available)
<!Delete::Send ^d      ; Cmd+Delete: Delete / Send to Trash
<!BackSpace::Send ^d   ; Cmd+Delete: Delete / Send to Trash
<!<+n::Send ^+n  ; new folder
<!d::return,                 ; Block the unusual Explorer "delete" shortcut of Ctrl+D, used for "bookmark" in similar apps

$Enter:: 			; Use Enter key to rename (F2), unless focus is inside a text input field. 
  ControlGetFocus, fc, A
  If fc contains Edit,Search,Notify,Windows.UI.Core.CoreWindow1,SysTreeView321
    Send {Enter}
  Else {
    Send {F2}
  }
Return

$BackSpace:: 		; Backspace (without Cmd): Block Backspace key with error beep, unless inside text input field
  ControlGetFocus, fc, A
  If fc contains Edit,Search,Notify,Windows.UI.Core.CoreWindow1
    Send {BackSpace}
  Else {
    SoundBeep, 600, 300
  }
Return

$Delete:: 			; Delete (without Cmd): Block Delete key with error beep, unless inside text input field
  ControlGetFocus, fc, A
  If fc contains Edit,Search,Notify,Windows.UI.Core.CoreWindow1 
    Send {Delete}
  Else  {
    SoundBeep, 600, 300
  }
Return

#IfWinActive
; #########################################################################
; ##############   END OF FINDER MODS FOR FILE MANAGERS   #################
; #########################################################################


; #########################################################################
; ####################     START OF COMMON KEYBINGS       #################
; #########################################################################
#IfWinNotActive ahk_group remotes
; docwise support
<!Up::Send ^{Home}       ;Command–Up Arrow: Move the insertion point to the beginning of the document.
<!<+Up::Send ^+{Home}    ;Shift–Command–Up Arrow: Select the text between the insertion point and the beginning of the document.
<!Down::Send ^{End}      ;Command–Down Arrow: Move the insertion point to the end of the document.
<!<+Down::Send ^+{End}
<!Left::Send {Home}      ;Command–Left Arrow: Move the insertion point to the beginning of the current line.
<!<+Left::Send +{Home}
<!Right::Send {End}
<!<+Right::Send +{End}

#If Not WinActive("ahk_class CabinetWClass ahk_exe explorer.exe")
$<!Backspace::Send +{Home}{Delete} ; Command-Backspace, delete current point to the beginning of the current line.
<#Backspace::Send ^{Backspace}  ; Option-Backspace, delete current point to beginning of word
#If

; wordwise support
<#b:: Send ^{Left}
<#f:: Send ^{Right}

; TODO 
<!+-::Send ^+-  ; Decrease the size 
<!+=::Send ^+=  ; Increase the size 
; Close Apps 
<!q::Send !{F4}
; Minimize specific Window
;<!m::WinMinimize, A
<!m::Send #m
<!<+m::Send #+m  ; restore last minimized window

<!=:: 
  if (WinActive("ahk_class Progman") || WinActive("ahk_Class DV2ControlHost") || (WinActive("Start") && WinActive("ahk_class Button")) || WinActive("ahk_class Shell_TrayWnd")) ; disallows minimizing things that shouldn't be minimized, like the task bar and desktop
    return
  WinGet, MinMax, MinMax, A
  If (MinMax = 1)
    WinRestore, A
  else {

    WinMaximize, A
  }
return

; Option-Command-M Minimize all but Active Window
<#<!m::
  WinGet, winid ,, A
  WinMinimizeAll
  WinActivate ahk_id %winid%
return

; Command-H: Hide the windows of the front app. To view the front app but hide all other apps, press Option-Command-H.
; hide all instances of active Program
<!h::
  WinGetClass, class, A
  WinGet, AllWindows, List
  loop %AllWindows% {
    WinGetClass, WinClass, % "ahk_id " AllWindows%A_Index%
    if(InStr(WinClass,class)){
      WinMinimize, % "ahk_id " AllWindows%A_Index%
    }
  }
return

; Option-Command-H hide all but active program
<#<!h::
  WinGetClass, class, A
  WinMinimizeAll
  WinGet, AllWindows, List
  loop %AllWindows% {
    WinGetClass, WinClass, % "ahk_id " AllWindows%A_Index%
    if(InStr(WinClass,class)){
      WinRestore, % "ahk_id " AllWindows%A_Index%
    }
  }
return

; Show Desktop
<!F3::Send #d

; Full Screenshot
<!<+3::Send {PrintScreen}

; Region Screenshot
<!<+4::Send #+{S}
#If
; #########################################################################
; ####################       END OF COMMON KEYBINGS       #################
; #########################################################################


; #########################################################################
; ################    START OF NONE-Terminal KEYBINGS       ###############
; #########################################################################

#If Not WinActive("ahk_group terminals") and Not WinActive("ahk_group remotes")
; emacs style
<^a::Send {Home}
<^b::Send {Left}
<^d::Send {Delete} ;Control-D: Delete the character to the right of the insertion point. Or use Fn-Delete.
<^e::Send {End}
<^f::Send {Right}
<^h::Send {BS} ;Control-H: Delete the character to the left of the insertion point. Or use Delete.
<^k::Send +{End}{Backspace}
<^n::Send {Down}
<^p::Send {Up}
<^v::Send {PgDn}
<^u::Send {PgUp}
<^w::Send ^{BS}

; the function can return a non-zero integer to prevent subsequent functions from being called.
StopOnClipboardChange(Type) {
  return 1
}
;; copyright https://jacks-autohotkey-blog.com/2016/03/23/autohotkey-windows-clipboard-techniques-for-swapping-letters-beginning-hotkeys-part-9/
<^t:: ; swap character
  ;OnClipboardChange("StopOnClipboardChange", -1) ; -1 = Call the function before any previously registered functions.
  ;OnClipboardChange("FuncOnClipChanged", 0) ; -1 = Call the function before any previously registered functions.
  OldClipboard := ClipboardAll
  Clipboard = ;clears the Clipboard
  SendInput {Left}+{Right 2}
  SendInput, ^x
  ClipWait 0 ;pause for Clipboard data
  If ErrorLevel = 0
  {
    SwappedLetters := SubStr(Clipboard,2) . SubStr(Clipboard,1,1)
    SendInput, %SwappedLetters%
    SendInput {Left}
  }
  Clipboard := 
  Clipboard := OldClipboard
  ClipWait,2,1
  ;OnClipboardChange("StopOnClipboardChange", 0)
  ;OnClipboardChange("FuncOnClipChanged", 0) ; -1 = Call the function before any previously registered functions.
Return

<#t:: ; swap word
  ;KeyWait, Lwin
  ;OnClipboardChange("StopOnClipboardChange", -1)
  OldClipboard := ClipboardAll
  Clipboard = ;clears the Clipboard
  SendInput ^{Left}+^{Right 2}
  SendInput, ^x
  ClipWait 0 ;pause for Clipboard data
  If ErrorLevel = 0
  {
    SwappedWords := RegExReplace(Clipboard,"([\w']+\w)(\S?\S?\S?)(\s.*\s|\s+)([""|']{0,2})([\w']+\w)","$5$2$3$4$1")
    SendInput, %SwappedWords%
    SendInput ^{Left}
  }
  Clipboard := 
  Clipboard := OldClipboard
  ClipWait,2,1
  ;OnClipboardChange("StopOnClipboardChange", 0)
Return


<!a::Send ^a ; select all
;<!c::Send ^c
<!f::Send ^f ; find
<!n::Send ^n ; new window
<!y::Send ^y ; Redo
<!o::Send ^o ; open
<!p::Send ^p ; print
<!r::Send ^r ; refresh
; <!s::Send ^s ; save
<!t::Send ^t ; new tab, TODO: swap character when in edit 
; <!v::Send ^v ; paste
<!w::Send ^w ; close tab
;<!x::Send ^x ; cut
<!z::Send ^z ; undo

<!<+t::Send ^+t
#If
; #########################################################################
; ################    END OF NONE-Terminal KEYBINGS       #################
; #########################################################################

; #########################################################################
; ################    START OF Browsers KEYBINGS       ####################
; #########################################################################
#IfWinActive ahk_group browsers

; block the alt key
Alt::
  KeyWait, Alt
return

LAlt Up::
  if (A_PriorKey = "Alt") {
    return
  }
return

<!l::Send ^l  ; taskbar

;Switch tabs: jump directly to the first tab, second tab, etc.
<!1::Send ^1
<!2::Send ^2
<!3::Send ^3
<!4::Send ^4
<!5::Send ^5
<!6::Send ^6
<!7::Send ^7
<!8::Send ^8
; Jump to the last tab	
<!9::Send ^9

; Zoom to Actual Size	
<!0::Send ^0
; Page Navigation
<![::send !{Left}                ; Go to prior page in history
<!]::send !{Right}               ; Go to next page in history
;Tab Navigation
;win11 change input method lang, see https://www.windowsdigitals.com/how-to-disable-alt-shift-or-change-it-to-ctrl-shift-in-windows-11/
$<!<+[::send ^{PgUp}               ; Go to prior tab (left)
$<!<+]::send ^{PgDn}               ; Go to next tab (right)
;<!Left::send ^{PgUp}            ; Go to prior tab (left)
;<!Right::send ^{PgDn}           ; Go to next tab (right)
;<!q::send {Alt Down}f{Alt Up}x   ; exit all windows
; Dev Tools
<!<#i::send {Ctrl Down}{Shift Down}i{Shift Up}{Ctrl Up}
<!<#j::send {Ctrl Down}{Shift Down}j{Shift Up}{Ctrl Up}

;Open Link in New Tab (in the background)
<!LButton::
  Send {Control Down}
  MouseClick, left
  Send {Control Up}
return
;Open Link in New Tab (in the foreground)
<!<+LButton::
  Send {Control Down}{Shift Down}
  MouseClick, left
  Send {Control Up}{Shift Down}
return
;Open Link in New Window	
<!<#<+LButton::
  Send {Shift Down}
  MouseClick, left
  Send {Shift Down}
return
; #########################################################################
; ##################    END OF Browsers KEYBINGS       ####################
; #########################################################################

; Open preferences
#IfWinActive ahk_exe firefox.exe
<!,::send, {Ctrl Down}t{Ctrl Up}about:preferences{Enter}
<!<+n::send ^+p
#IfWinActive ahk_exe chrome.exe
<!,::send {Alt Down}e{Alt Up}s{Enter}
#IfWinActive ahk_exe msedge.exe
<!,::send {Alt Down}e{Alt Up}s{Enter}
#IfWinActive ahk_exe opera.exe
<!,::send {Ctrl Down}{F12}{Ctrl Up}
#If



; #########################################################################
; ##################    START OF Terminals KEYBINGS       #################
; #########################################################################
#IfWinActive ahk_group terminals

; ===== tmux keybings
<#;::Send !;  ; prefix
<#-::Send !-  ; h pane
<#s::Send !s  ; select session
<#z::Send !z  ; zoom pane
<#\::Send !\  ; v pane
<#=::Send !=  ; even pane
; select pane
<^1:: Send !;1
<^2:: Send !;2
<^3:: Send !;3
<^4:: Send !;4
<^5:: Send !;5
<^6:: Send !;6
<^7:: Send !;7
<^8:: Send !;8
<^9:: Send !;9

; <!c::Send ^{Insert}
; <!v::Send +{Insert}

<!<+i:: Send, ^+w ; close window
<![:: Send, ^+{Tab}
<!]:: Send, ^{Tab}
<!t:: Send, ^+t

;Switch tabs: jump directly to the first tab, second tab, etc.
<!1::Send ^!1
<!2::Send ^!2
<!3::Send ^!3
<!4::Send ^!4
<!5::Send ^!5
<!6::Send ^!6
<!7::Send ^!7
<!8::Send ^!8
<!9::Send ^!9
<!,::Send ^,
#If
; #########################################################################
; ####################    END OF Terminals KEYBINGS       #################
; #########################################################################


;=====================================================================o
;                       Clipboard Manager                         ;|
;---------------------------------------------------------------------o

;#If (!GetKeyState("LAlt", "P")) and (CurAction == "Paste")
;<!v:: 
;  ;SetClipboardData(ClipContents[ClipIndex])
;  Send ^v
;  return
;#If CurAction == "Cancel"
;<!x:: DeleteAction()
;#If CurAction == "Delete"
;<!x:: DeleteAllAction()
;#If SearchPaneOn == 1
;<!s:: SearchHide()
;#If CurAction
;<!v:: IterForwardAction()
;<!c:: IterBackAction()
;<!x:: CancelAction()
;<!s:: SearchShow()
;#If
; normal mode
;Hotkey, $<!v, StartClipMode, On
;HotKey, $<!v Up, EndClipMode, On


pushClip(this) {
  OnClipboardChange("FuncOnClipChanged", 0)
  content := SaveClipboard()
  if Clipboard
    label := TrimStr(Clipboard)
  else
    label := "_RawData_"

  find_index := this.find(content)
  if (find_index) {
    this.removeClip(find_index)
  }
  if (this.len() >= this.max_cnt) {
    this.removeClip(this.len())
  }

  clip := {}
  clip.label := label
  clip.content := content
  this.contents.InsertAt(1, clip)
  if (find_index) {
    return find_index
  } else {
    return 0
  }
}

; default this.index
removeClip(this, index:=0) {
  if (index) {
    this.contents.removeAt(index)
  } else {
    this.contents.removeAt(this.index)
  }
}

len(this) {
  return this.contents.Length()
}

next(this) {
  this.index++
  if (this.index > this.len())
    this.index := 1
  return this.index
}
previous(this) {
  this.index--
  if (this.index < 1)
    this.index := this.len()
  return this.index
}

; start from 1
find(this, ByRef content) {
  ; clip := SaveClipboard()
  ;return clip == this.content(index)
  for index, element in this.contents {
    if (CompareContentObject(content, this.content(index)))
      return index
  }
  return 0
}

CompareContentObject(objA,objB) {
  for property,value in objA {	
    if(objB[property] != value) {
      return false
    }
  }
  return true
}

; default this.index
content(this, index:=0) {
  if index > 0
    return this.contents[index].content
  else 
    return this.contents[this.index].content
}

; default this.index
label(this, index:=0) {
  if index > 0
    return this.contents[index].label
  else 
    return this.contents[this.index].label
}
clear(this) {
  this.contents := []
  this.index := 0
  this.action := "Paste"
}

debugStr(this) {
  msg := ""
  for index, element in this.contents {
    msg := msg . "`n" . index . " " . element.label . " " . element.content
  }
  return msg
}


$<!s::
  OriginalSaveAction:
  Send ^s ; save
return

$<!c::
  OriginalCopyAction:
  OnClipboardChange("FuncOnClipChanged", 1)
  If WinActive("ahk_group terminals")
    send ^{Insert}
  else
    send ^c
  ClipWait,2,1
  ;OnClipboardChange("FuncOnClipChanged", 0)
return

$<!x::
  OriginalCutAction:
  send ^x
return

$<!v::
  StartClipMode:
  ;Critical
  ALT_V_STATUS := 1
  ToolTip, start clip mode
  OnClipboardChange("FuncOnClipChanged", 0)
  Hotkey, $<!s, SearchShow, On
  Hotkey, $<!c, IterBackAction, On
  Hotkey, $<!v, IterForwardAction, On
  Hotkey, $<!x, CancelAction, On
  clipManager.index := 0
  IterForwardAction()
  ;tooltip, paste on
return

$!v Up::
  EndClipMode:
  KeyWait LAlt
  Critical
  OnClipboardChange("FuncOnClipChanged", 0)

  if (clipManager.action == "Paste") || (clipManager.action == "SearchComplete") 
  {
    if (clipManager.index) {
      ToolTip, % "Paste clip " . clipManager.index . "/" . clipManager.len() . ": " . clipManager.label() . "`n" . clipManager.DebugStr()
      SetClipboardData(clipManager.content())
    } else {
      ToolTip, % "no history, Paste origin clip `n" . Clipboard
    }

    if WinActive("ahk_group terminals")
      Send +{Insert}
    else
      Send ^v

    ClipWait,2,1
  } else if (clipManager.action == "Cancel") {
    ToolTip, Canceled
  } else if (clipManager.action == "Delete") {
    ToolTip, % "Delete clip " . clipManager.index . "/" . clipManager.len() . ": " . clipManager.label() . "`n" . clipManager.DebugStr()
    clipManager.removeClip()
  } else if (clipManager.action == "DeleteAll") {
    ToolTip, % "Delete ALL clip " . clipManager.len() "`n" . clipManager.DebugStr()
    clipManager.clear()
  } 

  if (clipManager.action == "SearchShow") {
    ;SearchHide()
    Hotkey, $<!s, SearchHide, On

    Hotkey, $<!c, OriginalCopyAction, On
    Hotkey, $<!v, StartClipMode, On
    HotKey, $<!v Up, EndClipMode, On
    Hotkey, $<!x, OriginalCutAction, On
  } else {
    ;Hotkey, $<!s, SearchShow, Off
    ;Hotkey, $<!c, IterBackAction, Off
    ;Hotkey, $<!v, IterForwardAction, Off
    ;Hotkey, $<!x, CancelAction, Off

    Hotkey, $<!s, OriginalSaveAction, On
    Hotkey, $<!c, OriginalCopyAction, On
    Hotkey, $<!v, StartClipMode, On
    HotKey, $<!v Up, EndClipMode, On
    Hotkey, $<!x, OriginalCutAction, On
  }
  OnClipboardChange("FuncOnClipChanged", 1)
  SetTimer, RemoveToolTip, -2000
  ;ToolTip, Clip Mode Off, paste
  ALT_V_STATUS := 0
return

RestoreCopyPasteAction:
return

; 0 = Clipboard is now empty.
; 1 = Clipboard contains something that can be expressed as text (this includes files copied from an Explorer window).
; 2 = Clipboard contains something entirely non-text such as a picture.
FuncOnClipChanged(Type) {
  Critical 
  if (Type == 0)
    return
  if (Type == 1) {
    clip := TrimStr(Clipboard)
    if !clip
      return
  }

  find_index := clipManager.pushClip()
  len := clipManager.len()
  label := clipManager.label(find_index)
  if (!find_index) {
    tooltip_msg = Copy Data of %find_index%/%len%
  } else if (find_index == 1){
    tooltip_msg = Same Data of %find_index%/%len%
  } else {
    tooltip_msg = TopMost Data of %find_index%/%len%
  }
  ToolTip, %  tooltip_msg . "`n" . clipManager.debugStr()
  SetTimer, RemoveToolTip, -3000
}

IterForwardAction() {
  Critical 
  if (!clipManager.len()) {
    ToolTip, % "no history, use current clip:`n" . Clipboard
    ;SetTimer, RemoveToolTip, -1400
    return
  }
  OnClipboardChange("FuncOnClipChanged", 0)

  curr_index := clipManager.next()
  clipManager.action := "Paste"
  SetTimer, RemoveToolTip, Off

  ToolTip, %  "Clip " . curr_index . " of " .  clipManager.len() . ": " . clipManager.label(curr_index) . "`n" . clipManager.debugStr()

}


IterBackAction() {
  Critical 
  if (!clipManager.len()) {
    ToolTip, % "no history, use current clip:`n" . Clipboard
    ;SetTimer, RemoveToolTip, -1400
    return
  }
  OnClipboardChange("FuncOnClipChanged", 0)

  curr_index := clipManager.previous()
  clipManager.action := "Paste"
  SetTimer, RemoveToolTip, Off

  ToolTip, %  "Clip " . curr_index . " of " .  clipManager.len() . ": " . clipManager.label(curr_index) . "`n" . clipManager.debugStr()
}

SearchShow() {
  Gui, searchPane:default
  Gui, searchPane:ListView, clipContents
  GuiControl, -Redraw, clipContents
  LV_Delete()
  clip_cnts := clipManager.len()
  Loop %clip_cnts% {
    LV_Add("",  A_Index,  clipManager.label(A_Index))
  }
  GuiControl, +Redraw, clipContents
  LV_ModifyCol()  ; Auto-size each column to fit its contents.
  ;LV_ModifyCol() ; Make the Size column at little wider to reveal its header.
  clipManager.action := "SearchShow"
  GuiControl, searchPane:, SearchResultCnt, % LV_GetCount()
  ;Gui Show
  Gui, searchPane:show

  Hotkey, $<!s, SearchHide, On
  loop 9 {
    Hotkey, $<!%A_index%, SelectClipByHotkey, On
  }
  ;HotKey, $<!v Up, EndClipMode, Off

  ;Hotkey, $<!v Up, EndClipMode, Off
  ;Hotkey, $<!c, OriginalCopyAction, On
  ;Hotkey, $<!v, StartClipMode, On
  ;HotKey, $<!v Up, EndClipMode, On
  ;Hotkey, $<!x, OriginalCutAction, On

}

SelectClipByHotkey() {
  Critical
  _index := Substr(A_ThisHotkey, 3)
  Gui, searchPane:default
  Gui, searchPane:ListView, clipContents
  if (_index <= LV_GetCount()) && (_index >= 1) {
    CompleteSelection(_index)
  } else {
    ToolTip, % "select " . _index . " error, lv cnt: " . LV_GetCount()
  }
}

CompleteSelection(index) {
  Critical
  LV_GetText(clip_index, index, 1)
  GuiControl, searchPane:, searchText, 

  ToolTip, % "select clip no " . clip_index . " from index " . index
  ;gosub, EndClipMode
  clipManager.index := clip_index
  clipManager.action := "SearchComplete"

  loop 9 {
    Hotkey, $<!%A_index%, SelectClipByHotkey, Off
  }

  GuiControl, searchPane:, searchText, 

  Gui, searchPane:hide
  if ALT_V_STATUS = 0
    gosub, EndClipMode
}

SearchHide() {
  Gui, searchPane:hide
  clipManager.action := "SearchHide"
  ;Hotkey, $<!v Up, EndClipMode, Off

}

CancelAction() {
  ToolTip, Cancel Operation`nRelease LAlt to Confirm
  clipManager.action := "Cancel"
  Hotkey, $<!x, DeleteAction, On
}

DeleteAction() {
  Tooltip, % "Delete Current Clip:" . clipManager.label() . "`nRelease LAlt to Confirm`nPress X Again to Delete All"
  clipManager.action := "Delete"
  Hotkey, $<!x, DeleteAllAction, On
}

DeleteAllAction() {
  Tooltip, Delete ALL Clips`nRelease LAlt to Confirm`nPress X Again to Cancel
  clipManager.action := "DeleteAll"
  Hotkey, $<!x, CancelAction, On
}

RemoveToolTip:
ToolTip
return

TrimStr(str) {
  return trim(str, " `t`r`n")
}


SearchClipAction(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="") {
  if (GuiEvent != "Normal") {
    return
  }

  Gui, searchPane:default
  ;Gui, searchPane:Edit, searchClip
  GuiControlGet, searchText, searchPane:
  if searchText contains `n 
  {
    ;Tooltip, "search with enter"
    DoSearchClip()

    Gui, searchPane:ListView, clipContents
    if (LV_GetCount() > 0) {
      CompleteSelection(1)
    } 
  } else {
    SetTimer, DoSearchClip, -500
  }
}

DoSearchClip() {
  Gui, searchPane:default
  Gui, searchPane:ListView, clipContents
  GuiControl, -Redraw, clipContents
  LV_Delete()
  clip_cnts := clipManager.len()

  ;global SearchClip
  GuiControlGet, searchText, searchPane:
  search_terms := StrSplit(SearchText, " ", " `t`n")
  ;ToolTip, % "input " . SearchClip . " : " . search_terms[1]

  Loop %clip_cnts% {
    find := 1
    clip := clipManager.label(A_Index)
    For _idx, _term in search_terms {
      if InStr(clip, _term) = 0 {
        find := 0
        break
      }
    }

    if not find
      continue
    LV_Add("",  A_Index,  clip)
  }
  GuiControl, searchPane:, searchResultCnt, % LV_GetCount()

  GuiControl, +Redraw, clipContents
  LV_ModifyCol()  ; Auto-size each column to fit its contents.
}

SaveClipboard()  {
  static CF_ENHMETAFILE := 14
  clipContent := {}, clipFormat := 0

  DllCall("OpenClipboard", Ptr, 0)
  while clipFormat := DllCall("EnumClipboardFormats", UInt, clipFormat)  {
    hMem := DllCall("GetClipboardData", UInt, clipFormat, Ptr)
    if (clipFormat = CF_ENHMETAFILE)  {
      size := DllCall("GetEnhMetaFileBits", Ptr, hMem, UInt, 0, Ptr, 0)
      clipContent.SetCapacity(clipFormat, size)
      DllCall("GetEnhMetaFileBits", Ptr, hMem, UInt, size, Ptr, clipContent.GetAddress(clipFormat))
    }
    else  {
      pMem := DllCall("GlobalLock", Ptr, hMem, Ptr)
      size := DllCall("GlobalSize", Ptr, pMem)
      clipContent.SetCapacity(clipFormat, size)
      DllCall("RtlMoveMemory", Ptr, clipContent.GetAddress(clipFormat), Ptr, pMem, Ptr, size)
      DllCall("GlobalUnlock", Ptr, hMem)
    }
  }
  DllCall("CloseClipboard")
  Return clipContent
}

SetClipboardData(clipContent)  {
  static CF_ENHMETAFILE := 14, flags := (GMEM_ZEROINIT := 0x40) | (GMEM_MOVEABLE := 0x2)
  DllCall("OpenClipboard", Ptr, 0)
  DllCall("EmptyClipboard")
  for clipFormat in clipContent  {
    addr := clipContent.GetAddress(clipFormat), size := clipContent.GetCapacity(clipFormat)
    if (clipFormat = CF_ENHMETAFILE)  {
      hData := DllCall("SetEnhMetaFileBits", UInt, size, Ptr, addr, Ptr)
      DllCall("SetClipboardData", UInt, CF_ENHMETAFILE, Ptr, hData, Ptr)
      DllCall("DeleteEnhMetaFile", Ptr, hData)
    }
    else  {
      hMem := DllCall("GlobalAlloc", UInt, flags, Ptr, size, Ptr)
      pMem := DllCall("GlobalLock", Ptr, hMem, Ptr)
      DllCall("RtlMoveMemory", Ptr, pMem, Ptr, addr, Ptr, size)
      DllCall("SetClipboardData", UInt, clipFormat, Ptr, pMem, Ptr)
      DllCall("GlobalUnlock", Ptr, hMem)
    }
  }
  DllCall("CloseClipboard")
}
