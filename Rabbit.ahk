/*
 * Copyright (c) 2023 Xuesong Peng <pengxuesong.cn@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
#Requires AutoHotkey v2.0 32-bit
#SingleInstance Ignore

#Include <RabbitDeployer>
#Include <RabbitKeyTable>
#Include <RabbitCandidateBox>
#Include <RabbitCaret>

global rime := RimeApi()
global session_id := 0
global box := Gui()

RabbitMain()

RabbitMain() {
    local layout := DllCall("GetKeyboardLayout", "UInt", 0)
    SetDefaultKeyboard()

    Deploy()
    RegisterHotKeys()
    global session_id := rime.create_session()
    if not session_id {
        SetDefaultKeyboard(layout)
        rime.finalize()
        throw Error("未能成功创建 RIME 会话。")
    }
    TrayTip()
    TrayTip("初始化完成", APP_NAME)
    SetTimer(TrayTip, -2000)

    box.Opt("-Caption +Owner")
    box.MarginX := 3
    box.MarginY := 3
    box.SetFont("S12", "Microsoft YaHei UI")
    candidates := box.AddEdit("vCandidates -VScroll xm ym w200 ReadOnly r9")
    candidates.Value := "Hello, Rabbit!`r`n"
    ; box.Show("AutoSize")

    OnExit(ExitRabbit.Bind(layout))
}

; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=101183
SetDefaultKeyboard(locale_id := 0x0409) {
    local HWND_BROADCAST := 0xffff
    local LOW_WORD := 0xffff
    local WM_INPUTLANGCHANGEREQUEST := 0x0050
    local locale_id_hex := Format("{:08x}", locale_id & LOW_WORD)
    lang := DllCall("LoadKeyboardLayout", "Str", locale_id_hex, "Int", 0)
    PostMessage(WM_INPUTLANGCHANGEREQUEST, 0, lang, HWND_BROADCAST)
}

ExitRabbit(layout, reason, code) {
    SetDefaultKeyboard(layout)
    if session_id {
        rime.destroy_session(session_id)
        rime.finalize()
    }
}

RegisterHotKeys() {
    local shift := KeyDef.mask["Shift"]
    local ctrl := KeyDef.mask["Ctrl"]
    local alt := KeyDef.mask["Alt"]
    local win := KeyDef.mask["Win"]
    local up := KeyDef.mask["Up"]

    ; Modifiers
    for modifier, _ in KeyDef.modifier_code {
        if modifier = "LWin" or modifier = "RWin"
            continue ; do not register Win keys for now
        local mask := KeyDef.mask[modifier]
        Hotkey("$" . modifier, ProcessKey.Bind(modifier, mask))
        Hotkey("$" . modifier . " Up", ProcessKey.Bind(modifier, mask | up))
    }

    ; Plain
    Loop 2 {
        local key_map := A_Index = 1 ? KeyDef.plain_keycode : KeyDef.other_keycode
        for key, _ in key_map {
            Hotkey("$" . key, ProcessKey.Bind(key, 0))
            ; need specify left/right to prevent fallback to modifier down/up hotkeys
            Hotkey("$<^" . key, ProcessKey.Bind(key, ctrl))
            if not key = "Tab"
                Hotkey("$<!" . key, ProcessKey.Bind(key, alt))
            Hotkey("$>^" . key, ProcessKey.Bind(key, ctrl))
            Hotkey("$>!" . key, ProcessKey.Bind(key, alt))
            Hotkey("$^!" . key, ProcessKey.Bind(key, ctrl | alt))
            Hotkey("$!#" . key, ProcessKey.Bind(key, alt | win))

            ; Do not register Win keys for now
            ; Hotkey("$<#" . key, ProcessKey.Bind(key, win))
            ; Hotkey("$>#" . key, ProcessKey.Bind(key, win))
            ; Hotkey("$^#" . key, ProcessKey.Bind(key, ctrl | win))
            ; Hotkey("$^!#" . key, ProcessKey.Bind(key, ctrl | alt | win))
        }
    }

    ; Shifted
    Loop 2 {
        local key_map := A_Index = 1 ? KeyDef.shifted_keycode : KeyDef.other_keycode
        for key, _ in key_map {
            Hotkey("$<+" . key, ProcessKey.Bind(key, shift))
            Hotkey("$>+" . key, ProcessKey.Bind(key, shift))
            Hotkey("$+^" . key, ProcessKey.Bind(key, shift | ctrl))
            if not key = "Tab"
                Hotkey("$+!" . key, ProcessKey.Bind(key, shift | alt))
            Hotkey("$+^!" . key, ProcessKey.Bind(key, shift | ctrl | alt))

            ; Do not register Win keys for now
            ; Hotkey("$+#" . key, ProcessKey.Bind(key, shift | win))
            ; Hotkey("$+^#" . key, ProcessKey.Bind(key, shift | ctrl | win))
            ; Hotkey("$+!#" . key, ProcessKey.Bind(key, shift | alt | win))
            ; Hotkey("$+^!#" . key, ProcessKey.Bind(key, shift | ctrl | alt | win))
        }
    }
}

ProcessKey(key, mask, this_hotkey) {
    local code := 0
    Loop 4 {
        local key_map
        switch A_Index {
            case 1:
                key_map := KeyDef.modifier_code
            case 2:
                key_map := KeyDef.plain_keycode
            case 3:
                key_map := KeyDef.shifted_keycode
            case 4:
                key_map := KeyDef.other_keycode
            default:
                return
        }
        for check_key, check_code in key_map {
            if key = check_key {
                code := check_code
                break
            }
        }
        if code
            break
    }
    if not code
        return

    processed := rime.process_key(session_id, code, mask)
    if commit := rime.get_commit(session_id) {
        SendText(commit.text)
        ToolTip()
        box.Show("Hide")
        rime.free_commit(commit)
    }

    local caret := GetCaretPos(&caret_x, &caret_y, &caret_w, &caret_h)

    if context := rime.get_context(session_id) {
        if context.composition.length > 0 {
            context_text := GetCompositionText(context.composition) . "`r`n" . GetMenuText(context.menu)
            if caret {
                ; ToolTip(context_text, caret_x, caret_y + 30)
                local caret_loc := "`r`nx: " . caret_x . ", y: " . caret_y . ", w: " . caret_w . ", h: " . caret_h
                box["Candidates"].Value := context_text . caret_loc
                box.Show("AutoSize NA x" . (caret_x + caret_w) . " y" . (caret_y + caret_h + 4))
                WinSetAlwaysOnTop(1, box)
            } else {
                ; ToolTip(context_text)
                local caret_loc := "`r`nx: " . caret_x . ", y: " . caret_y . ", w: " . caret_w . ", h: " . caret_h
                box["Candidates"].Value := context_text . caret_loc
                box.Show("AutoSize NA")
                WinSetAlwaysOnTop(1, box)
            }
        } else {
            ToolTip()
            box.Show("Hide")
        }
        rime.free_context(context)
    }

    if not processed {
        if RegExMatch(SubStr(this_hotkey, 2), "([\<\>\^\+]+)(.+)", &matched)
            SendInput(StrReplace(StrReplace(matched[1], "<"), ">") . "{" . matched[2] . "}")
        else
            SendInput("{" . key . "}")
    }
}

GetCompositionText(composition) {
    local output := ""
    if not preedit := composition.preedit
        return output

    local len := StrPut(preedit, "UTF-8")
    local start := composition.sel_start
    local end := composition.sel_end
    local cursor := composition.cursor_pos
    local i := 0
    Loop parse preedit {
        if start < end {
            if i = start
                output := output . "["
            else if i = end
                output := output . "]"
        }
        if i = cursor
            output := output . "‸"
        if i < len
            output := output . A_LoopField
        i := i + StrPut(A_LoopField, "UTF-8") - 1
    }
    if start < end and i = end
        output := output . "]"
    if i = cursor
        output := output . "‸"

    return output
}

GetMenuText(menu) {
    local output := ""
    if menu.num_candidates = 0
        return output

    output := "page: " . menu.page_no + 1 . (menu.is_last_page ? "$" : " ") . "(of size " . menu.page_size . ")"
    local candidates := menu.candidates
    Loop menu.num_candidates {
        local highlighted := A_Index = menu.highlighted_candidate_index + 1
        output := output . "`r`n" . A_Index . ". " . (highlighted ? "[" : " ") . candidates[A_Index].text . (highlighted ? "]" : " ") . candidates[A_Index].comment
    }

    return output
}
