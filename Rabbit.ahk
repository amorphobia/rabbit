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
#Requires AutoHotkey v2.0
#SingleInstance Ignore

global TRAY_MENU_GRAYOUT := false

#Include <RabbitCommon>
#Include <RabbitKeyTable>
#Include <RabbitCandidateBox>
#Include <RabbitCaret>
#Include <RabbitTrayMenu>
#Include <RabbitMonitors>

global session_id := 0
global box := CandidateBox()
global mutex := RabbitMutex()

RegisterHotKeys()
RabbitMain(A_Args)

RabbitMain(args) {
    local layout := DllCall("GetKeyboardLayout", "UInt", 0)
    SetDefaultKeyboard()

    fail_count := 0
    while not mutex.Create() {
        fail_count++
        if fail_count > 500 {
            TrayTip()
            TrayTip("有其他进程正在使用 RIME，启动失败")
            Sleep(2000)
            ExitApp()
        }
    }

    rabbit_traits := CreateTraits()
    global rime
    rime.setup(rabbit_traits)
    rime.set_notification_handler(OnRimeMessage, 0)
    rime.initialize(rabbit_traits)

    local m := (args.Length == 0) ? RABBIT_PARTIAL_MAINTENANCE : args[1]
    if m != RABBIT_NO_MAINTENANCE {
        if rime.start_maintenance(m == RABBIT_FULL_MAINTENANCE)
            rime.join_maintenance_thread()
    } else {
        TrayTip()
        TrayTip("维护完成", RABBIT_IME_NAME)
        SetTimer(TrayTip, -2000)
    }

    global session_id := rime.create_session()
    if not session_id {
        SetDefaultKeyboard(layout)
        rime.finalize()
        throw Error("未能成功创建 RIME 会话。")
    }

    UpdateStateLabels()
    if status := rime.get_status(session_id) {
        local new_schema_name := status.schema_name
        local new_ascii_mode := status.is_ascii_mode
        local new_full_shape := status.is_full_shape
        local new_ascii_punct := status.is_ascii_punct
        rime.free_status(status)

        A_IconTip := Format(
            "玉兔毫　{}`n{} | {} | {}", new_schema_name,
            (new_ascii_mode ? ASCII_MODE_TRUE_LABEL : ASCII_MODE_FALSE_LABEL),
            (new_full_shape ? FULL_SHAPE_TRUE_LABEL : FULL_SHAPE_FALSE_LABEL),
            (new_ascii_punct ? ASCII_PUNCT_TRUE_LABEL : ASCII_PUNCT_FALSE_LABEL)
        )
    }

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
    TrayTip()
    ToolTip()
    ToolTip(, , , STATUS_TOOLTIP)
    if session_id {
        rime.destroy_session(session_id)
        rime.finalize()
    }
    if mutex
        mutex.Close()
}

