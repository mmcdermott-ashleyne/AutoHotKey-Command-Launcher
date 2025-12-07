#Requires AutoHotkey v2.0
#Include *i commands\sql.ahk
#Include *i commands\util.ahk

BuildRegistry() {
    reg := []

    ; ---- Core groups ----
    reg.Push(
	
		; ---- Links ----
        { key: "links", label: "Links", children: [
            { key: "links:fabric", label: "Fabric", action: (*) => Run("https://app.fabric.microsoft.com/home?experience=fabric-developer"), aliases: ["fab"] },
			{ key: "links:copilot", label: "Copilot Studio", action: (*) => Run("https://copilotstudio.microsoft.com/environments/~personal/home"), aliases: ["cop"] },
			{ key: "links:excel", label: "Excel", action: (*) => Run("https://excel.cloud.microsoft/en-us/"), aliases: ["ex"] },
			{ key: "links:word", label: "Word", action: (*) => Run("https://word.cloud.microsoft/"), aliases: ["word"] },
			{ key: "links:spdata", label: "SharePoint Data Repo", action: (*) => Run("https://ashleyne.sharepoint.com/sites/FDEFabricDataRepository"), aliases: ["repo","spdata"] },
			{ key: "links:crontab", label: "Crontab", action: (*) => Run("https://crontab.guru/#*/15_*_*_*_*"), aliases: ["cron"] }
        ], aliases: ["l"]},
		
		; ---- Reports ----
        { key: "reports", label: "Reporting", aliases: ["pbi","r"], children: [
            { key: "reports:capacity",    label: "Capacity",          action: (*) => Run("https://app.fabric.microsoft.com/groups/0b22deb9-309a-4bb5-a600-1e59aaa25cbf/reports/3323fd32-b27f-48d3-b7b4-d6f9f328d3b5/ReportSection9acbdaaf706063e57b07?experience=power-bi"), aliases: ["cap"] },
			{ key: "reports:sales",    label: "Sales Dashboard",          action: (*) => Run("https://app.fabric.microsoft.com/groups/me/apps/98d66221-00ae-489d-8f6c-1a279279ee23/dashboards/90296cb1-81e7-451b-9f1d-308baca0f339?experience=power-bi"), aliases: ["sales"] }
        ]}, 
		
		; ---- Azure ----
		{ key: "azuregroups", label: "Azure Groups", aliases: ["groups"], children: [
            { key: "azuregroups:all",    label: "All Groups",          action: (*) => Run("https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupsManagementMenuBlade/~/AllGroups"), aliases: ["allgroups"] },
        ]},
    )

    ; ---- Add SQL module commands ----
    reg.Push(BuildSqlCommands()*)  ; spread operator appends array contents


    ; ---- Core commands ----
	reg.Push(
		{ key: "links:downloads", label: "Downloads", action: (*) => Run(EnvGet("USERPROFILE") . "\Downloads"), aliases: ["dl","download dir"] },
        { key: "notepad", label: "Notepad", action: (*) => Run("notepad.exe"), aliases: ["np","++"] },
        { key: "calc",    label: "Calculator", action: (*) => Run("calc.exe"), aliases: ["calc"] },
        { key: "snip",    label: "Snipping Tool", action: (*) => Run("ms-screenclip:"), aliases: ["snip"] },
        { key: "lock",    label: "Lock Workstation", action: (*) => DllCall("LockWorkStation"), aliases: ["lock"] },
        { key: "ip",      label: "IP Config (CMD)", action: (*) => Run(EnvGet("ComSpec") . " /k ipconfig"), aliases: ["ipconfig","network"] },
        { key: "reload",  label: "Reload Launcher", action: (*) => Reload(), aliases: ["rel"] },
        { key: "prompt_template", label: "Prompt from Template"
            , action: PromptFromTemplateAction
            , aliases: ["ptemplate", "prompt from file", "tplprompt"] },
		{ key: "improve_prompt", label: "Improve Prompt (Fabric)", action: ImprovePromptAction, aliases: ["iprompt", "fabric improve", "prompt improve"] },
	)

    return reg
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

; =============
; == ARCHIVE ==
; =============
/*
    ; --- GitHub group  ---
        { key: "github", label: "GitHub", aliases: ["gh","git hub"], children: [
            { key: "github:home",    label: "Home",          action: (*) => Run("https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupsManagementMenuBlade/~/AllGroups"), aliases: ["site","root"] },
            { key: "github:issues",  label: "Issues",        action: (*) => Run("https://github.com/issues"), aliases: ["bugs","tickets"] },
            { key: "github:pulls",   label: "Pull Requests", action: (*) => Run("https://github.com/pulls"), aliases: ["prs"] },
            { key: "github:profile", label: "Your Profile",  action: (*) => Run("https://github.com/settings/profile"), aliases: ["profile","account"] }
        ]},
		
*/