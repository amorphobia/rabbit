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

#Include "librime-ahk\rime_api.ahk"

on_message(context_object, session_id, message_type, message_value) {
    msg_type := StrGet(message_type, "UTF-8")
    msg_value := StrGet(message_value, "UTF-8")
    if msg_type = "deploy" {
        if msg_value = "start" {
            TrayTip()
            TrayTip("维护中", "玉兔颖")
        } else if msg_value = "success" {
            TrayTip()
            TrayTip("维护完成", "玉兔颖")
            SetTimer(TrayTip, -2000)
        } else {
            TrayTip(msg_type . ": " . msg_value . " (" . session_id . ")", "玉兔颖")
        }
    } else {
        TrayTip(msg_type . ": " . msg_value . " (" . session_id . ")", "玉兔颖")
    }
}

deploy(full_check := true) {
    rime := RimeApi()
    traits := RimeTraits()
    traits.app_name := "rime.rabbit"
    traits.shared_data_dir := "SharedSupport"
    traits.user_data_dir := "rime"

    rime.setup(traits)
    rime.set_notification_handler(on_message, 0)
    rime.initialize(0)

    success := rime.start_maintenace(full_check)
    if success {
        rime.join_maintenance_thread()
    }
}
