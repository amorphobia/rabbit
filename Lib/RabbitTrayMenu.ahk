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

TraySetIcon("Rabbit.ico") ; https://www.freepik.com/icon/rabbit_4905239
A_TrayMenu.Delete()
A_TrayMenu.add("打开用户文件夹", (*) => Run(A_ScriptDir . "\Rime"))
A_TrayMenu.add("打开脚本文件夹", (*) => Run(A_ScriptDir))
A_TrayMenu.add()
A_TrayMenu.add("仓库主页", (*) => Run("https://github.com/amorphobia/rabbit"))
A_TrayMenu.add()
A_TrayMenu.add("重新部署", (*) => Deploy(true))
A_TrayMenu.Disable("重新部署")
A_TrayMenu.add("退出玉兔毫", (*) => ExitApp())