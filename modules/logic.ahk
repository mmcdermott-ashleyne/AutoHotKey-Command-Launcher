#Requires AutoHotkey v2.0

; ---------- Globals    ----------
global SearchStack := []   ; remembers parent searches when navigating into groups
global PromptTemplateDir := A_ScriptDir "\prompts"

StrJoin(delim, arr*) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? delim : "") v
    return out
}

; ---------- Navigation ----------
IsGroup(obj) => obj.HasOwnProp("children") && obj.children.Length

GoHome() {
    global CurrentNode, NavStack, SearchStack, GL
    CurrentNode := 0
    NavStack := []
    SearchStack := []     ; reset search history at root
    RefreshCrumbs()
    GL.search.Value := ""
    UpdateList("")
}

NavInto(groupObj) {
    global CurrentNode, NavStack, GL, SearchStack
    ; Save current search for parent, then clear for child
    SearchStack.Push(GL.search.Value)
    GL.search.Value := ""
    NavStack.Push(groupObj)
    CurrentNode := groupObj
    RefreshCrumbs()
    UpdateList("")
    GL.search.Focus()
}

NavBack() {
    global CurrentNode, NavStack, GL, SearchStack
    if (NavStack.Length = 0) {
        HideLauncher()
        return
    }

    ; Pop one group
    NavStack.Pop()
    CurrentNode := (NavStack.Length = 0) ? 0 : NavStack[NavStack.Length]

    ; Restore parent search if available
    if (SearchStack.Length > 0)
        GL.search.Value := SearchStack.Pop()
    else
        GL.search.Value := ""

    RefreshCrumbs()
    UpdateList(GL.search.Value)
    GL.search.Focus()
}

NavBackOrClose() {
    global NavStack
    if (NavStack.Length > 0)
        NavBack()
    else
        HideLauncher()
}

RefreshCrumbs() {
    global GL, NavStack
    if (NavStack.Length = 0) {
        GL.crumb.Value := "Home"
        GL.backBtn.Visible := false
    } else {
        path := "Home"
        for n in NavStack
            path .= "  ›  " . n.label
        GL.crumb.Value := path
        GL.backBtn.Visible := true
    }
}

; ---------- Search & listing ----------
SearchChanged() {
    global GL
    val := Trim(GL.search.Value)
    if (val = "?") {
        ShowHelp()
        GL.search.Value := ""
        UpdateList("")
        return
    }
    UpdateList(val)
}

Normalize(s) {
    return StrLower(RegExReplace(Trim(s), "\s+"))
}

BuildBag(strs) {
    bag := Map()
    for s in strs {
        bag[s] := 1
        bag[Normalize(s)] := 1
    }
    return bag
}

GetLevelItems() {
    global Registry, CurrentNode
    items := []
    src := (CurrentNode = 0) ? Registry : CurrentNode.children
    for o in src {
        aliases := o.HasOwnProp("aliases") ? o.aliases : []
        bag := BuildBag(MergeArrays([o.key, o.label], aliases))
        items.Push({ key: o.key
                   , label: o.label
                   , type: IsGroup(o) ? "Group" : "Command"
                   , node: o
                   , matchBag: bag })
    }
    return items
}

MergeArrays(a1, a2) {
    out := []
    for v in a1
        out.Push(v)
    for v in a2
        out.Push(v)
    return out
}


SortArray(arr, compareFunc) {
    out := arr.Clone()
    Loop out.Length {
        i := A_Index
        j := i
        while (j > 1) {
            if (compareFunc.Call(out[j-1], out[j]) <= 0)
                break
            tmp := out[j-1], out[j-1] := out[j], out[j] := tmp
            j -= 1
        }
    }
    return out
}

