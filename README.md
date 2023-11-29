# 🐇️玉兔毫

由 [AutoHotkey](https://www.autohotkey.com/) 实现的 [Rime 输入法引擎](https://github.com/rime/librime)前端

## 下载体验

> [!WARNING]
> ⚠️正在施工⚠️
> 现在已经可轻量地使用，遇到问题可以在 [Issues](https://github.com/amorphobia/rime-jiandao/issues/new/choose) 反馈。

### Action 版

需要先登录你的 GitHub 账号。

前往 [Actions 页面](https://github.com/amorphobia/rabbit/actions) 找到最近成功构建的一次，在生成的 Artifacts 中点击 `Rabbit-Full` 下载，将压缩包内容解压到一个新建目录中，运行 `Rabbit.exe` 即可。之后更新时，可只下载 `Rabbit` 或 `SharedSupport` 覆盖相应的文件。

一般来说，Action 版比 Release 版更新，可能会修复一些问题，也可能会引入更多问题（我太菜了😭️）

### Release 版

发行版会在 [Release 页面](https://github.com/amorphobia/rabbit/releases) 的 Assets 中，下载最新的 `rabbit-v<版本号>.zip`，解压到一个新建文件夹，运行 `Rabbit.exe` 即可。

## 开源许可

[GPL-3.0](LICENSE)

## 使用的开源项目

- [librime](https://github.com/rime/librime)
- [OpenCC](https://github.com/BYVoid/OpenCC)
- [librime-ahk](https://github.com/amorphobia/librime-ahk)
- [GetCaretPos](https://github.com/Descolada/AHK-v2-libraries)
- [rime-prelude](https://github.com/rime/rime-prelude)
- [🌟️星空键道](https://github.com/amorphobia/rime-jiandao)
- [朙月拼音](https://github.com/rime/rime-luna-pinyin)
- [八股文](https://github.com/rime/rime-essay)

以及一些代码片段，在注释中注明了来源链接

## 已知问题

- 候选框图形界面较为简陋，有闪烁等问题
- 某些情况无法获得输入光标的坐标
- 因热键冲突而取消了一些按键注册
- 与某些软件适配较差