RegisterHotKeys() {
    local shift := KeyDef.mask["Shift"]
    local ctrl := KeyDef.mask["Ctrl"]
    local alt := KeyDef.mask["Alt"]
    local win := KeyDef.mask["Win"]
    local up := KeyDef.mask["Up"]

    ; Modifiers
    for modifier, _ in KeyDef.modifier_code {
        if modifier == "LWin" or modifier == "RWin" or modifier == "LAlt" or modifier == "RAlt"
            continue ; do not register Win / Alt keys for now
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
            ; do not register Alt + single key now
            ; if not key = "Tab" {
            ;     Hotkey("$<!" . key, ProcessKey.Bind(key, alt))
            ;     Hotkey("$>!" . key, ProcessKey.Bind(key, alt))
            ; }
            Hotkey("$>^" . key, ProcessKey.Bind(key, ctrl))
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

    if status := rime.get_status(session_id) {
        local old_schema_id := status.schema_id
        local old_ascii_mode := status.is_ascii_mode
        local old_full_shape := status.is_full_shape
        local old_ascii_punct := status.is_ascii_punct
        rime.free_status(status)
    }

    processed := rime.process_key(session_id, code, mask)

    status := rime.get_status(session_id)
    local new_schema_id := status.schema_id
    local new_schema_name := status.schema_name
    local new_ascii_mode := status.is_ascii_mode
    local new_full_shape := status.is_full_shape
    local new_ascii_punct := status.is_ascii_punct
    rime.free_status(status)

    if old_schema_id !== new_schema_id {
        UpdateStateLabels()
    }

    A_IconTip := Format(
        "玉兔毫　{}`n{} | {} | {}", new_schema_name,
        (new_ascii_mode ? ASCII_MODE_TRUE_LABEL : ASCII_MODE_FALSE_LABEL),
        (new_full_shape ? FULL_SHAPE_TRUE_LABEL : FULL_SHAPE_FALSE_LABEL),
        (new_ascii_punct ? ASCII_PUNCT_TRUE_LABEL : ASCII_PUNCT_FALSE_LABEL)
    )

    local status_text := ""
    local status_changed := false
    if old_ascii_mode != new_ascii_mode {
        status_changed := true
        status_text := new_ascii_mode ? ASCII_MODE_TRUE_LABEL_ABBR : ASCII_MODE_FALSE_LABEL_ABBR
    } else if old_full_shape != new_full_shape {
        status_changed := true
        status_text := new_full_shape ? FULL_SHAPE_TRUE_LABEL_ABBR : FULL_SHAPE_FALSE_LABEL_ABBR
    } else if old_ascii_punct != new_ascii_punct {
        status_changed := true
        status_text := new_ascii_punct ? ASCII_PUNCT_TRUE_LABEL_ABBR : ASCII_PUNCT_FALSE_LABEL_ABBR
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

    if context := rime.get_context(session_id) {
        if context.composition.length > 0 {
            if GetCaretPos(&caret_x, &caret_y, &caret_w, &caret_h) {
                box.Build(context, &box_width, &box_height)
                new_x := caret_x + caret_w
                new_y := caret_y + caret_h + 4

                hWnd := WinExist("A")
                hMon := MonitorManage.MonitorFromWindow(hWnd)
                info := MonitorManage.GetMonitorInfo(hMon)
                if info {
                    if new_x + box_width > info.work.right
                        new_x := info.work.right - box_width
                    if new_y + box_height > info.work.bottom
                        new_y := caret_y - 4 - box_height
                } else {
                    workspace_width := SysGet(16) ; SM_CXFULLSCREEN
                    workspace_height := SysGet(17) ; SM_CYFULLSCREEN
                    if new_x + box_width > workspace_width
                        new_x := workspace_width - box_width
                    if new_y + box_height > workspace_height
                        new_y := caret_y - 4 - box_height
                }
                box.Show("AutoSize NA x" . new_x . " y" . new_y)
            } else {
                has_selected := GetCompositionText(context.composition, &pre_selected, &selected, &post_selected)
                preedit_text := pre_selected
                if has_selected
                    preedit_text := preedit_text . "[" . selected "]" . post_selected
                ToolTip(preedit_text . "`r`n" . GetMenuText(context.menu))
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

UpdateStateLabels() {
    global rime, session_id, ASCII_MODE_FALSE_LABEL, ASCII_MODE_TRUE_LABEL, ASCII_MODE_FALSE_LABEL_ABBR, ASCII_MODE_TRUE_LABEL_ABBR, FULL_SHAPE_FALSE_LABEL, FULL_SHAPE_TRUE_LABEL, FULL_SHAPE_FALSE_LABEL_ABBR, FULL_SHAPE_TRUE_LABEL_ABBR, ASCII_PUNCT_FALSE_LABEL, ASCII_PUNCT_TRUE_LABEL, ASCII_PUNCT_FALSE_LABEL_ABBR, ASCII_PUNCT_TRUE_LABEL_ABBR
    if not rime
        return

    str := rime.get_state_label(session_id, "ascii_mode", false)
    ASCII_MODE_FALSE_LABEL := str ? str : "中文"
    str := rime.get_state_label(session_id, "ascii_mode", true)
    ASCII_MODE_TRUE_LABEL := str ? str : "西文"
    str := rime.get_state_label_abbreviated(session_id, "ascii_mode", false, true).slice
    ASCII_MODE_FALSE_LABEL_ABBR := str ? str : "中"
    str := rime.get_state_label_abbreviated(session_id, "ascii_mode", true, true).slice
    ASCII_MODE_TRUE_LABEL_ABBR := str ? str : "西"
    str := rime.get_state_label(session_id, "full_shape", false)
    FULL_SHAPE_FALSE_LABEL := str ? str : "半角"
    str := rime.get_state_label(session_id, "full_shape", true)
    FULL_SHAPE_TRUE_LABEL := str ? str : "全角"
    str := rime.get_state_label_abbreviated(session_id, "full_shape", false, true).slice
    FULL_SHAPE_FALSE_LABEL_ABBR := str ? str : "半"
    str := rime.get_state_label_abbreviated(session_id, "full_shape", true, true).slice
    FULL_SHAPE_TRUE_LABEL_ABBR := str ? str : "全"
    str := rime.get_state_label(session_id, "ascii_punct", false)
    ASCII_PUNCT_FALSE_LABEL := str ? str : "。，"
    str := rime.get_state_label(session_id, "ascii_punct", true)
    ASCII_PUNCT_TRUE_LABEL := str ? str : "．，"
    str := rime.get_state_label_abbreviated(session_id, "ascii_punct", false, true).slice
    ASCII_PUNCT_FALSE_LABEL_ABBR := str ? str : "。"
    str := rime.get_state_label_abbreviated(session_id, "ascii_punct", true, true).slice
    ASCII_PUNCT_TRUE_LABEL_ABBR := str ? str : "．"
}
