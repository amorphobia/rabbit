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

class KeyDef {
    static keycode_code := Map(
        "Space",        0x000020,
        "'",            0x000027,
        ",",            0x00002c,
        "-",            0x00002d,
        ".",            0x00002e,
        "/",            0x00002f,
        "0",            0x000030,
        "1",            0x000031,
        "2",            0x000032,
        "3",            0x000033,
        "4",            0x000034,
        "5",            0x000035,
        "6",            0x000036,
        "7",            0x000037,
        "8",            0x000038,
        "9",            0x000039,
        ";",            0x00003b,
        "=",            0x00003d,
        "[",            0x00005b,
        "\",            0x00005c,
        "]",            0x00005d,
        "``",           0x000060,
        "a",            0x000061,
        "b",            0x000062,
        "c",            0x000063,
        "d",            0x000064,
        "e",            0x000065,
        "f",            0x000066,
        "g",            0x000067,
        "h",            0x000068,
        "i",            0x000069,
        "j",            0x00006a,
        "k",            0x00006b,
        "l",            0x00006c,
        "m",            0x00006d,
        "n",            0x00006e,
        "o",            0x00006f,
        "p",            0x000070,
        "q",            0x000071,
        "r",            0x000072,
        "s",            0x000073,
        "t",            0x000074,
        "u",            0x000075,
        "v",            0x000076,
        "w",            0x000077,
        "x",            0x000078,
        "y",            0x000079,
        "z",            0x00007a,
        "Backspace",    0x00ff08,
        "Tab",          0x00ff09,
        "Enter",        0x00ff0d, ; Return
        "Pause",        0x00ff13,
        "ScrollLock",   0x00ff14,
        "Escape",       0x00ff1b,
        "Home",         0x00ff50,
        "Left",         0x00ff51,
        "Up",           0x00ff52,
        "Right",        0x00ff53,
        "Down",         0x00ff54,
        "PgUp",         0x00ff55,
        "PgDn",         0x00ff56,
        "End",          0x00ff57,
        "Insert",       0x00ff63,
        "AppsKey",      0x00ff67, ; Menu
        "Help",         0x00ff6a,
        "NumLock",      0x00ff7f,
        "NumpadEnter",  0x00ff8d,
        "NumpadHome",   0x00ff95,
        "NumpadLeft",   0x00ff96,
        "NumpadUp",     0x00ff97,
        "NumpadRight",  0x00ff98,
        "NumpadDown",   0x00ff99,
        "NumpadPgUp",   0x00ff9a,
        "NumpadPgDn",   0x00ff9b,
        "NumpadEnd",    0x00ff9c,
        "NumpadIns",    0x00ff9e,
        "NumpadDel",    0x00ff9f,
        "NumpadMult",   0x00ffaa,
        "NumpadAdd",    0x00ffab,
        "NumpadSub",    0x00ffad,
        "NumpadDot",    0x00ffae,
        "NumpadDiv",    0x00ffaf,
        "Numpad0",      0x00ffb0,
        "Numpad1",      0x00ffb1,
        "Numpad2",      0x00ffb2,
        "Numpad3",      0x00ffb3,
        "Numpad4",      0x00ffb4,
        "Numpad5",      0x00ffb5,
        "Numpad6",      0x00ffb6,
        "Numpad7",      0x00ffb7,
        "Numpad8",      0x00ffb8,
        "Numpad9",      0x00ffb9,
        "F1",           0x00ffbe,
        "F2",           0x00ffbf,
        "F3",           0x00ffc0,
        "F4",           0x00ffc1,
        "F5",           0x00ffc2,
        "F6",           0x00ffc3,
        "F7",           0x00ffc4,
        "F8",           0x00ffc5,
        "F9",           0x00ffc6,
        "F10",          0x00ffc7,
        "F11",          0x00ffc8,
        "F12",          0x00ffc9,
        "F13",          0x00ffca,
        "F14",          0x00ffcb,
        "F15",          0x00ffcc,
        "F16",          0x00ffcd,
        "F17",          0x00ffce,
        "F18",          0x00ffcf,
        "F19",          0x00ffd0,
        "F20",          0x00ffd1,
        "F21",          0x00ffd2,
        "F22",          0x00ffd3,
        "F23",          0x00ffd4,
        "F24",          0x00ffd5,
        "CapsLock",     0x00ffe5,
        "Delete",       0x00ffff,
    )

