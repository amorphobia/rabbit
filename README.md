# 🐇️玉兔毫

由 [AutoHotkey](https://www.autohotkey.com/) 实现的 [Rime 输入法引擎](https://github.com/rime/librime)前端

## 开源许可

[GPL-3.0](LICENSE)

## 使用的开源项目

- [librime](https://github.com/rime/librime)
- [librime-ahk](https://github.com/amorphobia/librime-ahk)
- [GetCaretPos](https://github.com/Descolada/AHK-v2-libraries)
- [🌟️星空键道](https://github.com/amorphobia/rime-jiandao)
- [朙月拼音](https://github.com/rime/rime-luna-pinyin)

以及一些代码片段，在注释中注明了来源链接

## ⚠️正在施工⚠️

目前仅实现了一个原型，上下文界面使用 [ToolTip](https://www.autohotkey.com/docs/v2/lib/ToolTip.htm) 简单显示，但已经可以用来输入了，此 README 文件就是使用玉兔毫部署的[星空键道](https://github.com/amorphobia/rime-jiandao)方案编写。可以在 Actions 里找到自动打包的文件，解压后运行 `Rabbit.exe` 即可。

## 已知问题

- 尚未实现足够多的图形界面，无合适的候选框
- 尚未实现基础设置功能，如重新部署、同步等（在搞定多线程问题之前，重新部署使用 `Reload` 作为临时方案）
- 某些窗口拿不到输入光标所在的坐标，ToolTip 会跟随鼠标光标的位置显示
- 注册热键的问题，例如，上档键输入的字符似乎需要额外注册；热键过多，注册会比较耗时等问题（已取消 Win 键的相关注册，应该有所缓解）
- 并非使用系统的输入法接口，而是用热键的方式获取按键，可能导致一些问题，如，需要保留一个英文输入语言；退出玉兔毫时，可能无法恢复先前的输入法语言等
- 管理员权限打开的窗口应该不起作用
- Windows 远程桌面连接中，不应拦截切换 ascii mode 的热键，而是交给远程桌面控制
