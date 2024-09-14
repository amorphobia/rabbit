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

global RABBIT_VERSION := "dev"
;@Ahk2Exe-SetCompanyName amorphobia
;@Ahk2Exe-SetCopyright Copyright (c) 2023`, 2024 Xuesong Peng
;@Ahk2Exe-SetDescription 由 AutoHotkey 实现的 Rime 输入法
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-SetVersion %U_version%
;@Ahk2Exe-SetLanguage 0x0804
;@Ahk2Exe-SetMainIcon Rabbit.ico

#Include <librime-ahk\rime_api>
#Include <librime-ahk\rime_levers_api>

global AHK_NOTIFYICON := 0x404
global WM_LBUTTONDOWN := 0x201
global WM_LBUTTONUP := 0x202

global rime := RimeApi()
global RABBIT_IME_NAME := "玉兔毫"
global RABBIT_CODE_NAME := "Rabbit"
global RABBIT_NO_MAINTENANCE := "0"
global RABBIT_PARTIAL_MAINTENANCE := "1"
global RABBIT_FULL_MAINTENANCE := "2"

global TRAY_MENU_GRAYOUT := false
global STATUS_TOOLTIP := 2
global box := 0
global ASCII_MODE_FALSE_LABEL := "中文"
global ASCII_MODE_TRUE_LABEL := "西文"
global ASCII_MODE_FALSE_LABEL_ABBR := "中"
global ASCII_MODE_TRUE_LABEL_ABBR := "西"
global FULL_SHAPE_FALSE_LABEL := "半角"
global FULL_SHAPE_TRUE_LABEL := "全角"
global FULL_SHAPE_FALSE_LABEL_ABBR := "半"
global FULL_SHAPE_TRUE_LABEL_ABBR := "全"
global ASCII_PUNCT_FALSE_LABEL := "。，"
global ASCII_PUNCT_TRUE_LABEL := ". ,"
global ASCII_PUNCT_FALSE_LABEL_ABBR := "。"
global ASCII_PUNCT_TRUE_LABEL_ABBR := "."

global ERROR_ALREADY_EXISTS := 183 ; https://learn.microsoft.com/windows/win32/debug/system-error-codes--0-499-

class RabbitMutex {
    handle := 0
    errmsg := ""
    Create() {
        this.errmsg := ""
        this.handle := DllCall("CreateMutex", "Ptr", 0, "Int", true, "Str", "RabbitDeployerMutex")
        if A_LastError == ERROR_ALREADY_EXISTS {
            this.Close()
            this.errmsg := "mutex already exists"
        }
        return this.handle
    }
    Close() {
        if this.handle {
            DllCall("CloseHandle", "Ptr", this.handle)
            this.handle := 0
        }
    }
}

CreateTraits() {
    traits := RimeTraits()
    traits.distribution_name := RABBIT_IME_NAME
    traits.distribution_code_name := RABBIT_CODE_NAME
    traits.distribution_version := RABBIT_VERSION
    traits.app_name := "rime.rabbit"
    traits.shared_data_dir := "Data"
    traits.user_data_dir := "Rime"

    return traits
}

OnRimeMessage(context_object, session_id, message_type, message_value) {
    msg_type := StrGet(message_type, "UTF-8")
    msg_value := StrGet(message_value, "UTF-8")
    if msg_type = "deploy" {
        if msg_value = "start" {
            TrayTip()
            TrayTip("维护中", RABBIT_IME_NAME)
        } else if msg_value = "success" {
            TrayTip()
            TrayTip("维护完成", RABBIT_IME_NAME)
            SetTimer(TrayTip, -2000)
        } else {
            TrayTip(msg_type . ": " . msg_value . " (" . session_id . ")", RABBIT_IME_NAME)
        }
    } else {
        ; TrayTip(msg_type . ": " . msg_value . " (" . session_id . ")", RABBIT_IME_NAME)
    }
}

class RabbitConfig {
    static suspend_hotkey := ""
    static show_tips := true
    static show_tips_time := 1200
    static global_ascii := false
    static preset_process_ascii := Map()
    static process_ascii := Map()

    static load() {
        global rime
        if !rime || !config := rime.config_open("rabbit")
            return

        RabbitConfig.suspend_hotkey := rime.config_get_string(config, "suspend_hotkey")
        if rime.config_test_get_bool(config, "show_tips", &result)
            RabbitConfig.show_tips := !!result
        if rime.config_test_get_int(config, "show_tips_time", &result) {
            RabbitConfig.show_tips_time := Abs(result)
            if result == 0
                RabbitConfig.show_tips := false
        }

        if rime.config_test_get_bool(config, "global_ascii", &result)
            RabbitConfig.global_ascii := !!result

        if iter := rime.config_begin_map(config, "app_options") {
            while rime.config_next(iter) {
                proc_name := StrLower(iter.key)
                if rime.config_test_get_bool(config, "app_options/" . proc_name . "/ascii_mode", &result) {
                    RabbitConfig.preset_process_ascii[proc_name] := !!result
                    RabbitConfig.process_ascii[proc_name] := !!result
                }
            }
            rime.config_end(iter)
        }

        rime.config_close(config)
    }
}
