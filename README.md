# claude-iterm2-notify

> Claude 任务跑完了，切到别的窗口干等？通知来了，点一下，回到正在等你的那个标签页。

Claude Code 处理长任务时你切去干别的事，回来发现早就完成了但白白浪费了几分钟。这个工具让你放下键盘去刷 Twitter、写文档、修另一个 bug，任务完成的一刻 macOS 通知弹出，点击直接跳转回对应的 iTerm2 标签页——精准到窗口和标签，不干扰你其他的 iTerm2 窗口。

**与 terminal-notifier 的 `-activate` 不同**：后者会把 iTerm2 所有窗口全部拉到前台。这个方案用 iTerm2 Python API 做三层精准激活：先选中目标 session，再单独激活所在窗口，最后 macOS 级别强制前台。其他 iTerm2 窗口保持原样。

## 效果

```
你在 Chrome 里读文档
      ↓
Claude 任务完成 → macOS 通知弹出
      ↓
点击通知 → 目标 iTerm2 窗口+标签页精准弹出（其他窗口不受影响）
```

## 适用场景

- **并行任务**：一边等 Claude 跑长任务，一边在别的窗口做事
- **多窗口工作流**：多个 iTerm2 窗口各自跑不同的 Claude 会话，通知精准定位
- **全屏/多桌面**：iTerm2 在其他桌面空间也能正确弹出

## 前置要求

