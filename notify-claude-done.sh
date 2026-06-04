#!/usr/bin/env bash
# Claude 完成后发送通知，点击跳转到对应 iTerm2 标签页
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_ID="${1:-$ITERM_SESSION_ID}"

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

PYTHON3=$(command -v python3)
TERMINAL_NOTIFIER=$(command -v terminal-notifier)

exec "$TERMINAL_NOTIFIER" \
  -title '✅ Claude 任务完成' \
  -message '点击跳转到对应的 iTerm2 标签页' \
  -execute "$PYTHON3 $SCRIPT_DIR/iterm-activate.py $SESSION_ID" \
  -sound default
