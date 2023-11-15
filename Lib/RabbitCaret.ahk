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

/*
 * original code can be found in https://github.com/Descolada/AHK-v2-libraries
 * with MIT License
 */

/**
 * Gets the position of the caret with UIA, Acc or CaretGetPos.
 * Credit: plankoe (https://www.reddit.com/r/AutoHotkey/comments/ysuawq/get_the_caret_location_in_any_program/)
 * @param X Value is set to the screen X-coordinate of the caret
 * @param Y Value is set to the screen Y-coordinate of the caret
 * @param W Value is set to the width of the caret
 * @param H Value is set to the height of the caret
 */
GetCaretPos(&caret_x?, &caret_y?, &caret_w?, &caret_h?) {
    static OBJID_CARET := 0xFFFFFFF8
    static VT_I4 := 3
    static VT_R8 := 5
    static VT_DISPATCH := 9
    static VT_ARRAY := 0x2000
    static VT_BYREF := 0x4000
    static F_OWNVALUE := 1
    static UIA_TextPattern2Id := 10024

    caret_x := 0
    caret_y := 0
    caret_w := 0
    caret_h := 0

    ; Acc caret
    static acc_lib := DllCall("LoadLibrary", "Str", "oleacc", "Ptr")
    if acc_lib {
        local hwnd := WinExist("A")
        local iid := Buffer(16, 0)
        local riid := NumPut("Int64", 0x11CF3C3D618736E0, iid)
        riid := NumPut("Int64", 0x719B3800AA000C81, riid) - 16
        local result := DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hwnd, "UInt", OBJID_CARET, "Ptr", riid, "Ptr*", acc_object := ComValue(VT_DISPATCH, 0))
        if result = 0 {
            x := Buffer(4, 0)
            y := Buffer(4, 0)
            w := Buffer(4, 0)
            h := Buffer(4, 0)
            acc_object.accLocation(
                ComValue(VT_I4 | VT_BYREF, x.Ptr, F_OWNVALUE),
                ComValue(VT_I4 | VT_BYREF, y.Ptr, F_OWNVALUE),
                ComValue(VT_I4 | VT_BYREF, w.Ptr, F_OWNVALUE),
                ComValue(VT_I4 | VT_BYREF, h.Ptr, F_OWNVALUE),
                0
            )
            caret_x := NumGet(x, "Int")
            caret_y := NumGet(y, "Int")
            caret_w := NumGet(w, "Int")
            caret_h := NumGet(h, "Int")
            if caret_x or caret_y
                return true
        }
    }

    ; UIA2
    static uia_lib := ComObject("{e22ad333-b25f-460c-83d0-0581107395c9}", "{34723aff-0c9d-49d0-9896-7ab52df8cd8a}")
    if uia_lib {
        ; https://github.com/tpn/winsdk-10/blob/9b69fd26ac0c7d0b83d378dba01080e93349c2ed/Include/10.0.16299.0/um/UIAutomationClient.h#L15415
        ; GetFocusedElement
        ComCall(8, uia_lib, "Ptr*", &focused_element := 0)
        ; https://github.com/tpn/winsdk-10/blob/9b69fd26ac0c7d0b83d378dba01080e93349c2ed/Include/10.0.16299.0/um/UIAutomationClient.h#L1863
        ; GetCurrentPattern
        ComCall(16, focused_element, "Int", UIA_TextPattern2Id, "Ptr*", &pattern_object := 0)
        ObjRelease(focused_element)

        if pattern_object {
            ; https://github.com/tpn/winsdk-10/blob/9b69fd26ac0c7d0b83d378dba01080e93349c2ed/Include/10.0.16299.0/um/UIAutomationClient.h#L7766
            ; GetCaretRange
            ComCall(10, pattern_object, "Int*", &is_active := 1, "Ptr*", &caret_range := 0)
            ObjRelease(pattern_object)

            ; https://github.com/tpn/winsdk-10/blob/9b69fd26ac0c7d0b83d378dba01080e93349c2ed/Include/10.0.16299.0/um/UIAutomationClient.h#L6849C2-L6849C2
            ; GetBoundingRectangles
            ComCall(10, caret_range, "Ptr*", &bounding_rects := 0)
            ObjRelease(caret_range)

            rect := ComValue(VT_R8 | VT_ARRAY, bounding_rects)
            if rect.MaxIndex() = 3 {
                caret_x := Round(rect[0])
                caret_y := Round(rect[1])
                caret_w := Round(rect[2])
                caret_h := Round(rect[3])
                return true
            }
        }
    }

    local saved_caret := A_CoordModeCaret
    CoordMode("Caret", "Screen")
    local found := CaretGetPos(&caret_x, &caret_y)
    CoordMode("Caret", saved_caret)
    if found {
        caret_w := 4
        caret_h := 20
    } else {
        caret_x := 0
        caret_y := 0
    }

    return found
}
