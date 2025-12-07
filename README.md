# 🧭 AHK Command Launcher

A fast, dark-mode, Spotlight-style command launcher for Windows built with **AutoHotkey v2**.  
Instant fuzzy search, nested groups, action shortcuts, Fabric AI prompt enhancement, **prompt templates**, and a fully modular architecture.

<br>

## ✨ Features

* ⚡ **Instant fuzzy search** (space-insensitive)
* 🗂 **Nested command groups** (GitHub, Links, Azure, SQL helpers, custom groups)
* 🌓 **Dark mode UI**
* ↕ **Keyboard-first workflow** (Tab, Enter, Esc, Shift+Tab)
* 🔍 **Enter-to-run even without list focus**
* 🔙 **Search state restoration when navigating back**
* 🧩 **Modular file structure** (GUI, commands, logic)
* 📁 **Prompt templates** from files with parameter placeholders
* 🤖 **Fabric AI integration** via your repo  
  → **[Fabric-Prompt-Enhancer](https://github.com/mmcdermott-ashleyne/Fabric-Prompt-Enhancer)**
* 📋 Autocopies AI-enhanced output to clipboard
* 🛠 Easy command customization (open apps, URLs, folders, scripts)

<br>

## 📸 Screenshot

!['launcher'](launcher-preview.png)

<br>

## 🚀 Installation

### 1. Install AutoHotkey v2

[https://www.autohotkey.com/download/](https://www.autohotkey.com/download/)

### 2. Clone this repository

```sh
git clone https://github.com/mmcdermott-ashleyne/AutoHotKey-Command-Launcher.git
```

### 3. Folder Structure

```
AutoHotKey-Command-Launcher/
  main.ahk
  modules/
    commands.ahk
    gui.ahk
    logic.ahk
  prompts/
    repository_instruct.txt
```

### 4. Run the launcher

```sh
main.ahk
```

### 5. Open it anytime with:

```
Alt + CapsLock
```

<br>

## 🎮 Usage

### 🔹 Open Launcher

**Alt + CapsLock**

### 🔹 Navigation

| Action               | Key                      |
| -------------------- | ------------------------ |
| Filter / Search      | Type text                |
| Run selection        | **Enter**                |
| Move focus into list | **Tab**                  |
| Go back              | **Shift+Tab** or **Esc** |
| Close from root      | **Esc**                  |
| Help                 | `?` or **F1**            |

### 🔹 Nested Groups

Example:

```
links → Enter → downloads → Enter
```

Pressing Enter on a group opens a submenu.
Pressing **Esc** restores your previous search automatically.

### 🔹 Quick Execution

No need to tab into the list — **Enter** always defaults to the top result when nothing is selected.

<br>

## 🧾 Prompt Templates

The launcher can generate prompts from template files stored on disk.

```
prompt_template
```

**Template Folder**
By default, templates live in:

```
PromptTemplateDir := A_ScriptDir "\prompts"
```

**Template Format**

Any plain-text file works (.txt, .md, etc).
You can optionally include parameters using {NAME} placeholders, for example:
```
You are helping with a project called {PROJECT_NAME}.

Goal:
{GOAL}

Constraints:
{CONSTRAINTS}
```

How it works

1. Run prompt_template in the launcher.

2. A file picker opens in your prompts directory.

3. Choose a template file.

4. The launcher scans the file for {PARAM} placeholders.

5. For each unique param, you get an input box:

    - Example: Enter a value for {PROJECT_NAME}

6. After filling them in:

    - All {PARAM} placeholders are replaced with your values.

    - The final, filled template is copied to your clipboard.

7. A tray notification confirms the prompt was copied.

If the template has no placeholders, the raw file contents are copied directly to the clipboard.

### repository_instruct.txt

This template is designed for use with the Visual Studio Code extension [Copy4AI](https://marketplace.visualstudio.com/items?itemName=LeonKohli.snapsource). It provides a controlled workflow for gathering project context before sending instructions to GPT.

Usage Workflow (Strict Order):
1. Select `repository_instruct.txt` and fill in your instructions when prompted.

2. Paste the entire filled-in template into your GPT window.
This establishes the instruction framework before attaching any source material.

3. Use Copy4AI to extract project content.
In VS Code, select the target folder and/or files that GPT should analyze.
Run the Copy4AI command (right click) to generate the structured snapshot.

4. Append the generated snapshot to the end of the GPT prompt.
Do not modify the snapshot content.
Ensure the appended material appears after all instructions.

5. Submit the full prompt to GPT.
Allow GPT to process both the instructions and the appended repository snapshot.

<br>

## 🤖 Fabric AI Integration

This launcher includes a built-in command:

```
improve_prompt
```

It works seamlessly with your repository:

➡ **Fabric Prompt Enhancer**
[https://github.com/mmcdermott-ashleyne/Fabric-Prompt-Enhancer](https://github.com/mmcdermott-ashleyne/Fabric-Prompt-Enhancer)

### How it works

1. You select the command `improve_prompt`
2. Launcher hides itself
3. A multi-line prompt dialog appears
4. Your text is piped into:

```
type prompt.txt | fabric --pattern improve_prompt
```

5. Output is captured
6. Launcher copies the enhanced prompt to the clipboard
7. A system tray notification confirms completion

### Requirements

* Fabric CLI installed
* `fabric.exe` located at:

  ```
  C:\tools\fabric.exe
  ```

  (configurable in `logic.ahk`)

<br>

## 🧱 Project Architecture

### `main.ahk`

* Loads hotkeys
* Initializes modules
* Entry point for launcher

### `modules/commands.ahk`

Defines the command registry.
Add/edit launcher commands here.

Example:

```ahk
{ key: "vscode", label: "VS Code", action: (*) => Run("code.exe"), aliases: ["code", "vsc"] }
```

Or nested:

```ahk
{
  key: "web", label: "Web", children: [
    { key: "google", label: "Google", action: (*) => Run("https://google.com") },
    { key: "hackernews", label: "Hacker News", action: (*) => Run("https://news.ycombinator.com") }
  ]
}
```

### `modules/gui.ahk`

Handles:

* Dark mode layout
* Fonts and styling
* Window positioning
* Event hooks

### `modules/logic.ahk`

Handles:

* Fuzzy search
* Multiline prompt dialog
* Navigation stack
* Back/forward behavior
* Enter-to-run fallback
* Fabric piping and output capture

<br>

## 🔌 Adding Your Own Commands

### Simple command

```ahk
{ key: "calc", label: "Calculator", action: (*) => Run("calc.exe") }
```

### Command with argument support

```ahk
{ key: "open", label: "Open Path", action: (arg) => Run(arg) }
```

### Grouped commands

```ahk
{
  key: "devtools", label: "Developer Tools", children: [
    { key: "terminal", label: "Terminal", action: (*) => Run("wt.exe") },
    { key: "github", label: "GitHub", action: (*) => Run("https://github.com") }
  ]
}
```

<br>

## 🐛 Troubleshooting

### Command window flashes or openings appear behind launcher

Ensure GUI uses:

```ahk
+OwnDialogs
```

### Fabric not recognized

Verify the path in `logic.ahk`:

```ahk
fabricExe := "C:\tools\fabric.exe"
```

### Multiline prompt not working

Fabric *requires* the `type file | fabric ...` pattern.
`echo` cannot handle multiline reliably in cmd.

<br>

## ❤️ Contributing

Pull requests welcome!
Ideas:

* Add more built-in commands
* Advanced fuzzy scoring
* Plugin-style command extensions
* UI - Enhancements

<br>

