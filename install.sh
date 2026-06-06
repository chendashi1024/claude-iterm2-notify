#!/usr/bin/env bash
set -e

echo "============================================"
echo " Claude Code iTerm2 通知聚焦 一键安装"
echo "============================================"
echo ""
echo " 💡 提示：你也可以直接把仓库地址丢给 Claude Code，让它帮你装："
echo "    \"帮我装一下 https://github.com/chendashi1024/claude-iterm2-notify\""
echo "    遇到问题它还能自动排查，比手动装更省事。"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# ---------- 1. 安装 terminal-notifier ----------
echo "[1/5] 检查 terminal-notifier..."
if command -v terminal-notifier &>/dev/null; then
  echo "  ✅ 已安装: $(command -v terminal-notifier)"
else
  echo "  📦 安装中..."
  brew install terminal-notifier
  echo "  ✅ 安装完成"
fi

# ---------- 2. 安装 iterm2 Python 包 ----------
echo "[2/5] 检查 iTerm2 Python API..."
PYTHON3=$(command -v python3 2>/dev/null || echo "")
if [ -z "$PYTHON3" ]; then
  echo "  ❌ 未找到 python3，请先安装 Python 3"
  exit 1
fi

if $PYTHON3 -c "import iterm2" 2>/dev/null; then
  echo "  ✅ iterm2 包已安装"
else
  echo "  📦 安装 iterm2 Python 包..."
  $PYTHON3 -m pip install iterm2 iterm2-focus
  echo "  ✅ 安装完成"
fi

# ---------- 3. 复制脚本 ----------
echo "[3/5] 安装脚本到 ~/.claude/..."
chmod +x "$SCRIPT_DIR/notify-claude-done.sh"
chmod +x "$SCRIPT_DIR/iterm-activate.py"
cp "$SCRIPT_DIR/notify-claude-done.sh" "$CLAUDE_DIR/notify-claude-done.sh"
cp "$SCRIPT_DIR/iterm-activate.py" "$CLAUDE_DIR/iterm-activate.py"
echo "  ✅ 脚本已复制"

# ---------- 4. 配置 settings.json ----------
echo "[4/5] 配置 Claude Code Stop hook..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{"hooks":{"Stop":[]}}' > "$SETTINGS_FILE"
fi

# 用 Python 处理 JSON（更可靠）
$PYTHON3 << PYEOF
import json, os

settings_path = os.path.expanduser("$SETTINGS_FILE")
with open(settings_path) as f:
    cfg = json.load(f)

cfg.setdefault("hooks", {})
cfg["hooks"].setdefault("Stop", [])

# 检查是否已经存在我们的 hook
hook_cmd = "$CLAUDE_DIR/notify-claude-done.sh \$ITERM_SESSION_ID"
already_exists = False
for entry in cfg["hooks"]["Stop"]:
    for h in entry.get("hooks", []):
        if "notify-claude-done" in h.get("command", ""):
            already_exists = True
            break

if already_exists:
    print("  ✅ Stop hook 已配置（跳过）")
else:
    new_entry = {
        "matcher": "",
        "hooks": [{
            "type": "command",
            "command": hook_cmd,
            "timeout": 60
        }]
    }
    cfg["hooks"]["Stop"].append(new_entry)
    with open(settings_path, "w") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
    print("  ✅ Stop hook 已添加")
PYEOF

# ---------- 5. 检查环境 ----------
echo "[5/5] 环境检查..."

# 检查 ITERM_SESSION_ID
if [ -n "$ITERM_SESSION_ID" ]; then
  echo "  ✅ ITERM_SESSION_ID: $ITERM_SESSION_ID"
else
  echo "  ⚠️  未检测到 ITERM_SESSION_ID，请确保在 iTerm2 中运行"
fi

# 检查 iTerm2 Python API
if $PYTHON3 -c "
import iterm2
async def check():
    try:
        conn = await iterm2.Connection.async_create()
        print('  ✅ iTerm2 Python API 已启用')
        await conn.async_close()
    except Exception as e:
        print(f'  ❌ iTerm2 Python API 未启用: {e}')
        print('     请在 iTerm2 → Settings → General → Magic → 勾选 Enable Python API 后重启')
import asyncio
asyncio.run(check())
" 2>/dev/null; then
  :
else
  echo "  ⚠️  无法验证 iTerm2 Python API，请手动确认已启用"
fi

echo ""
echo "============================================"
echo " 安装完成！"
echo ""
echo " 测试命令："
echo "   ~/.claude/notify-claude-done.sh"
echo ""
echo " 💡 如果通知没弹出来，把这段丢给 Claude Code："
echo "   \"我刚装完 claude-iterm2-notify，通知没出来，帮我排查\""
echo " 它会自动诊断 ncprefs.plist flags、API 连接等问题"
echo ""
echo " 如果通知需要常驻，去系统设置 → 通知 → terminal-notifier → 改为「提示」"
echo "============================================"
