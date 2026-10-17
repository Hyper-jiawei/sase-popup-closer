#!/bin/zsh
set -euo pipefail

if (( EUID == 0 )); then
    print -u2 '请使用自己的普通登录账号运行，不要使用 sudo。'
    exit 1
fi

label='local.hyper.sase-popup-closer'
launch_domain="gui/$(/usr/bin/id -u)"
/bin/launchctl bootout "$launch_domain/$label" 2>/dev/null || true

trash_dir="$HOME/.Trash/SASEPopupCloser-$(/bin/date +%Y%m%d-%H%M%S)-$$"
/bin/mkdir -p "$trash_dir"
for item in \
    "$HOME/Applications/SASE Popup Closer.app" \
    "$HOME/Library/LaunchAgents/$label.plist" \
    "$HOME/Library/Logs/SASEPopupCloser.log" \
    "$HOME/Library/Logs/SASEPopupCloser.error.log"; do
    if [[ -e "$item" ]]; then /bin/mv "$item" "$trash_dir/"; fi
done
print "已停止自动关窗，并将工具、登录项和日志移到废纸篓：$trash_dir"
print '可在系统设置 → 隐私与安全性 → 辅助功能中移除 SASE Popup Closer。'