UpdateList(query) {
    global GL
    q := Trim(query)
    GL.list.Delete()

    if (q = "" || Normalize(q) = "") {
        cnt := 0
        for item in GetLevelItems() {
            icon := (item.type="Group") ? "📁  " : "▶  "
			aliases := (item.node.HasOwnProp("aliases")) ? StrJoin(", ", item.node.aliases*) : ""
			GL.list.Add(, icon . item.label
						  , item.type . (item.type="Command" ? " [" . item.key . "]" : "")
              , aliases)
            cnt++
            if (cnt >= 24)
                break
        }
        if (GL.list.GetCount() > 0)
            GL.list.Modify(1, "Select Focus")
        return
    }

    nq := Normalize(q)
    results := []
    for item in GetLevelItems() {
        hit := false
        if (nq != "") {
            for variant, _ in item.matchBag {
                if (variant != "" && InStr(variant, nq)) {
                    hit := true
                    break
                }
            }
        }
        if (!hit && q != "" && InStr(StrLower(item.label), StrLower(q)))
            hit := true
        if (hit)
            results.Push(item)
    }

    groups := [], cmds := []
    for it in results
        (it.type="Group") ? groups.Push(it) : cmds.Push(it)

    groups := SortArray(groups, (a,b) => StrCompare(a.label, b.label, true))
    cmds   := SortArray(cmds,   (a,b) => StrCompare(a.label, b.label, true))

    ordered := []
    for it in groups
        ordered.Push(it)
    for it in cmds
        ordered.Push(it)

    for it in ordered
        GL.list.Add(, (it.type="Group" ? "📁  " : "▶  ") . it.label, it.type . (it.type="Command" ? " [" . it.key . "]" : ""))

    if (GL.list.GetCount() > 0)
        GL.list.Modify(1, "Select Focus")
}

GetSelectedItem() {
    global GL
    row := GL.list.GetNext()
    if (row = 0)
        return 0
    name := GL.list.GetText(row, 1)
    label := RegExReplace(name, "^\X+\s{2}", "")
    for it in GetLevelItems()
        if (it.label = label)
            return it
    return 0
}


GetItemFromRow(row) {
    global GL
    if (row <= 0)
        return 0
    name := GL.list.GetText(row, 1)              ; e.g., "📁  Links" or "▶  Notepad"
    label := RegExReplace(name, "^\X+\s{2}", "") ; strip icon + two spaces
    for it in GetLevelItems()
        if (it.label = label)
            return it
    return 0
}

; ---------- Execute / parse ----------
LaunchSelected() {
    global GL

    ; Try current selection first
    item := GetSelectedItem()

    ; If nothing selected, but there are results, default to first row
    if (!item && GL.list.GetCount() > 0) {
        ; visually indicate the choice (optional)
        GL.list.Modify(1, "Select")
        item := GetItemFromRow(1)
    }

    if item {
        if (item.type = "Group") {
            NavInto(item.node)
            return
        }
        ; leaf: maybe with arg
        input := GL.search.Value
        res := ParseCommandAndArg(input)
        cmd := res[1], arg := res[2]
        if (item.node.key = cmd && arg != "")
            TryRun(item.node.action, arg)
        else
            TryRun(item.node.action)
        HideLauncher()
        return
    }

    ; No rows at all — fall back to raw execution attempt
    input := GL.search.Value
    res := ParseCommandAndArg(input)
    cmd := res[1], arg := res[2]
    if (cmd = "")
        return
    ExecuteByKeyAtCurrentLevel(cmd, arg)
    HideLauncher()
}

ExecuteByKeyAtCurrentLevel(cmd, arg) {
    items := GetLevelItems()
    ncmd := Normalize(cmd)
    candidates := []
    for it in items {
        if (Normalize(it.node.key) = ncmd || Normalize(it.node.label) = ncmd)
            candidates.Push(it)
    }
    if (candidates.Length = 0) {
        MsgBox("Unknown here: " . cmd . "`nTip: open submenus like 'Links' to see nested items.")
        return
    }
    it := candidates[1]
    if (it.type = "Group") {
        NavInto(it.node)
        return
    }
    if (arg != "")
        TryRun(it.node.action, arg)
    else
        TryRun(it.node.action)
}

TryRun(action, arg := "") {
    ; If we have an arg, try with it first and fall back without.
    if (arg != "") {
        try {
            action.Call(arg)
            return
        } catch as e {
            ; Fall through and try without arg
        }
    }
    try {
        action.Call()
    } catch as e {
        ; If we had no arg and it actually requires one, the call above will fail.
        ; Optionally, you could attempt a retry with arg here if arg <> "".
        MsgBox("Error: " . e.Message, "Launcher", "Icon! Owner")
    }
}

