#!/bin/zsh
set -euo pipefail

package_dir="${0:A:h}"
label='local.hyper.sase-popup-closer'
app_name='SASE Popup Closer.app'
source_app="$package_dir/$app_name"
stage_only=false
install_root="$HOME"

if [[ "${1:-}" == '--stage-only' && -n "${2:-}" && "$2" == /* ]]; then
    stage_only=true
    install_root="$2"
elif (( $# != 0 )); then
    print -u2 'Usage: Install.command [--stage-only /absolute/test/directory]'
    exit 1
fi

if (( EUID == 0 )); then
    print -u2 '请使用自己的普通登录账号运行，不要使用 sudo。'
    exit 1
fi

if [[ ! -x "$source_app/Contents/MacOS/SASEPopupCloser" ]]; then
    print -u2 '安装包不完整。请先解压整个 ZIP，再运行 Install.command。'
    exit 1
fi

/usr/bin/codesign --verify --strict "$source_app"
major_version=$(/usr/bin/sw_vers -productVersion)
major_version="${major_version%%.*}"
if (( major_version < 13 )); then
    print -u2 '此安装包需要 macOS 13 或更新版本。'
    exit 1
fi

dest_app="$install_root/Applications/$app_name"
agent_file="$install_root/Library/LaunchAgents/$label.plist"
if [[ -e "$dest_app" || -e "$agent_file" ]]; then
    print -u2 '工具已存在。为避免覆盖原来的程序和权限，请先运行 Uninstall.command。'
    exit 1
fi

/bin/mkdir -p "$install_root/Applications" "$install_root/Library/LaunchAgents" "$install_root/Library/Logs"
/usr/bin/ditto "$source_app" "$dest_app"
/usr/bin/plutil -create xml1 "$agent_file"
/usr/bin/plutil -insert Label -string "$label" "$agent_file"
/usr/bin/plutil -insert ProgramArguments -xml '<array/>' "$agent_file"
/usr/bin/plutil -insert ProgramArguments.0 -string "$dest_app/Contents/MacOS/SASEPopupCloser" "$agent_file"
/usr/bin/plutil -insert RunAtLoad -bool YES "$agent_file"
/usr/bin/plutil -insert KeepAlive -bool YES "$agent_file"
/usr/bin/plutil -insert ThrottleInterval -integer 30 "$agent_file"
/usr/bin/plutil -insert ProcessType -string Background "$agent_file"
/usr/bin/plutil -insert LimitLoadToSessionType -string Aqua "$agent_file"
/usr/bin/plutil -insert StandardOutPath -string "$install_root/Library/Logs/SASEPopupCloser.log" "$agent_file"
/usr/bin/plutil -insert StandardErrorPath -string "$install_root/Library/Logs/SASEPopupCloser.error.log" "$agent_file"
/bin/chmod 644 "$agent_file"
/usr/bin/plutil -lint "$agent_file"

if $stage_only; then
    print '测试目录部署完成；未启动程序，未加载登录项，未打开系统设置。'
    exit 0
fi

launch_domain="gui/$(/usr/bin/id -u)"
/bin/launchctl enable "$launch_domain/$label"
/bin/launchctl bootstrap "$launch_domain" "$agent_file"
print '已安装并设置登录自动运行。最后请手动开启 SASE Popup Closer 的辅助功能权限。'
print '位置：系统设置 → 隐私与安全性 → 辅助功能。'
print "若列表中没有它，点 + 添加：$dest_app"
print '请给关窗工具授权，不要给 SASE 授权。无需录屏或完全磁盘访问权限。'
/usr/bin/open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'
