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
; #NoTrayIcon

#Include <RabbitCommon>
#Include <librime-ahk\rime_levers_api>

global rime
global ERROR_ALREADY_EXISTS := 183
global INVALID_FILE_ATTRIBUTES := -1
global FILE_ATTRIBUTE_DIRECTORY := 0x00000010

arg := A_Args.Length > 0 ? A_Args[1] : ""
RunDeployer(arg)

RunDeployer(command) {
    conf := Configurator()
    conf.Initialize()
    deployment_scheduled := command == "deploy"
    if deployment_scheduled
        return conf.UpdateWorkspace()
    dict_management := command == "dict"
    if dict_management
        return 0 ; return conf.DictManagement()
    sync_user_dict := command == "sync"
    if sync_user_dict
        return conf.SyncUserData()
    installing := command == "install"
    return conf.Run(installing)
}

CreateFileIfNotExist(filename) {
    user_data_dir := A_ScriptDir . "\Rime\"
    if not InStr(DirExist(user_data_dir), "D")
        DirCreate(user_data_dir)
    filepath := user_data_dir . filename
    if not InStr(FileExist(filepath), "N")
        FileAppend("", filepath)
}

ConfigureSwitcher(levers, switcher_settings, reconfigured) {
    if not levers.load_settings(switcher_settings)
        return false
    ; 
}

class Configurator extends Class {
    __New() {
        CreateFileIfNotExist("default.custom.yaml")
        CreateFileIfNotExist("rabbit.custom.yaml")
    }

    Initialize() {
        rabbit_traits := CreateTraits()
        rime.setup(rabbit_traits)
        rime.deployer_initialize(0)
    }

    Run(installing) {
        levers := RimeLeversApi()
        if not levers
            return 1

        switcher_settings := levers.switcher_settings_init()
        skip_switcher_settings := installing && !levers.is_first_run(switcher_settings)

        if installing
            this.UpdateWorkspace()

        return 0
    }

    UpdateWorkspace(report_errors := false) {
        hMutex := DllCall("CreateMutex", "Ptr", 0, "Int", true, "Str", "RabbitDeployerMutex")
        if not hMutex {
            return 1
        }
        if DllCall("GetLastError") == ERROR_ALREADY_EXISTS {
            DllCall("CloseHandle", "Ptr", hMutex)
            return 1
        }

        {
            rime.deploy()
            ; rime.deploy_config_file("rabbit.yaml", "config_version")
        }

        DllCall("CloseHandle", "Ptr", hMutex)

        return 0
    }

    ; DictManagement()

    SyncUserData() {
        hMutex := DllCall("CreateMutex", "Ptr", 0, "Int", true, "Str", "RabbitDeployerMutex")
        if not hMutex {
            return 1
        }
        if DllCall("GetLastError") == ERROR_ALREADY_EXISTS {
            DllCall("CloseHandle", "Ptr", hMutex)
            return 1
        }

        {
            if not rime.sync_user_data() {
                DllCall("CloseHandle", "Ptr", hMutex)
                return 1
            }
            rime.join_maintenance_thread()
        }

        DllCall("CloseHandle", "Ptr", hMutex)

        return 0
    }
}
