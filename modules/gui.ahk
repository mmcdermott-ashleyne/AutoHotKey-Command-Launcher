#Requires AutoHotkey v2.0

; ---- Dark palette ----
guiBg         := 0x202020
inputBg       := 0x2A2A2A
listBg        := 0x262626
listTextCol   := 0xE0E0E0
crumbTextCol  := 0xAAAAAA
btnBg         := 0x2A2A2A
btnTextCol    := 0xFFFFFF
accent        := 0xF0A144
titleTextCol  := 0xF0A144
DEFAULT_WIN_W := 980

global GL := Map()
global LauncherVisible := false

SetFonts() {
    global GL
    GL.gui.SetFont("s10", "Segoe UI")
    GL.search.SetFont("s12", "Segoe UI")
    GL.list.SetFont("s10", "Segoe UI")
    GL.title.SetFont("s12 bold", "Segoe UI")
    GL.header.SetFont("s9", "Segoe UI")
    GL.crumb.SetFont("s9", "Segoe UI")
}

MakeGui() {
    global GL, guiBg, titleTextCol, accent, btnBg, btnTextCol, crumbTextCol, inputBg, listBg, listTextCol, DEFAULT_WIN_W

    GL.gui := Gui("+AlwaysOnTop -Caption +Border +Owner +OwnDialogs", "Launcher")
    GL.gui.MarginX := 14, GL.gui.MarginY := 12
    GL.gui.BackColor := guiBg

    GL.title := GL.gui.AddText("xm ym w200 h24 Center c" . Format("0x{:06X}", titleTextCol)
        . " Background" . Format("0x{:06X}", guiBg), "Command Launcher")
    GL.header := GL.gui.AddText("xm y+4 w200 h4 Background" . Format("0x{:06X}", accent))
    GL.backBtn := GL.gui.AddButton(
        "xm+8 yp+8 w60 h24 Hidden -TabStop Background" . Format("0x{:06X}", btnBg)
        . " c" . Format("0x{:06X}", btnTextCol), "← Back")
    GL.crumb := GL.gui.AddText(
        "x+8 yp+4 w200 h28 c" . Format("0x{:06X}", crumbTextCol)
        . " Background" . Format("0x{:06X}", guiBg), "")
    GL.search := GL.gui.AddEdit(
        "xm yp+28 w200 h40 vSearch -VScroll Background" . Format("0x{:06X}", inputBg)
        . " c" . Format("0x{:06X}", 0xFFFFFF))
    DllCall("UxTheme\SetWindowTheme", "ptr", GL.search.Hwnd, "str", "", "str", "")
    GL.list := GL.gui.AddListView("xm y+12 w200 h330 -Multi", ["Item","Type/Key","Aliases"])
    GL.list.ModifyCol(1,300), GL.list.ModifyCol(2,160), GL.list.ModifyCol(3,260)

    SetFonts()

    SendMessage(0x1001,0,listBg,GL.list.Hwnd)
    SendMessage(0x1024,0,listTextCol,GL.list.Hwnd)
    SendMessage(0x1026,0,listBg,GL.list.Hwnd)
    DllCall("UxTheme\SetWindowTheme", "ptr", GL.list.Hwnd, "str", "", "str", "")

    GL.search.OnEvent("Change",(*)=>SearchChanged())
    GL.list.OnEvent("DoubleClick",(*)=>LaunchSelected())
    GL.backBtn.OnEvent("Click",(*)=>NavBack())
    GL.gui.OnEvent("Escape",(*)=>NavBackOrClose())
    GL.gui.OnEvent("Close",(*)=>HideLauncher())

    GL.winW := DEFAULT_WIN_W

    ; create HWNDs hidden, then layout + center + show
    GL.gui.Show("Hide")
    ApplyLayout(GL.winW)
    CenterGui()
    GL.gui.Show()

    ; keep columns proportional on resize
    GL.gui.OnEvent("Size",(g,mm,w,h)=>ApplyLayout(w))
}

ApplyLayout(winW) {
    global GL
    if (winW <= 0)
        return

    ; widths
    crumbW := winW - 76 ; back button + spacing

    ; Resize controls to new width
    GL.title.Move(,, winW)
    GL.header.Move(,, winW)
    GL.search.Move(,, winW)
    GL.list.Move(,, winW)
    GL.crumb.Move(,, crumbW)

    ; Rebalance columns so they fit without horizontal scroll
    ; Reserve ~28px for LV vertical scrollbar + borders
    usable := winW - 28
    col2   := 180
    col1   := Max(240, Floor(usable * 0.45))
    col3   := Max(160, usable - col1 - col2)

    GL.list.ModifyCol(1, col1)
    GL.list.ModifyCol(2, col2)
    GL.list.ModifyCol(3, col3)

    ; Make the parent window actually grow to fit
    GL.gui.Show("AutoSize")
}

CenterGui() {
    global GL
    ; wait until window handle exists
    if !WinExist("ahk_id " GL.gui.Hwnd) {
        Sleep 30
        if !WinExist("ahk_id " GL.gui.Hwnd)
            return
    }
    WinGetPos(&x,&y,&w,&h,"ahk_id " GL.gui.Hwnd)
    if !(w && h)
        w := GL.winW, h := 480
    x := (A_ScreenWidth - w)//2
    y := (A_ScreenHeight - h)//3
    WinMove(x,y,,,"ahk_id " GL.gui.Hwnd)
}

ShowLauncher() {
    global LauncherVisible
    GoHome()
    ApplyLayout(GL.winW)
    CenterGui()
    GL.gui.Show()
    WinActivate("ahk_id " GL.gui.Hwnd)
    GL.search.Focus()
    LauncherVisible := true
}

HideLauncher() {
    global GL, LauncherVisible
    GL.gui.Hide()
    LauncherVisible := false
}

TogglePalette() {
    global LauncherVisible
    if (LauncherVisible)
        HideLauncher()
    else
        ShowLauncher()
}
