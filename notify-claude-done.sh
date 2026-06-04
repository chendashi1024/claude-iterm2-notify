#!/usr/bin/env bash
# Claude 完成后发送通知，点击跳转到对应 iTerm2 标签页
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_ID="${1:-$ITERM_SESSION_ID}"

if [ -z "$SESSION_ID" ]; then
  echo "错误: 未提供 SESSION_ID" >&2
  exit 1
fi

# 自动查找 Python3 路径（优先用 homebrew/framework 版本）
PYTHON3=$(command -v python3 2>/dev/null || echo "/usr/bin/python3")

# 自动查找 terminal-notifier
TERMINAL_NOTIFIER=$(command -v terminal-notifier 2>/dev/null || echo "/opt/homebrew/bin/terminal-notifier")

exec "$TERMINAL_NOTIFIER" \
  -title '✅ Claude 任务完成' \
  -message '点击跳转到对应的 iTerm2 标签页' \
  -execute "$PYTHON3 $SCRIPT_DIR/iterm-activate.py $SESSION_ID" \
  -sound default