ParseCommandAndArg(raw) {
    text := Trim(raw)
    if (text = "")
        return ["", ""]
    norm := Normalize(text)
    if (SubStr(norm, 1, 4) = "open") {
        target := "open", seen := 0, cutPos := 0
        Loop StrLen(text) {
            ch := SubStr(text, A_Index, 1)
            if (ch != " " && StrLower(ch) = SubStr(target, seen+1, 1)) {
                seen++
                if (seen = 4) {
                    cutPos := A_Index
                    break
                }
            }
        }
        arg := Trim(SubStr(text, cutPos+1))
        return ["open", arg]
    }
    if sp := InStr(text, " ") {
        return [Trim(SubStr(text, 1, sp-1)), Trim(SubStr(text, sp+1))]
    }
    return [text, ""]
}

ShowHelp() {
    txt := "Navigation:`n"
        . "  • Enter to open a group or run a command`n"
        . "  • Esc to go back (or close at Home)`n"
        . "  • Tab to move focus to the list; Shift+Tab to go back`n"
        . "  • Type to filter current level`n"
        . "  • 'open<path-or-url>' works with or without a space`n`n"
        . "Tips:`n"
        . "  • Fuzzy search ignores spaces: 'vs code' == 'vscode'`n"
        . "  • Use Back button or Esc to return from a submenu.`n"
    MsgBox(txt)
}


