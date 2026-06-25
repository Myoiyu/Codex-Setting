# CLAUDE.md 规则入口

本文件是 Claude 用户级规则入口，只保留模块化规则索引，不承载大段规则正文。

执行任务时，必须按任务类型读取并遵守 `~/.claude/rules/` 下的对应规则文件。不要只根据文件名推测规则内容。

## 跨会话记忆

所有任务都必须额外读取并遵守：

- `~/.claude/rules/session-memory.md`

## 通用规则

所有任务都必须先读取并遵守：

- `~/.claude/rules/coding.md`
- `~/.claude/rules/code-change-command.md`
- `~/.claude/rules/language.md`

## 报告与文档输出

当任务需要输出 Markdown 报告、分析文档、流程说明、架构说明、对外流转结论或阶段总结时，必须额外读取并遵守：

- `~/.claude/rules/report-style.md`

## 大日志与多分片日志分析

当任务涉及读取、搜索、分析大体积日志、滚动日志、多分片日志、串口日志、kernel 日志、logcat、CTS/XTS 日志、pstore/last_kmsg 等内容时，必须额外读取并遵守：

- `~/.claude/rules/large-log-analysis.md`

## Android 调试任务

当任务涉及 Android 日志、系统调试、STR、待机唤醒、PowerManager、kernel suspend、Framework、应用触发待机等问题时，必须额外读取并遵守：

- `~/.claude/rules/question-ask.md`

## 维护约定

- 新增规则时，优先放入 `~/.claude/rules/` 下的独立文件。
- 只有当新规则需要被 Claude 发现时，才在本文件中增加索引和触发条件。
- 如果规则之间存在冲突，以用户当前明确指令优先，其次以更具体的任务规则优先。
