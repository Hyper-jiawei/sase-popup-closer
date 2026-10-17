# SASE Popup Closer for macOS

自动关闭阿里云 SASE 的“服务授权”提醒窗口。每 3 秒检查一次，只匹配指定的应用标识和窗口标题。

## 快速安装

**[下载 Mac 安装包](https://github.com/Hyper-jiawei/sase-popup-closer/raw/refs/heads/main/downloads/SASEPopupCloser-Mac.zip)**

支持 Apple 芯片及 Intel Mac，最低 macOS 13。无需 Xcode、Python、Homebrew 或 sudo。

1. 下载并解压 `SASEPopupCloser-Mac.zip`。
2. 双击文件夹中的 `Install.command`。
3. 前往“系统设置 → 隐私与安全性 → 辅助功能”，开启 **SASE Popup Closer**。
   若列表中没有它，点击 `+`，添加 `~/Applications/SASE Popup Closer.app`。
4. 此后每次登录 Mac，工具都会自动运行。需要卸载时双击 `Uninstall.command`。

每台电脑都需要使用者亲自批准权限，无法把另一台电脑的权限一起复制过去。
工具采用临时签名，尚未经 Apple Developer ID 签名或公证，首次打开可能被系统拦截。
确认来源和源码后，按 [Apple 官方说明](https://support.apple.com/102445)对该文件选择“仍要打开”。
不需要关闭 Gatekeeper 或 SIP。

## 工作原理

```text
当前用户登录
    ↓
launchd 启动后台工具
    ↓
每 3 秒定位 com.aliyun.security.sase
    ↓
窗口标题完全等于“SASE服务授权”或“SASE Service Authorization”？
    ↓ 是
通过 Accessibility API 点击该窗口的标准关闭按钮
```

代码使用 `NSRunningApplication` 找到 SASE，通过 `AXUIElement` 读取这个应用的窗口标题，
仅在匹配时调用 `AXUIElementPerformAction(..., kAXPressAction)` 点击关闭按钮。
源码见 [src/main.swift](src/main.swift)。

## 操作范围与权限

- 只关闭上述授权窗口，不关闭 SASE 主界面、登录窗口、定位权限说明或 macOS 系统权限窗口。
- 不退出 SASE、不连接或断开 VPN、不点击授权按钮。
- 不修改 SASE 程序、企业策略或 macOS 隐私权限数据库。
- 不录屏，没有联网代码。
- 仅需给 **关窗工具** 辅助功能权限，无需给 SASE 新增权限。

macOS 的辅助功能权限本身可控制其他应用，并非只允许控制 SASE。
操作范围由这份工具的源码限制；请只运行可信的程序。
参见 [Apple 辅助功能授权说明](https://support.apple.com/guide/mac-help/mh43185/mac)。

工具以当前用户的 LaunchAgent 运行，不是 root 系统服务；退出登录后停止。
弹窗创建与检测之间可能短暂闪现。SASE 更新应用标识、窗口标题或关闭按钮行为后，可能需要更新本工具。
它只关闭提醒界面，不改变公司对 VPN 的准入要求。

## 安装位置

| 内容 | 路径 |
| --- | --- |
| 后台程序 | `~/Applications/SASE Popup Closer.app` |
| 登录启动项 | `~/Library/LaunchAgents/local.hyper.sase-popup-closer.plist` |
| 状态日志 | `~/Library/Logs/SASEPopupCloser.log` |

安装脚本会按当前账号生成路径，既不读取也不打包 SASE 的账号、凭据或公司配置。

## 查看运行状态

```sh
launchctl print "gui/$(id -u)/local.hyper.sase-popup-closer"
tail -20 "$HOME/Library/Logs/SASEPopupCloser.log"
```

`Watcher active` 表示已获权限并正在检查；`Waiting for Accessibility permission`
表示尚未获权限；`Closed SASE authorization window` 表示实际关闭过授权窗口。

直接从终端运行应用内的 `--check` 可能继承终端的权限归属，请以登录代理的日志判断权限状态。

## 暂停与卸载

临时停止，下次登录恢复：

```sh
launchctl bootout "gui/$(id -u)/local.hyper.sase-popup-closer"
```

卸载：运行安装包中的 `Uninstall.command`。它停止工具后，将程序、启动项和日志移到废纸篓。
然后可在系统设置中移除 **SASE Popup Closer** 的辅助功能授权。

## 从源码构建

构建时需要安装 Apple Command Line Tools；使用预编译包不需要。

```sh
git clone https://github.com/Hyper-jiawei/sase-popup-closer.git
cd sase-popup-closer
zsh Build.command
```

输出 `dist/SASEPopupCloser-Mac.zip`，包含 Apple 芯片和 Intel 架构、安装/卸载脚本及源码。
构建不会安装或启动登录代理，也不会修改已有的 SASE 或关窗工具。

## 验证范围

已在 Apple 芯片 Mac 上验证精确匹配逻辑、后台启动及权限状态；已验证安装脚本能处理
包含中文、空格和 `&` 的用户路径，并拒绝覆盖已有安装。
双架构程序及 ZIP 解压后的签名完整性已检查。Intel 版本已编译，尚未实机测试。
实际关窗成功以屏幕表现和日志中的 `Closed SASE authorization window` 为准。

详细步骤见 [安装说明](docs/安装说明.md)。本项目与阿里云无隶属关系。
