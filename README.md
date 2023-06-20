# 🐇️玉兔毫

由 [AutoHotkey](https://www.autohotkey.com/) 实现的 [Rime 输入法引擎](https://github.com/rime/librime/)前端

## 开源许可

[GPL-3.0](LICENSE)

## ⚠️正在施工⚠️

目前仅实现了一个原型，上下文界面使用 [ToolTip](https://www.autohotkey.com/docs/v2/lib/ToolTip.htm) 简单显示，但已经可以用来输入了，此 README 文件就是使用玉兔毫部署的[星空键道](https://github.com/xkinput/Rime_JD)方案编写。

## 已知问题

- 尚未实现足够多的图形界面
- 某些窗口拿不到输入光标所在的坐标，ToolTip 会跟随鼠标光标的位置显示
- 注册热键的问题，例如，上档键输入的字符似乎需要额外注册；热键过多，注册会比较耗时等问题
- 并非使用系统的输入法接口，而是用热键的方式获取按键，可能导致一些问题，如，需要保留一个英文输入法；退出玉兔毫时，可能无法恢复先前的输入法语言等
- 管理员权限打开的窗口应该不起作用
