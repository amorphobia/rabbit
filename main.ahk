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

#Include "RabbitDeployer.ahk"

exit_rabbit(session_id, ExitReason, ExitCode) {
    rime := RimeApi()
    rime.destroy_session(session_id)
    rime.finalize()
}

; WIP
composition_str(composition) {
    out := ""
    if not preedit := composition.preedit
        return out
    len := StrPut(preedit, "UTF-8")
    start := composition.sel_start
    end := composition.sel_end
    cursor := composition.cursor_pos
    i := 0
    Loop Parse preedit {
        if start < end {
            if i = start
                out := out . "["
            else if i = end
                out := out . "]"
        }
        if i = cursor
            out := out . "‸"
        if i < len
            out := out . A_LoopField
        i := i + StrPut(A_LoopField, "UTF-8") - 1
    }
    if start < end and i = end
        out := out . "]"
    if i = cursor
        out := out . "‸"
    return out
}

; WIP
menu_str(menu) {
    out := ""
    if menu.num_candidates = 0
        return out
    out := "page: " . menu.page_no + 1 . (menu.is_last_page ? "$" : " ") . " (of size " . menu.page_size . ")"
    cands := menu.candidates
    Loop menu.num_candidates {
        highlighted := A_Index = menu.highlighted_candidate_index + 1
        out := out . "`r`n" . A_Index . ". " . (highlighted ? "[" : " ") . cands[A_Index].text . (highlighted ? "]" : " ") . cands[A_Index].comment
    }
    return out
}

; WIP
process_key(session_id, code, ch) {
    rime := RimeApi()
    if code {
        rime.process_key(session_id, code, 0)
        if commit := rime.get_commit(session_id) {
            SendText(commit.text)
            ToolTip()
            rime.free_commit(commit)
        }

        if context := rime.get_context(session_id) {
            if context.composition.length > 0 {
                ctx := composition_str(context.composition) . "`r`n" . menu_str(context.menu)
                ToolTip(ctx)
            }
            rime.free_context(context)
        }
    }
}

main() {
    deploy() ; TODO: skip full check if not first time
    rime := RimeApi()
    session_id := rime.create_session()
    if not session_id {
        MsgBox("未能成功创建 rime 会话。", "错误")
        ExitApp(1)
    }

    Loop 26 {
        code := 96 + A_Index
        Hotkey(Chr(code), process_key.Bind(session_id, code), "On")
    }
    Hotkey("Space", process_key.Bind(session_id, 32), "On")

    OnExit(exit_rabbit.Bind(session_id))
}

main()
