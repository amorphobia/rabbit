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

#Include <RabbitCommon>

A_IconTip := "玉兔毫"

global TRAY_SCHEMA_NAME := ""
global TRAY_ASCII_MODE := 0
global TRAY_FULL_SHAPE := 0
global TRAY_ASCII_PUNCT := 0

SetupTrayMenu()
UpdateTrayIcon()

SetupTrayMenu() {
    static rabbit_script := Format("`"{}\Rabbit.ahk`"", A_ScriptDir)
    static rabbit_ico    := Format("{}\Lib\rabbit.ico", A_ScriptDir)
    A_TrayMenu.Delete()
    ; A_TrayMenu.Add("输入法设定")
    ; A_TrayMenu.Add("用户词典管理")
    A_TrayMenu.Add("用户资料同步", (*) => Sync())

    A_TrayMenu.Add()

    A_TrayMenu.Add("用户文件夹", (*) => Run(A_ScriptDir . "\Rime"))
    A_TrayMenu.Add("脚本文件夹", (*) => Run(A_ScriptDir))

    A_TrayMenu.Add()

    if FileExist(A_Startup . "\Rabbit.lnk") {
        A_TrayMenu.Add("从开机启动删除", (*) => (FileDelete(A_Startup . "\Rabbit.lnk"), SetupTrayMenu()))
    } else {
        A_TrayMenu.Add("添加到开机启动", (*) => (FileCreateShortcut(A_AhkPath, A_Startup . "\Rabbit.lnk", A_ScriptDir, rabbit_script, "玉兔毫输入法", rabbit_ico), SetupTrayMenu()))
    }
    A_TrayMenu.Add("添加到桌面快捷方式", (*) => FileCreateShortcut(A_AhkPath, A_Desktop . "\Rabbit.lnk", A_ScriptDir, rabbit_script, "玉兔毫输入法", rabbit_ico))

    A_TrayMenu.Add()

    A_TrayMenu.Add("仓库主页", (*) => Run("https://github.com/amorphobia/rabbit"))
    A_TrayMenu.Add("参加讨论", (*) => Run("https://github.com/amorphobia/rabbit/discussions"))
    A_TrayMenu.Add("关于", (*) => MsgBox(Format("由 AutoHotkey 实现的 Rime 输入法引擎前端`r`n版本：{}", RABBIT_VERSION), "玉兔毫输入法"))

    A_TrayMenu.Add()

    A_TrayMenu.Add("重新部署", (*) => Deploy())
    if (A_IsSuspended) {
        A_TrayMenu.Add("启用玉兔毫", (*) => ToggleSuspend())
    } else {
        A_TrayMenu.Add("禁用玉兔毫", (*) => ToggleSuspend())
    }
    A_TrayMenu.Add("退出玉兔毫", (*) => ExitApp())
}

Sync() {
    Run(Format("{} `"{}\RabbitDeployer.ahk`" sync 1", A_AhkPath, A_ScriptDir))
    ExitApp()
}
Deploy() {
    Run(Format("{} `"{}\RabbitDeployer.ahk`" deploy 1", A_AhkPath, A_ScriptDir))
    ExitApp()
}
ToggleSuspend() {
    global rime, session_id, box, STATUS_TOOLTIP
    ToolTip()
    if box
        box.Show("Hide")
    rime.clear_composition(session_id)
    Suspend(-1)
    UpdateTrayTip()
    UpdateTrayIcon()
    if RabbitConfig.show_tips {
        ToolTip(A_IsSuspended ? "禁用" : "启用", , , STATUS_TOOLTIP)
        SetTimer(() => ToolTip(, , , STATUS_TOOLTIP), -RabbitConfig.show_tips_time)
    }
    SetupTrayMenu()
}

if IN_MAINTENANCE {
    A_TrayMenu.Disable( "1&") ; 用户资料同步
    ; A_TrayMenu.Disable( "2&") ; seperator
    A_TrayMenu.Disable( "3&") ; 用户文件夹
    A_TrayMenu.Disable( "4&") ; 脚本文件夹
    ; A_TrayMenu.Disable( "5&") ; seperator
    A_TrayMenu.Disable( "6&") ; 开机启动
    ; A_TrayMenu.Disable( "7&") ; seperator
    A_TrayMenu.Disable( "8&") ; 仓库主页
    A_TrayMenu.Disable( "9&") ; 参加讨论
    A_TrayMenu.Disable("10&") ; 关于
    ; A_TrayMenu.Disable("11&") ; seperator
    A_TrayMenu.Disable("12&") ; 重新部署
    A_TrayMenu.Disable("13&") ; 禁用/启用
    A_TrayMenu.Disable("14&") ; 退出玉兔毫
}

ClickHandler(wParam, lParam, msg, hWnd) {
    if !rime || !IsSet(session_id) || !session_id || A_IsSuspended
        return
    if lParam == WM_LBUTTONDOWN {
        RabbitGlobals.on_tray_icon_click := true
    } else if lParam == WM_LBUTTONUP {
        local old_ascii_mode := rime.get_option(session_id, "ascii_mode")
        rime.set_option(session_id, "ascii_mode", !old_ascii_mode)
        local new_ascii_mode := rime.get_option(session_id, "ascii_mode")
        if IsSet(UpdateWinAscii) {
            UpdateWinAscii(new_ascii_mode, true, RabbitGlobals.active_win, true)
        }
        status_text := new_ascii_mode ? ASCII_MODE_TRUE_LABEL_ABBR : ASCII_MODE_FALSE_LABEL_ABBR
        if RabbitConfig.show_tips {
            ToolTip(status_text, , , STATUS_TOOLTIP)
            SetTimer(() => ToolTip(, , , STATUS_TOOLTIP), -RabbitConfig.show_tips_time)
        }
        WinActivate("ahk_exe " . RabbitGlobals.active_win)
        RabbitGlobals.on_tray_icon_click := false
    }
}

UpdateTrayTip(schema_name := TRAY_SCHEMA_NAME, ascii_mode := TRAY_ASCII_MODE, full_shape := TRAY_FULL_SHAPE, ascii_punct := TRAY_ASCII_PUNCT) {
    global TRAY_SCHEMA_NAME, TRAY_ASCII_MODE, TRAY_FULL_SHAPE, TRAY_ASCII_PUNCT
    TRAY_SCHEMA_NAME := schema_name ? schema_name : TRAY_SCHEMA_NAME
    TRAY_ASCII_MODE := !!ascii_mode
    TRAY_FULL_SHAPE := !!full_shape
    TRAY_ASCII_PUNCT := !!ascii_punct
    local ss := A_IsSuspended ? "（已禁用）" : ""
    A_IconTip := Format(
        "玉兔毫 {} {}`n左键切换模式，右键打开菜单`n{} | {} | {}", ss, TRAY_SCHEMA_NAME,
        (TRAY_ASCII_MODE ? ASCII_MODE_TRUE_LABEL : ASCII_MODE_FALSE_LABEL),
        (TRAY_FULL_SHAPE ? FULL_SHAPE_TRUE_LABEL : FULL_SHAPE_FALSE_LABEL),
        (TRAY_ASCII_PUNCT ? ASCII_PUNCT_TRUE_LABEL : ASCII_PUNCT_FALSE_LABEL)
    )
}

UpdateTrayIcon() {
    global TRAY_ASCII_MODE
    TraySetIcon((A_IsSuspended || IN_MAINTENANCE) ? "Lib\rabbit-alt.ico" : (TRAY_ASCII_MODE ? "Lib\rabbit-ascii.ico" : "Lib\rabbit.ico"), , true)
}
