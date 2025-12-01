#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; ===== includes =====
#Include modules\commands.ahk   ; BuildRegistry()
#Include modules\gui.ahk        ; MakeGui(), CenterShow(), Show/Hide/Toggle, SetFonts()
#Include modules\logic.ahk      ; Navigation, search, execute, helpers

; ===== globals & state =====
global GL := { gui: 0, search: 0, list: 0, header: 0, crumb: 0, backBtn: 0 }
global LauncherVisible := false
global NavStack := []          ; breadcrumbs stack
global CurrentNode := 0        ; 0 = root (Registry)
global AcceptsArgCache := Map()
global Registry := BuildRegistry()

; ===== init =====
MakeGui()
GoHome()

; ===== hotkeys =====
!CapsLock::TogglePalette()

#HotIf LauncherVisible
Enter::LaunchSelected()
F1::ShowHelp()
Esc::NavBackOrClose()
+Tab::NavBack()  ; Shift+Tab = Back
#HotIf
