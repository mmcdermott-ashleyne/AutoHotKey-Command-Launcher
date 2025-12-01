#Requires AutoHotkey v2.0

BuildSqlCommands() {
    return [
        { key: "sqlsum", label: "Wrap Columns with SUM()", action: (*) => WrapColumnsWithSum(), aliases: ["sum"] },
        { key: "sqlin",   label: "Make SQL IN (...) list",  action: (*) => MakeSqlInList(),     aliases: ["in"] }
    ]
}

TryHideLauncher() {
    try {
        HideLauncher()
    } catch {
        ; no-op
    }
}

; Comma-first SUM wrapper
WrapColumnsWithSum() {
    txt := A_Clipboard
    if !Trim(txt) {
        MsgBox("Clipboard is empty.", "Launcher")
        TryHideLauncher()
        return
    }
    items := StrSplit(RegExReplace(txt, "[,`r`n]+", "`n"), "`n", "`r`n")

    lines := []
    for p in items {
        col := Trim(p)
        if (col = "")
            continue
        lines.Push("sum(" col ") as " col)
    }

    out := ""
    for i, line in lines
        out .= (i = 1 ? "    " : "  , ") . line . "`n"

    A_Clipboard := RTrim(out, "`n")
    TryHideLauncher()
}

; Build: in ('a','b','c') with quote-escaping
MakeSqlInList() {
    txt := A_Clipboard
    if !Trim(txt) {
        MsgBox("Clipboard is empty.", "Launcher")
        TryHideLauncher()
        return
    }

    items := StrSplit(RegExReplace(txt, "[,`r`n]+", "`n"), "`n", "`r`n")
    vals := []
    for raw in items {
        v := Trim(raw)
        if (v = "")
            continue
        if (SubStr(v,1,1)="'"
         && SubStr(v,-1)="'")
            v := SubStr(v,2,StrLen(v)-2)
        v := StrReplace(v, "'", "''")
        vals.Push("'" v "'")
    }

    joined := ""
    for i, qv in vals
        joined .= (i>1 ? "," : "") qv

    A_Clipboard := "in (" . joined . ")"
    TryHideLauncher()
}
