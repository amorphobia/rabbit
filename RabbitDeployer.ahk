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
    SetupTrayMenu()

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
            opt := RABBIT_NO_MAINTENANCE
    }

    if args.Length > 1 {
        Run(Format("{} `"{}\Rabbit.ahk`" {} {}", A_AhkPath, A_ScriptDir, opt, res))
        ExitApp()
    }
    return res
}

ExitRabbitDeployer(reason, code) {
    TrayTip()
}

CreateFileIfNotExist(filename) {
    user_data_dir := RabbitUserDataPath() . "\"
    if not InStr(DirExist(user_data_dir), "D")
        DirCreate(user_data_dir)
    filepath := user_data_dir . filename
    if not InStr(FileExist(filepath), "N")
        FileAppend("", filepath)
}

ConfigureSwitcher(levers, switcher_settings, &reconfigured) {
    if !IsSet(reconfigured)
        reconfigured := false
    if not levers.load_settings(switcher_settings)
        return false
    ; To mimic a dialog
    result := {
        yes : false
    }
    dialog := SwitcherSettingsDialog(switcher_settings, result)
    dialog.Show()
    WinWaitClose(dialog)

    if result.yes {
        if levers.save_settings(switcher_settings)
            reconfigured := true
        return true
    }
    return false
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

        if !skip_switcher_settings {
            ConfigureSwitcher(levers, switcher_settings, &reconfigured)
        }

        levers.custom_settings_destroy(switcher_settings)

        if installing || reconfigured
            return this.UpdateWorkspace()

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

class SwitcherSettingsDialog extends Gui {
    __New(settings, result) {
        super.__New(, "【玉兔毫】方案选单设定", this)
        this.settings := settings
        this.loaded := false
        this.modified := false
        this.api := RimeLeversApi()

        this.item_data := Map()
        this.result := result

        ; Layout
        this.MarginX := 15
        this.MarginY := 15
        this.AddText(, "请勾选所需的输入方案：")
        this.schema_list := this.AddListView("Section Checked NoSort w220 h175", ["方案名称"])
        this.schema_list.OnEvent("Click", (ctrl, lvid) => this.OnSchemaListClick(lvid))
        this.schema_list.OnEvent("ItemCheck", (ctrl, lvid, checked) => this.OnSchemaListItemCheck(lvid, checked))
        this.description := this.AddText("YP w285 h175", "选中列表中的输入方案以查看简介")
        this.AddText("XS", "在玉兔毫里，以下快捷键可唤出方案选单，以切换模式或选用其他输入方案。")
        this.hotkeys := this.AddEdit("-Multi ReadOnly r1 w505")
        this.more_schemas := this.AddButton("Disabled w155", "获取更多输入方案…")
        this.ok := this.AddButton("X+60 YP w90", "中")
        this.ok.OnEvent("Click", (*) => this.OnOK())

        this.Populate()
    }

    Populate() {
        if !this.settings
            return
        local available := this.api.get_available_schema_list(this.settings)
        local selected := this.api.get_selected_schema_list(this.settings)
        this.schema_list.Delete()

        local recruited := Map()

        local selected_list := selected.list
        local available_list := available.list
        Loop selected.size {
            local schema_id := selected_list[A_Index].schema_id
            Loop available.size {
                item := available_list[A_Index]
                info := RimeSchemaInfo(item)
                if item.schema_id == schema_id && (!recruited.Has(info.Ptr) || recruited[info.Ptr] == false) {
                    recruited[info.Ptr] := true
                    row := this.schema_list.Add("Check", item.name)
                    this.item_data[row] := info
                    break
                }
            }
        }
        Loop available.size {
            item := available_list[A_Index]
            info := RimeSchemaInfo(item)
            if !recruited.Has(info.Ptr) || recruited[info.Ptr] == false {
                recruited[info.Ptr] := true
                row := this.schema_list.Add(, item.name)
                this.item_data[row] := info
            }
        }
        txt := this.api.get_hotkeys(this.settings)
        this.hotkeys.Value := txt
        this.loaded := true
        this.modified := false
    }

    OnSchemaListClick(lvid) {
        if !this.loaded || !this.schema_list || lvid <= 0 || lvid > this.schema_list.GetCount() {
            return
        }
        this.ShowDetails(this.item_data[lvid])
    }

    OnSchemaListItemCheck(lvid, checked) {
        if !this.loaded || !this.schema_list || lvid <= 0 || lvid > this.schema_list.GetCount() {
            return
        }
        this.modified := true
    }

    ShowDetails(info) {
        if !info
            return
        details := ""
        if name := this.api.get_schema_name(info)
            details .= name
        if author := this.api.get_schema_author(info)
            details .= "`r`n`r`n" . author
        if description := this.api.get_schema_description(info)
            details .= "`r`n`r`n" . description
        this.description.Value := details
    }

    OnOK() {
        if this.modified && !!this.settings && this.schema_list.GetCount() != 0 {
            selection := []
            row := 0
            while row := this.schema_list.GetNext(row, "Checked") {
                if info := this.item_data[row]
                    selection.Push(this.api.get_schema_id(info))
            }
            if selection.Length == 0 {
                MsgBox("至少要选用一项吧。", "玉兔毫不是这般用法", "Icon!")
                return
            }
            this.api.select_schemas(this.settings, selection)
        }
        this.Exit(true)
    }

    Exit(yes) {
        this.result.yes := yes
        this.Destroy()
    }
}