| 组件 | 安装方式 | 用途 |
|------|---------|------|
| macOS + iTerm2 | 系统自带 / [iterm2.com](https://iterm2.com) | 终端 |
| Homebrew | [brew.sh](https://brew.sh) | 安装 terminal-notifier |
| terminal-notifier | `brew install terminal-notifier` | 发送 macOS 通知 |
| Python 3 + iterm2 包 | `python3 -m pip install iterm2` | iTerm2 Python API |
| iTerm2 Python API | Settings → General → Magic → 勾选 Enable Python API | 允许脚本控制 iTerm2 |

## 30 秒安装

**把这段话发给 Claude Code，它会自动完成配置：**

> 请帮我配置 claude-iterm2-notify。步骤：
> 1. `brew install terminal-notifier`
> 2. `python3 -m pip install iterm2`
> 3. 将 iterm-activate.py 和 notify-claude-done.sh 复制到 ~/.claude/，确保脚本有执行权限
> 4. 在 ~/.claude/settings.json 的 hooks.Stop 中添加：
> ```json
> {
>   "matcher": "",
>   "hooks": [{
>     "type": "command",
>     "command": "~/.claude/notify-claude-done.sh $ITERM_SESSION_ID",
>     "timeout": 60
>   }]
> }
> ```
> 5. 运行 `~/.claude/notify-claude-done.sh` 测试
> 6. 提醒我：iTerm2 → Settings → General → Magic → 勾选 Enable Python API 并重启 iTerm2

或者手动执行一键脚本：

```bash
cd claude-iterm2-notify && bash install.sh
```

## 手动安装

### 1. 安装依赖

```bash
brew install terminal-notifier
python3 -m pip install iterm2
```

### 2. 启用 iTerm2 Python API

iTerm2 → **Settings** → **General** → **Magic** → 勾选 **Enable Python API** → 重启 iTerm2

验证：

```bash
python3 -c "import iterm2; print('OK')"
```

### 3. 部署脚本

```bash
cp iterm-activate.py ~/.claude/
cp notify-claude-done.sh ~/.claude/
chmod +x ~/.claude/notify-claude-done.sh
```

### 4. 配置 Stop Hook

编辑 `~/.claude/settings.json`，在 `hooks.Stop` 数组中添加：

```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/notify-claude-done.sh $ITERM_SESSION_ID",
      "timeout": 60
    }
  ]
}
```

> `$ITERM_SESSION_ID` 是 iTerm2 自动注入的环境变量，每个标签页唯一。Hook 执行时 shell 自动展开为具体的 session ID。

### 5. 测试

```bash
~/.claude/notify-claude-done.sh
```

点击通知，确认聚焦到当前标签页。

## 工作原理

```
┌─────────────────────────────────────────────────────────┐
│  Claude 任务完成                                          │
│    → Stop hook 触发 notify-claude-done.sh                 │
│      → terminal-notifier 发送 macOS 通知                  │
│        → 用户点击通知                                     │
│          → iterm-activate.py 执行三层激活：               │
│            1. session.async_activate()  选中目标标签页     │
│            2. window.async_activate()   激活目标窗口       │
│            3. open -b com.googlecode     macOS 强制前台    │
│          → 目标 iTerm2 窗口精准弹出                       │
└─────────────────────────────────────────────────────────┘
```

三层激活缺一不可：

| 层级 | 方法 | 单独使用时的问题 |
|------|------|-----------------|
| 1 | `session.async_activate()` | 聚焦了标签页，但窗口可能不在前台 |
| 2 | `window.async_activate()` | 窗口激活了，但可能被其他应用遮挡 |
| 3 | `open -b com.googlecode.iterm2` | macOS 强制前台，确保不被遮挡 |

只用 `terminal-notifier -activate` 会把 iTerm2 **所有**窗口拉到前台。这个方案用 Python API 代替，只激活目标窗口。

## 为什么不用 `terminal-notifier -activate`

| 方案 | 多窗口 | 精准聚焦 | 依赖 |
|------|--------|---------|------|
| `-activate com.googlecode.iterm2` | ❌ 全部弹出 | ❌ 不聚焦 | 无 |
| `-execute` + `iterm2-focus` | ✅ | ✅ 精准 | iterm2-focus |
| **本方案（Python API）** | ✅ 只弹目标 | ✅ 三层保障 | iterm2 Python 包 |

本方案是唯一同时满足「精准聚焦」和「不干扰其他窗口」的方案。

## 文件说明

```
claude-iterm2-notify/
├── iterm-activate.py         # 核心：iTerm2 Python API 三层激活
├── notify-claude-done.sh     # 入口：读取 SESSION_ID，调用 terminal-notifier
├── install.sh                # 一键安装脚本
└── README.md                 # 本文件
```

### `iterm-activate.py`

接收 session ID（`w0t0p0:UUID` 格式），遍历 iTerm2 所有窗口和标签页，找到匹配的 session 后执行三层激活。找不到目标 session 时退出码为 1。

### `notify-claude-done.sh`

Claude Code Stop hook 的入口。从 `$1` 或 `$ITERM_SESSION_ID` 获取当前 session ID，调用 terminal-notifier 发送通知，将激活命令绑定到通知的点击事件。

### `install.sh`

自动检测环境、安装依赖、部署脚本、配置 settings.json。幂等：重复执行不会重复添加 hook。

## 提示和技巧

### 通知常驻

默认通知几秒后消失。如果需要在屏幕右上角常驻直到点击：

**系统设置 → 通知 → terminal-notifier → 通知样式改为「提示」**

提示样式会显示「显示」和「关闭」两个按钮，点击「显示」触发跳转。

### 多台机器

把 `iterm-activate.py` 和 `notify-claude-done.sh` 放到 dotfiles 仓库，新机器上运行 `install.sh` 即可。

### Hook 只在 iTerm2 中生效

`$ITERM_SESSION_ID` 是 iTerm2 特有的环境变量。在其他终端（Terminal.app、Warp、VS Code 终端）中运行 Claude Code 时，变量为空，脚本会跳过通知。不会报错。

## 卸载

```bash
# 移除脚本
rm -f ~/.claude/iterm-activate.py ~/.claude/notify-claude-done.sh

# 从 settings.json 中删除 Stop hook（手动编辑，删除含 notify-claude-done 的条目）
```

## 故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| 通知不弹出 | terminal-notifier 未安装 | `brew install terminal-notifier` |
| 点击通知无反应 | iterm2 包未安装或 Python 路径不对 | `python3 -m pip install iterm2`，确认 notify-claude-done.sh 中 PYTHON3 路径正确 |
| 点击后显示所有窗口 | 使用了旧版 `-activate` 方案 | 确认 notify-claude-done.sh 不含 `-activate` 参数 |
| `$ITERM_SESSION_ID` 为空 | 不在 iTerm2 中运行 | 这是正常行为，非 iTerm2 终端不会触发通知 |
| `ModuleNotFoundError: No module named 'iterm2'` | 系统 Python 与安装 Python 不一致 | 在 notify-claude-done.sh 中指定完整 Python 路径 |
| iTerm2 Python API 连接失败 | Python API 未启用 | Settings → General → Magic → Enable Python API → 重启 iTerm2 |

## License

MIT
