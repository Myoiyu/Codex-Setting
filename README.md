# Codex Setting

个人 Codex / Claude 配置备份，用于在新项目或新电脑上快速恢复规则入口、规则文件和自定义 skills。

## 内容

- `.codex/AGENTS.md`：Codex 用户级规则入口。
- `.codex/rules/`：Codex 模块化规则。
- `.codex/skills/`：自定义 Codex skills，已将本机符号链接展开为普通目录。
- `.codex/config.example.toml`：脱敏后的 Codex 配置模板。
- `.claude/CLAUDE.md`：Claude 用户级规则入口。
- `.claude/rules/`：Claude 模块化规则。
- `.claude/skills/`：Claude 自定义 skills。
- `scripts/`：恢复脚本。

## 恢复到新电脑

Windows PowerShell：

```powershell
git clone https://github.com/Myoiyu/Codex-Setting.git
cd Codex-Setting
.\scripts\install-windows.ps1
```

Linux / macOS / WSL：

```bash
git clone https://github.com/Myoiyu/Codex-Setting.git
cd Codex-Setting
bash scripts/install-unix.sh
```

安装脚本默认不会覆盖已有的 `~/.codex/config.toml`。Windows 下需要覆盖时使用：

```powershell
.\scripts\install-windows.ps1 -OverwriteConfig
```

## 需要手动补充的内容

`.codex/config.example.toml` 已移除真实 token、本机 runtime 路径、历史项目信任列表和 hook hash。复制为 `~/.codex/config.toml` 后，请按新机器实际情况补充：

- API token 或改用系统环境变量管理。
- Codex 桌面端生成的 runtime / MCP 路径。
- 需要信任的项目路径。
- 需要启用的本地 hooks。

## 不应提交的内容

不要提交以下内容：

- `auth.json`、真实 token、PAT、API key。
- `sessions/`、`history.jsonl`、`session_index.jsonl`。
- SQLite 状态库、日志库、缓存、临时目录。
- 本机绝对路径生成的 runtime 配置。

已经暴露过的 token 应立即在对应平台撤销并重新生成。
