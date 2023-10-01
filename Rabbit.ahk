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
    preedit := box.AddEdit("vPreedit -VScroll xm ym w200 ReadOnly r1")
    preedit.Value := "nihao"
    candidates := box.AddEdit("vCandidates -VScroll w200 ReadOnly r10")
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

    static STATUS_TOOLTIP := 2
    local status := rime.get_status(session_id)
    local old_ascii_mode := status.is_ascii_mode
    local old_full_shape := status.is_full_shape
    local old_ascii_punct := status.is_ascii_punct
    rime.free_status(status)

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

            GetTextSize(preedit_text, "S12, Microsoft YaHei UI", &max_width, &height)

            candidate_text_array := GetCandidateTextArray(context.menu, &page_no, &is_last_page)

            local menu_text := ""
            for candidate_text in candidate_text_array {
                GetTextSize(candidate_text, "S12, Microsoft YaHei UI", &width)
                if width > max_width
                    max_width := width
                if A_Index > 1
                    menu_text := menu_text . "`r`n"
                menu_text := menu_text . candidate_text
            }

            if caret {
                ; local caret_loc := "x: " . caret_x . ", y: " . caret_y . ", w: " . caret_w . ", h: " . caret_h
                ; GetTextSize(caret_loc, "S12, Microsoft YaHei UI", &width)
                ; if width > max_width
                ;     max_width := width
                box["Preedit"].Value := preedit_text
                box["Candidates"].Value := menu_text ;. "`r`n" . caret_loc
                box["Preedit"].Move(, , max_width)
                box["Candidates"].Move(, , max_width, height * candidate_text_array.Length)
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

GetCompositionText(composition, &pre_selected, &selected, &post_selected) {
    pre_selected := ""
    selected := ""
    post_selected := ""
    if not preedit := composition.preedit
        return false

    static cursor_text := "‸" ; or 𝙸
    static cursor_size := StrPut(cursor_text, "UTF-8") - 1 ; do not count tailing null

    local preedit_length := StrPut(preedit, "UTF-8")
    local selected_start := composition.sel_start
    local selected_end := composition.sel_end

    local preedit_buffer ; insert caret text into preedit text if applicable
    if 0 <= composition.cursor_pos and composition.cursor_pos <= preedit_length {
        preedit_buffer := Buffer(preedit_length + cursor_size, 0)
        local temp_preedit := c_str(preedit)
        local src := temp_preedit.Ptr
        local tgt := preedit_buffer.Ptr
        Loop composition.cursor_pos {
            byte := NumGet(src, A_Index - 1, "Char")
            NumPut("Char", byte, tgt, A_Index - 1)
        }
        src := src + composition.cursor_pos
        tgt := tgt + composition.cursor_pos
        StrPut(cursor_text, tgt, "UTF-8")
        tgt := tgt + cursor_size
        Loop preedit_length - composition.cursor_pos {
            byte := NumGet(src, A_Index - 1, "Char")
            NumPut("Char", byte, tgt, A_Index - 1)
        }
        preedit_length := preedit_length + cursor_size
        if selected_start >= composition.cursor_pos
            selected_start := selected_start + cursor_size
        if selected_end > composition.cursor_pos
            selected_end := selected_end + cursor_size
    } else {
        preedit_buffer := Buffer(preedit_length, 0)
        StrPut(preedit, preedit_buffer, "UTF-8")
    }

    if 0 <= selected_start and selected_start < selected_end and selected_end <= preedit_length {
        pre_selected := StrGet(preedit_buffer, selected_start, "UTF-8")
        selected := StrGet(preedit_buffer.Ptr + selected_start, selected_end - selected_start, "UTF-8")
        post_selected := StrGet(preedit_buffer.Ptr + selected_end, "UTF-8")
        return true
    } else {
        pre_selected := StrGet(preedit_buffer, "UTF-8")
        return false
    }
}

GetCandidateTextArray(menu, &page_no, &is_last_page) {
    local candidate_text_array := Array()
    if menu.num_candidates = 0
        return candidate_text_array

    page_no := menu.page_no
    is_last_page := menu.is_last_page
    ; local page_info := "page: " . page_no + 1 . (is_last_page ? "$" : " ") . "(of size " . menu.page_size . ")"
    ; candidate_text_array.Push(page_info)

    local candidates := menu.candidates
    Loop menu.num_candidates {
        local is_highlighted := A_Index = menu.highlighted_candidate_index + 1
        local candidate_text := A_Index . ". " . (is_highlighted ? "[" : " ") . candidates[A_Index].text . (is_highlighted ? "]" : " ") . candidates[A_Index].comment
        candidate_text_array.Push(candidate_text)
    }

    return candidate_text_array
}

; https://www.autohotkey.com/board/topic/16625-function-gettextsize-calculate-text-dimension/
GetTextSize(text, font_settings := "", &width := 0, &height := 0) {
    local dc := DllCall("GetDC", "UInt", 0)

    ; parse font
    italic := InStr(font_settings, "italic") ? true : false
    underline := InStr(font_settings, "underline") ? true : false
    strikeout := InStr(font_settings, "strikeout") ? true : false
    weight := InStr(font_settings, "bold") ? 700 : 400

    RegExMatch(font_settings, "(?<=[S|s])(\d{1,2})(?=[ ,])", &matched)
    point := matched ? Integer(matched[1]) : 10

    ; static weasel_root := RegRead("HKEY_LOCAL_MACHINE\Software\Rime\Weasel", "WeaselRoot", "")
    local log_pixels := RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontDPI", "LogPixels", "")
    point := -DllCall("MulDiv", "Int", point, "Int", log_pixels, "Int", 72)
    RegExMatch(font_settings, "(?<=,)(.+)", &matched)
    font_face := matched ? RegExReplace(matched[1], "(^\s*)|(\s*$)") : "MS Sans Serif"

    font := DllCall("CreateFont", "Int", point, "Int", 0, "Int", 0, "Int", 0, "Int", weight, "UInt", italic, "UInt", underline, "UInt", strikeout, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "Str", font_face)
    old_font := DllCall("SelectObject", "UInt", dc, "UInt", font)

    local size := Buffer(16, 0)
    DllCall("DrawText", "UInt", dc, "Str", text, "Int", StrLen(text), "UInt", size.Ptr, "UInt", 0x400)
    DllCall("SelectObject", "UInt", dc, "UInt", old_font)
    DllCall("DeleteObject", "UInt", font)
    DllCall("ReleaseDC", "UInt", 0, "UInt", dc)

    width := ExtractInteger(size.Ptr, 8)
    height := ExtractInteger(size.Ptr, 12)
}

ExtractInteger(src, offset) {
    local result := 0
    Loop 4 {
        result += NumGet(src, offset + A_Index - 1, "UChar") << 8 * (A_Index - 1)
    }
    return result
}
