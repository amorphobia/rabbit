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

#Include <RabbitCommon>
#Include <RabbitKeyTable>
#Include <RabbitCandidateBox>
#Include <RabbitCaret>
#Include <RabbitTrayMenu>

global session_id := 0
global box := Gui()

RegisterHotKeys()
RabbitMain()

RabbitMain() {
    local layout := DllCall("GetKeyboardLayout", "UInt", 0)
    SetDefaultKeyboard()

    rabbit_traits := CreateTraits()
    global rime
    rime.setup(rabbit_traits)
    rime.set_notification_handler(OnMessage, 0)
    rime.initialize(rabbit_traits)
    if rime.start_maintenace(true)
        rime.join_maintenance_thread()

    global session_id := rime.create_session()
    if not session_id {
        SetDefaultKeyboard(layout)
        rime.finalize()
        throw Error("未能成功创建 RIME 会话。")
    }

    box.Opt("-Caption +Owner")
    box.MarginX := 3
    box.MarginY := 3
    box.SetFont("S12", "Microsoft YaHei UI")

    preedit := box.AddText("vPreedit xm ym")
    preedit.Value := "nkhz"
    candidates := box.AddText("vCandidates")
    candidates.Value := "Hello, Rabbit!`r`n"

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
        if modifier == "LWin" or modifier == "RWin"
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
            if not key == "Tab"
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
            if key == check_key {
                code := check_code
                break
            }
        }
        if code
            break
    }
    if not code
        return

    static STATUS_TOOLTIP := 2
    if status := rime.get_status(session_id) {
        local old_ascii_mode := status.is_ascii_mode
        local old_full_shape := status.is_full_shape
        local old_ascii_punct := status.is_ascii_punct
        rime.free_status(status)
    }

    processed := rime.process_key(session_id, code, mask)

    status := rime.get_status(session_id)
    local new_ascii_mode := status.is_ascii_mode
    local new_full_shape := status.is_full_shape
    local new_ascii_punct := status.is_ascii_punct
    rime.free_status(status)

    local status_text := ""
    local status_changed := false
    if old_ascii_mode != new_ascii_mode {
        status_changed := true
        status_text := new_ascii_mode ? "En" : "中"
    } else if old_full_shape != new_full_shape {
        status_changed := true
        status_text := new_full_shape ? "全" : "半"
    } else if old_ascii_punct != new_ascii_punct {
        status_changed := true
        status_text := new_ascii_punct ? ",." : "，。"
    }

    if status_changed {
        ToolTip(status_text, , , STATUS_TOOLTIP)
        SetTimer(() => ToolTip(, , , STATUS_TOOLTIP), -2000)
    }

    if commit := rime.get_commit(session_id) {
        SendText(commit.text)
        ToolTip()
        box.Show("Hide")
        rime.free_commit(commit)
    }

    local caret := GetCaretPos(&caret_x, &caret_y, &caret_w, &caret_h)

    if context := rime.get_context(session_id) {
        if context.composition.length > 0 {
            has_selected := GetCompositionText(context.composition, &pre_selected, &selected, &post_selected)
            preedit_text := pre_selected
            if has_selected
                preedit_text := preedit_text . "[" . selected "]" . post_selected

            GetTextSize(preedit_text . "pad", "S12, Microsoft YaHei UI", &max_width, &height)

            candidate_text_array := GetCandidateTextArray(context.menu, &page_no, &is_last_page)

            local menu_text := ""
            for candidate_text in candidate_text_array {
                GetTextSize(candidate_text . "pad", "S12, Microsoft YaHei UI", &width)
                if width > max_width
                    max_width := width
                if A_Index > 1
                    menu_text := menu_text . "`r`n"
                menu_text := menu_text . candidate_text
            }

            if max_width < 150
                max_width := 150

            if caret {
                box["Preedit"].Value := preedit_text
                box["Candidates"].Value := menu_text
                box["Preedit"].Move(, , max_width)
                box["Candidates"].Move(, , max_width, height * candidate_text_array.Length)
                box.Show("Hide")
                box.Show("AutoSize NA x" . (caret_x + caret_w) . " y" . (caret_y + caret_h + 4))
                WinSetAlwaysOnTop(1, box)
            } else {
                ToolTip(preedit_text . "`r`n" . menu_text)
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
