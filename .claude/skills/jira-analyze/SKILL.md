---
name: jira-analyze
description: 从 Jira (jira.skyoss.com) 拉取问题单信息、下载附件日志、从评论中提取 Samba 服务器路径并复制日志、结合 STR 分析能力进行问题分析。当用户说"解决XXX单号"、"分析XXX问题"、"处理XXX"等时使用此 skill。支持单号格式：NXXT-123456、PROJ-123 等。
---

# Jira 问题单分析与解决 Skill

## 概述

端到端自动化 Jira 问题解决流程：获取问题单信息 → 下载日志附件 → STR/日志分析 → 输出结论。

## 前置条件

- 必须在公司内网环境
- Jira PAT 已配置在 `~/.claude/.mcp.json` 中（当前 token: `<JIRA_PAT>`）
- 所有 curl 请求必须加 `--noproxy '*'` 参数绕过本地代理

## 日志附件下载目录

- **下载根目录**：`E:\日志\jira_attachments\`（bash 中为 `/e/日志/jira_attachments/`）
- 每个问题单创建独立子目录：`/e/日志/jira_attachments/<问题单号>/`

## 执行流程

### Step 1：从用户输入提取问题单号

从用户消息中提取 Jira 问题单号，格式通常为 `<项目前缀>-<数字>`（如 `NXXT-204684`）。

如果用户没有明确给出单号，必须先询问用户提供单号。

### Step 2：获取问题单基本信息

```bash
curl -s --noproxy '*' -H "Authorization: Bearer <JIRA_PAT>" "http://jira.skyoss.com/rest/api/2/issue/<单号>?fields=summary,description,status,assignee,reporter,created,updated,priority,issuetype,project,labels,components,attachment,comment,resolution"
```

用 node 解析 JSON，提取并展示以下关键字段：

| 字段 | 说明 |
|------|------|
| key | 问题单号 |
| summary | 标题 |
| description | 问题描述 |
| status.name | 当前状态 |
| priority.name | 优先级 |
| assignee.displayName | 经办人 |
| reporter.displayName | 报告人 |
| created | 创建日期 |
| updated | 最后更新 |
| resolution | 解决结果（若为空说明未真正解决） |
| attachment 列表 | 附件文件名、大小、下载URL |

向用户展示问题单概要，然后提出分析计划（是否需要下载附件、分析什么）。

### Step 3：检查评论中的 Samba 服务器路径

在 Step 2 返回的评论中，搜索 Samba 网络路径（通常格式为 `\\172.20.xxx.xxx\share\path\单号` 或 `\\192.168.xxx.xxx\share\path`）。

**提取规则**：
- 匹配模式：`\\\\\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\\[^\s]+`
- 如果匹配到路径，将其转换为 Bash 可访问的 UNC 格式：
  - Windows 格式 `\\172.20.217.11\log_to_share\Hisi\NXXT-207532`
  - 转换为 `//172.20.217.11/log_to_share/Hisi/NXXT-207532`

**列出 Samba 路径下的文件**：
```bash
ls -lh "//172.20.217.11/log_to_share/Hisi/<单号>/"
```

如果路径可访问且存在日志文件，将其目录作为补充日志来源。

### Step 4：从 Samba 复制日志到本地

将 Samba 路径下的所有文件复制到本地分析目录：

```bash
mkdir -p /e/日志/jira_attachments/<单号>/samba_logs/
cp -r "//<ip>/<share>/<path>/<单号>/"* "/e/日志/jira_attachments/<单号>/samba_logs/"
```

复制完成后确认文件列表和大小：
```bash
ls -lh "/e/日志/jira_attachments/<单号>/samba_logs/"
```

**注意**：如果 Samba 路径无法访问（权限问题或网络不通），向用户报告并跳过此步骤，仅使用 Jira 附件。

### Step 5：获取附件列表

附件信息在 Step 2 的返回中已包含，提取以下数据：

- `filename`：文件名
- `size`：文件大小（字节）
- `content`：下载 URL（如 `http://jira.skyoss.com/secure/attachment/1111468/xxx.log`）

对每个附件展示：文件名 + 大小，让用户确认是否需要下载。

### Step 6：下载日志附件

如果用户确认下载，创建目录并下载：

```bash
mkdir -p /e/日志/jira_attachments/<单号>/
curl -s --noproxy '*' -H "Authorization: Bearer <JIRA_PAT>" -o "/e/日志/jira_attachments/<单号>/<文件名>" "http://jira.skyoss.com/secure/attachment/<附件ID>/<文件名>"
```

