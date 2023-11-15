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
