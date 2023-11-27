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

#Include <librime-ahk\rime_api>
#Include <librime-ahk\rime_levers_api>

global rime := RimeApi()
global RABBIT_IME_NAME := "玉兔毫"
global RABBIT_CODE_NAME := "Rabbit"
global RABBIT_VERSION := "0.1.0"
global RABBIT_NO_MAINTENANCE := "0"
global RABBIT_PARTIAL_MAINTENANCE := "1"
global RABBIT_FULL_MAINTENANCE := "2"

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
    traits.shared_data_dir := "SharedSupport"
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