; ---------- Multiline prompt helper ----------
PromptMultiline(title := "Input", label := "Text:") {
    ; Returns the entered text, or "" if cancelled
    dlg := Gui("+Owner +OwnDialogs", title)
    dlg.MarginX := 12, dlg.MarginY := 10
    dlg.BackColor := 0x202020

    dlg.SetFont("s10", "Segoe UI")
    dlg.AddText("c0xCCCCCC", label)

    ; use a non-conflicting local name (not "edit")
    edt := dlg.AddEdit("w560 h260 -VScroll +Multi Background0x2A2A2A cWhite")

    okBtn     := dlg.AddButton("w80 h26 Default", "OK")
    cancelBtn := dlg.AddButton("x+8 w80 h26", "Cancel")

    picked := ""
    okBtn.OnEvent("Click", (*) => (picked := edt.Value, dlg.Destroy()))
    cancelBtn.OnEvent("Click", (*) => (picked := "", dlg.Destroy()))

    ; Center relative to main window if we have GL + gui; else center on screen
    if (IsSet(GL) && GL.gui) {
        GL.gui.GetPos(&gx, &gy, &gw, &gh)
        dlg.Show("x" (gx + (gw - 600) // 2) " y" (gy + (gh - 330) // 2) " w600 h330")
    } else {
        dlg.Show("w600 h400")
    }

    edt.Focus()
    WinWaitClose("ahk_id " dlg.Hwnd)
    return Trim(picked)
}

; ---------- Fabric exec helper ----------
FabricImprove(promptText) {
    ; temp files for input/output
    inFile  := A_Temp "\fabric_prompt_" A_TickCount ".txt"
    outFile := A_Temp "\fabric_output_" A_TickCount ".txt"

    ; clean up any leftovers (paranoid, but safe)
    try FileDelete(inFile)
    try FileDelete(outFile)

    ; write the prompt exactly as-is (multiline-safe)
    FileAppend(promptText, inFile, "UTF-8")

    fabricExe := "C:\tools\fabric.exe"

    ; Build a hidden cmd:
    ;   type "inFile" | "fabric.exe" --pattern improve_prompt > "outFile" 2>&1
    cmd := Format('cmd.exe /c type "{1}" | "{2}" --pattern improve_prompt > "{3}" 2>&1'
        , inFile, fabricExe, outFile)

    ; Run hidden and wait
    shell := ComObject("WScript.Shell")
    exitCode := shell.Run(cmd, 0, true)  ; 0 = hidden, true = wait

    ; Read output
    if FileExist(outFile) {
        out := FileRead(outFile, "UTF-8")
    } else {
        out := ""
    }

    ; cleanup
    try FileDelete(inFile)
    try FileDelete(outFile)

    if (exitCode != 0) {
        throw Error("fabric exited with code " . exitCode . "`n`nOutput:`n" . out, exitCode)
    }

    return out
}

SelectPromptTemplate(baseDir) {
    ; Ensure the directory exists; if not, fall back to the script directory
    if !DirExist(baseDir)
        baseDir := A_ScriptDir "\prompts"

    ; Let the user pick a template file starting in baseDir.
    ; Mode 3 = existing files only.
    tplFile := FileSelect(
        "3"  ; 3 = existing files, single-select
      , baseDir
      , "Select a prompt template"
      , "Prompt templates (*.txt;*.md;*.prompt)"
    )

    ; If the user cancels, FileSelect() returns an empty string.
    return tplFile
}

PromptFromTemplateAction(*) {
    global GL, PromptTemplateDir

    ; Hide launcher so selection dialogs are not behind it
    if (IsSet(GL) && GL.gui)
        HideLauncher()

    ; Let user choose a template file from PromptTemplateDir
    tplPath := SelectPromptTemplate(PromptTemplateDir)
    if (tplPath = "")
        return  ; user cancelled

    if !FileExist(tplPath) {
        MsgBox("Template file not found:`n" tplPath, "Prompt Template", "Icon!")
        return
    }

    tplText := FileRead(tplPath, "UTF-8")

    params := CollectTemplateParams(tplText)
    if (params.Length = 0) {
        ; No parameters → just copy as-is
        A_Clipboard := tplText
        TrayTip("Prompt copied", "Template copied to clipboard (no parameters).", "Iconi")
        return
    }

    ; Ask for each parameter value
    values := Map()
    for pname in params {
        ib := InputBox(
            "Enter a value for {" pname "}",
            "Prompt Parameter",
            "w420"
        )
        if (ib.Result = "Cancel")
            return  ; abort the entire operation

        values[pname] := ib.Value
    }

    final := ReplaceTemplateParams(tplText, values)
    A_Clipboard := final
    TrayTip("Prompt copied", "Filled prompt copied to clipboard.", "Iconi")
}

CollectTemplateParams(tplText) {
    params := Map()
    list := []

    pos := 1
    while (pos := RegExMatch(tplText, "\{([A-Za-z0-9_]+)\}", &m, pos)) {
        name := m[1]
        if !params.Has(name) {
            params[name] := true
            list.Push(name)
        }
        pos := pos + m.Len
    }
    return list
}

ReplaceTemplateParams(tplText, values) {
    for name, val in values {
        tplText := StrReplace(tplText, "{" name "}", val)
    }
    return tplText
}


ImprovePromptAction(*) {
	HideLauncher()
    ; Ask the user for a multi-line prompt
    txt := PromptMultiline("Improve Prompt", "Prompt:")
    if (txt = "")  ; cancelled or empty
        return

    ; Run: echo {prompt} | fabric --pattern improve_prompt
    try {
		TrayTip("Processing Prompt", "Iconi")
        result := FabricImprove(txt)  ; returns stdout (throws on nonzero)
    } catch as e {
        MsgBox("Fabric error:`n`n" . e.Message, "Fabric", "Icon! Owner")
        return
    }

    A_Clipboard := result
    TrayTip("Copied to clipboard", "Fabric improve_prompt complete.", "Iconi")
}

; Calculates approximate LLM tokens in the clipboard
; Assumes 1 token ≈ 4 characters
TokenCountFromClipboard() {
    ; Hide launcher if present
    if (IsSet(GL) && GL.gui)
        HideLauncher()

    clipText := A_Clipboard
    if (clipText = "")
    {
        MsgBox "Clipboard is empty.`nTokens: 0"
        return 0
    }

    charCount := StrLen(clipText)
    tokenCount := Ceil(charCount / 4)

    ; Apply comma formatting
    charFmt  := AddCommas(charCount)
    tokenFmt := AddCommas(tokenCount)

    MsgBox "Characters: " charFmt "`nEstimated tokens: " tokenFmt
    return tokenCount
}

; -------- Comma-format helper --------
AddCommas(n) {
    s := n . ""   ; convert to string
    while RegExMatch(s, "^\d+(\d{3})", &m)
        s := RegExReplace(s, "(\d+)(\d{3})", "$1,$2")
    return s
}