下载完成后确认文件大小与 Jira 返回一致。

### Step 7：解压压缩包

下载完成后，检查所有日志文件（Jira 附件 + Samba 日志），按扩展名判断是否需要解压：

| 扩展名 | 工具 | 解压命令 |
|--------|------|----------|
| .zip | unzip | `unzip -o "<文件>" -d "<输出目录>"` |
| .7z | Bandizip | `"/c/Program Files/Bandizip/bz.exe" x -o:"<输出目录>" "<文件>"` |
| .rar | Bandizip | `"/c/Program Files/Bandizip/bz.exe" x -o:"<输出目录>" "<文件>"` |
| .gz / .tgz | tar | `tar -xzf "<文件>" -C "<输出目录>"` |
| .tar | tar | `tar -xf "<文件>" -C "<输出目录>"` |

**解压流程**：

```bash
# 对每个压缩包创建独立解压目录
mkdir -p "/e/日志/jira_attachments/<单号>/extracted/<压缩包名去掉扩展名>/"

# .7z 文件使用 Bandizip
"/c/Program Files/Bandizip/bz.exe" x -o:"/e/日志/jira_attachments/<单号>/extracted/<目录名>/" "/e/日志/jira_attachments/<单号>/<压缩包>"

# .zip 文件使用 unzip
unzip -o "/e/日志/jira_attachments/<单号>/<压缩包>" -d "/e/日志/jira_attachments/<单号>/extracted/<目录名>/"
```

**注意**：如果 Bandizip 不可用，尝试用 PowerShell 自带的 `Expand-Archive`（仅支持 .zip）或告知用户手动解压。

### Step 8：日志类型判断与分析

**日志来源**：
1. Jira 附件（`/e/日志/jira_attachments/<单号>/`）
2. Samba 服务器日志（`/e/日志/jira_attachments/<单号>/samba_logs/`）

下载/复制完成后，按文件扩展名判断日志类型：

| 扩展名 | 类型 | 分析策略 |
|--------|------|----------|
| .log / .txt | 串口日志 / logcat | 用 `str-debug` 关键词过滤分析 |
| .logcat | logcat 日志 | 优先 STR 关键词 + 崩溃堆栈 |
| .dmesg | kernel 日志 | 搜索 panic/oops/suspend |
| .txt (pstore) | pstore 日志 | 搜索 panic/last_kmsg |
| .zip / .gz / .tar | 压缩包 | 先解压再分析 |
| .png / .jpg | 截图 | 用 Read 工具查看 |

**日志分析策略**：

1. 先用 `str-debug` skill 的过滤关键词进行初筛：
   ```
   powermanager|str\b|suspend|PM|wakelock|screen_off|screen_on|androidruntime
   ```
2. 根据问题描述中的关键词（如"黑屏"、"待机异常"、"开机失败"）增加针对性搜索
3. 按 `str-debug` skill 的四维分析框架输出结论（待机异常 / 黑屏异常 / 开机异常 / STR 流程完整性）
4. 若有 Java/NE 崩溃，搜索 `FATAL EXCEPTION`、`signal`、`backtrace`

### Step 9：综合输出分析报告

结合问题单信息和日志分析结果，输出结构化报告：

```
=== Jira 问题单分析报告 ===
【问题单号】: XXX-123
【标题】: xxx
【状态】: xxx
【优先级】: xxx
【创建日期】: xxx

--- 日志分析结果 ---
（调用 str-debug 的分析框架输出）

--- 结论 ---
（置信度标注 + 证据链）

--- 下一步建议 ---
（具体可执行的验证动作）
```

## 大日志处理

遵循 `large-log-analysis.md` 规则：
- 超过 100MB 的日志只做关键词搜索，不全文读取
- 超过 10MB 用 grep 过滤后只读命中附近行
- 多个分片时先盘点所有文件，再按时间排序分析

## 注意事项

- Jira token 硬编码在 curl 命令中（内网环境，无外泄风险）
- 所有 curl 请求必须使用 `--noproxy '*'` 绕过本地代理
- 下载的文件保存到 `/e/日志/jira_attachments/<单号>/`
- 分析结论必须区分事实（有日志证据）、推测（推断但未证实）、建议
- 不要编造不存在的日志内容或 Android 接口