    static modifiers := Array(
        "LShift", "RShift",
        "LCtrl", "RCtrl",
        "LAlt", "RAlt",
        "LWin", "RWin",
    )

    static modifier_code := Map(
        "LShift",       0x00ffe1,
        "RShift",       0x00ffe2,
        "LCtrl",        0x00ffe3,
        "RCtrl",        0x00ffe4,
        "LAlt",         0x00ffe9,
        "RAlt",         0x00ffea,
        "LWin",         0x00ffeb, ; Super_L
        "RWin",         0x00ffec, ; Super_R
    )

    static modifier_symbol := Map(
        "LShift",       "<+",
        "RShift",       ">+",
        "LCtrl",        "<^",
        "RCtrl",        ">^",
        "LAlt",         "<!",
        "RAlt",         ">!",
        "LWin",         "<#",
        "RWin",         ">#",
    )

    static mask := Map(
        "Shift",        1 <<  0,
        "LShift",       1 <<  0,
        "RShift",       1 <<  0,
        "Ctrl",         1 <<  2,
        "LCtrl",        1 <<  2,
        "RCtrl",        1 <<  2,
        "Alt",          1 <<  3,
        "LAlt",         1 <<  3,
        "RAlt",         1 <<  3,
        "Win",          1 << 26,
        "LWin",         1 << 26,
        "RWin",         1 << 26,
        "Up",           1 << 30,
    )
}

; WIP
RegisterKeys(session_id, process_key) {
    for mod, code in KeyDef.modifier_code {
        Hotkey("$" . mod, process_key.Bind(session_id, mod . " Down", code, KeyDef.mask[mod]))
        Hotkey("$" . mod . " Up", process_key.Bind(session_id, mod . " Up", code, KeyDef.mask[mod] | KeyDef.mask["Up"]))
    }
    ; TODO: maybe parse the built key-bindings and only register them
    ;       or use InputHook
    for key, code in KeyDef.keycode_code {
        ; TODO: hook up events so that chord schemas work
        Hotkey("$" . key, process_key.Bind(session_id, key, code, 0))
        if key = "Tab"
            continue
        for index1, mod1 in KeyDef.modifiers {
            Hotkey("$" . KeyDef.modifier_symbol[mod1] . key, process_key.Bind(session_id, key, code, KeyDef.mask[mod1]))
            for index2, mod2 in KeyDef.modifiers {
                if index2 <= index1 or SubStr(mod1, 2) = SubStr(mod2, 2)
                    continue
                Hotkey(
                    "$" . KeyDef.modifier_symbol[mod1] . KeyDef.modifier_symbol[mod2] . key,
                    process_key.Bind(session_id, key, code, KeyDef.mask[mod1] | KeyDef.mask[mod2])
                )
                ; FIXME: too many nested loops
                ; for index3, mod3 in KeyDef.modifiers {
                ;     if index3 <= index2 or SubStr(mod2, 2) = SubStr(mod3, 2)
                ;         continue
                ;     Hotkey(
                ;         "$" . KeyDef.modifier_symbol[mod1] . KeyDef.modifier_symbol[mod2] . KeyDef.modifier_symbol[mod3] . key,
                ;         process_key.Bind(session_id, key, code, KeyDef.mask[mod1] | KeyDef.mask[mod2] | KeyDef.mask[mod3])
                ;     )
                ; }
            }
        }
    }
}

; https://www.autohotkey.com/boards/viewtopic.php?f=76&t=101183
SetDefaultKeyboard(locale_id) {
    lang := DllCall("LoadKeyboardLayoutW", "Str", Format("{:08x}", locale_id), "Int", 0)
    PostMessage(0x50, 0, lang, , 0xffff)
}
