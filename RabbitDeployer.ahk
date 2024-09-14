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
#Requires AutoHotkey v2.0
#SingleInstance Ignore

;@Ahk2Exe-SetInternalName rabbit-deployer
;@Ahk2Exe-SetProductName 玉兔毫部署应用
;@Ahk2Exe-SetOrigFilename RabbitDeployer.ahk

#Include <RabbitCommon>
#Include <RabbitTrayMenu>

global IN_MAINTENANCE := true
global rime
global INVALID_FILE_ATTRIBUTES := -1
global FILE_ATTRIBUTE_DIRECTORY := 0x00000010

OnExit(ExitRabbitDeployer)

RunDeployer(A_Args)

RunDeployer(args) {
    IN_MAINTENANCE := true
    UpdateTrayIcon()
    TrayTip()
    TrayTip("维护中", RABBIT_IME_NAME)

    command := args.Length > 0 ? args[1] : ""
    conf := Configurator()
    conf.Initialize()
    switch command {
        case "deploy":
            res := conf.UpdateWorkspace()
            opt := RABBIT_NO_MAINTENANCE
        case "dict":
            res := 0 ; conf.DictManagement()
            opt := RABBIT_PARTIAL_MAINTENANCE
        case "sync":
            res := conf.SyncUserData()
            opt := RABBIT_PARTIAL_MAINTENANCE
        default:
            res := conf.Run(command = "install")
            opt := RABBIT_PARTIAL_MAINTENANCE ; TODO: check if need maintenance
    }

    if args.Length > 1 {
        sp := " "
        target := A_AhkPath . sp . A_ScriptDir . "\Rabbit.ahk"
        Run(target . sp . opt . sp . String(res))
        ExitApp()
    }
    return res
}

ExitRabbitDeployer(reason, code) {
    TrayTip()
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
        mutex := RabbitMutex()
        if not mutex.Create() {
            ; TODO: log error
            return 1
        }

        {
            rime.deploy()
            rime.deploy_config_file("rabbit.yaml", "config_version")
        }

        mutex.Close()

        return 0
    }

    ; DictManagement()

    SyncUserData() {
        mutex := RabbitMutex()
        if not mutex.Create() {
            ; TODO: log error
            return 1
        }

        {
            if not rime.sync_user_data() {
                mutex.Close()
                return 1
            }
            rime.join_maintenance_thread()
        }

        mutex.Close()

        return 0
    }
}
