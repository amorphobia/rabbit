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

A_IconTip := "玉兔毫"

global TRAY_SCHEMA_NAME := ""
global TRAY_ASCII_MODE := 0
global TRAY_FULL_SHAPE := 0
global TRAY_ASCII_PUNCT := 0

A_TrayMenu.Delete()
; A_TrayMenu.add("输入法设定")
; A_TrayMenu.add("用户词典管理")
A_TrayMenu.add("用户资料同步", (*) => Sync())
A_TrayMenu.add()
A_TrayMenu.add("用户文件夹", (*) => Run(A_ScriptDir . "\Rime"))
A_TrayMenu.add("脚本文件夹", (*) => Run(A_ScriptDir))
A_TrayMenu.add()
A_TrayMenu.add("仓库主页", (*) => Run("https://github.com/amorphobia/rabbit"))
A_TrayMenu.add()
A_TrayMenu.add("重新部署", (*) => Deploy())
A_TrayMenu.add("退出玉兔毫", (*) => ExitApp())

Sync() {
    Run(A_AhkPath . " " . A_ScriptDir . "\RabbitDeployer.ahk sync 1")
    ExitApp()
}
Deploy() {
    Run(A_AhkPath . " " . A_ScriptDir . "\RabbitDeployer.ahk deploy 1")
    ExitApp()
}

if TRAY_MENU_GRAYOUT {
    ; A_TrayMenu.Disable("输入法设定")
    ; A_TrayMenu.Disable("用户词典管理")
    A_TrayMenu.Disable("用户资料同步")
    A_TrayMenu.Disable("用户文件夹")
    A_TrayMenu.Disable("脚本文件夹")
    A_TrayMenu.Disable("仓库主页")
    A_TrayMenu.Disable("重新部署")
    A_TrayMenu.Disable("退出玉兔毫")
}

ClickHandler(wParam, lParam, msg, hWnd) {
    if !rime || !IsSet(session_id) || !session_id
        return
    if lParam == WM_LBUTTONUP {
        local old_ascii_mode := rime.get_option(session_id, "ascii_mode")
        rime.set_option(session_id, "ascii_mode", !old_ascii_mode)
        local new_ascii_mode := rime.get_option(session_id, "ascii_mode")
        UpdateTrayTip(, new_ascii_mode)
        status_text := new_ascii_mode ? ASCII_MODE_TRUE_LABEL_ABBR : ASCII_MODE_FALSE_LABEL_ABBR
        ToolTip(status_text, , , STATUS_TOOLTIP)
        SetTimer(() => ToolTip(, , , STATUS_TOOLTIP), -2000)
    }
}

UpdateTrayTip(schema_name := TRAY_SCHEMA_NAME, ascii_mode := TRAY_ASCII_MODE, full_shape := TRAY_FULL_SHAPE, ascii_punct := TRAY_ASCII_PUNCT) {
    global TRAY_SCHEMA_NAME, TRAY_ASCII_MODE, TRAY_FULL_SHAPE, TRAY_ASCII_PUNCT
    TRAY_SCHEMA_NAME := schema_name ? schema_name : TRAY_SCHEMA_NAME
    TRAY_ASCII_MODE := !!ascii_mode
    TRAY_FULL_SHAPE := !!full_shape
    TRAY_ASCII_PUNCT := !!ascii_punct
    A_IconTip := Format(
        "玉兔毫　{}`n左键切换模式，右键打开菜单`n{} | {} | {}", TRAY_SCHEMA_NAME,
        (TRAY_ASCII_MODE ? ASCII_MODE_TRUE_LABEL : ASCII_MODE_FALSE_LABEL),
        (TRAY_FULL_SHAPE ? FULL_SHAPE_TRUE_LABEL : FULL_SHAPE_FALSE_LABEL),
        (TRAY_ASCII_PUNCT ? ASCII_PUNCT_TRUE_LABEL : ASCII_PUNCT_FALSE_LABEL)
    )
}
