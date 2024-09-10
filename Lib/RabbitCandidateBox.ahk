/*
 * Copyright (c) 2023, 2024 Xuesong Peng <pengxuesong.cn@gmail.com>
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

global LVM_GETCOLUMNWIDTH := 0x101D
; https://learn.microsoft.com/windows/win32/winmsg/extended-window-styles
global WS_EX_NOACTIVATE := "+E0x8000000"

class CandidateBox extends Gui {
    static min_width := 150
    static idx_col := 1
    static cand_col := 2
    static comment_col := 3
    static num_col := 3

    __New() {
        super.__New(, , this)
        this.Opt("-Caption +Owner AlwaysOnTop " . WS_EX_NOACTIVATE)
        this.MarginX := 3
        this.MarginY := 3
        this.SetFont("S12", "Microsoft YaHei UI")

        this.pre := this.AddText(, "p")
        this.pre.GetPos(, , , &h)
        this.preedit_height := h
        this.lv := this.AddListView("-Multi -Hdr -E0x200 LV0x40", ["i", "c", "m"])
        DllCall("uxtheme\SetWindowTheme", "ptr", this.lv.hwnd, "WStr", "Explorer", "Ptr", 0)

        this.dummy_lv1 := this.AddListView("-Multi -Hdr -E0x200 LV0x40 Hidden R1", ["p"])
        this.dummy_lv2 := this.AddListView("-Multi -Hdr -E0x200 LV0x40 Hidden R2", ["p"])
        this.dummy_lv1.GetPos(, , , &dh1)
        this.dummy_lv2.GetPos(, , , &dh2)
        this.row_height := dh2 - dh1
        this.row_padding := dh1 - this.row_height
    }

    Build(context, &width, &height) {
        local has_selected := GetCompositionText(context.composition, &pre_selected, &selected, &post_selected)
        local cands := context.menu.candidates
        local lv_height := this.row_height * context.menu.num_candidates + this.row_padding

        preedit_text := pre_selected
        if has_selected
            preedit_text := preedit_text . "[" . selected "]" . post_selected

        this.pre.Value := preedit_text
        this.dummy_lv1.Delete()
        this.dummy_lv1.Add(, preedit_text)
        this.dummy_lv1.ModifyCol()
        preedit_width := SendMessage(LVM_GETCOLUMNWIDTH, 0, 0, this.dummy_lv1)

        this.lv.Delete()
        has_comment := false
        Loop context.menu.num_candidates {
            opt := (A_Index == context.menu.highlighted_candidate_index + 1) ? "Select" : ""
            if comment := cands[A_Index].comment
                has_comment := true
            this.lv.Add(opt, A_Index . ". ", cands[A_Index].text, comment)
        }

        total_width := 0
        this.lv.ModifyCol()
        if not has_comment
            this.lv.ModifyCol(CandidateBox.comment_col, 0)
        this.lv.GetPos(, , , &cands_height)
        Loop CandidateBox.num_col {
            width := SendMessage(LVM_GETCOLUMNWIDTH, A_Index - 1, 0, this.lv)
            total_width += width
            if A_Index == CandidateBox.cand_col
                cand_width := width
        }

        if not cand_width
            cand_width := SendMessage(LVM_GETCOLUMNWIDTH, CandidateBox.cand_col - 1, 0, this.lv)

        max_width := Max(preedit_width, total_width, CandidateBox.min_width)
        if total_width < max_width
            this.lv.ModifyCol(CandidateBox.cand_col, cand_width + max_width - total_width)

        this.lv.Move(, , max_width, lv_height)
        this.pre.Move(, , max_width)
        this.lv.Redraw()

        width := max_width + 6
        height := this.preedit_height + lv_height + this.MarginY
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
        local temp_preedit := Buffer(preedit_length, 0)
        StrPut(preedit, temp_preedit, "UTF-8")
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

GetMenuText(menu) {
    local text := ""
    if menu.num_candidates == 0
        return text
    local cands := menu.candidates
    Loop menu.num_candidates {
        local is_highlighted := (A_Index == menu.highlighted_candidate_index + 1)
        if A_Index > 1
            text := text . "`r`n"
        text := text . Format("{}. {}{}{}{}",
                              A_Index,
                              (is_highlighted ? "[" : " "),
                              cands[A_Index].text,
                              (is_highlighted ? "]" : " "),
                              cands[A_Index].comment
        )
    }
    return text
}
