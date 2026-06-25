---
name: update-arch-doc
description: 分析 git staged diff，智能更新模块架构文档的正文章节（流程、类关系、字段表、Skyworth Patch 登记等）。当用户修改了受监控模块的代码后、commit 前调用。触发词：更新架构文档、同步架构文档、/update-arch-doc。
---

# 更新模块架构文档

## 概述

分析当前 staged 的代码变更，与对应模块的架构文档进行比对，智能更新文档正文中受影响的章节。

**调用时机**：代码修改 → git add → `/update-arch-doc` → 审查 → git commit（hook 自动追加 changelog）

## 工作流程

### Step 1: 确定目标模块

读取 `~/.config/arch-doc/` 下所有模块的白名单文件，与 staged 文件求交集：

```bash
git diff --cached --name-only
```

对照每个模块的 watchlist（如 `~/.config/arch-doc/cec/cec-standby-watchlist.txt`），确定涉及哪个模块。

**模块注册表**（有新模块时需更新）：

| 模块 | 白名单路径 | 架构文档路径 |
|------|-----------|------------|
| cec | `~/.config/arch-doc/cec/cec-standby-watchlist.txt` | `services/core/java/com/android/server/hdmi/CEC_STANDBY_ARCHITECTURE.md` |
| volume | `~/.config/arch-doc/volume/volume-earc-watchlist.txt` | `packages/SystemUI/src/com/android/systemui/volume/VOLUME_EARC_ARCHITECTURE.md` |

如果无法自动确定，问用户选择模块。

### Step 2: 获取 diff 内容

```bash
git diff --cached -U10 -- <涉及的白名单文件>
```

用 `-U10` 提供充足上下文。

### Step 3: 读取当前架构文档

完整读取对应的架构文档 `.md` 文件。

### Step 4: 分析 diff，定位需要更新的章节

逐章节检查 diff 是否影响该章节描述的内容：

| 章节类型 | 触发更新的 diff 特征 |
|---------|-------------------|
| **文件清单与职责** | 新增/删除/重命名文件 |
| **协作关系 mermaid 图** | 新增/删除类间调用、回调注册、监听器 |
| **关键流程伪代码** | 流程方法体内逻辑变化（新增分支、改变条件、新增步骤） |
| **布局结构** | XML 中新增/删除/重组 View 节点 |
| **扩展字段表** | VolumeRow/类中新增/删除/改名字段 |
| **Skyworth Patch 登记表** | `Skyworth patch start/end` 标记的增删改 |
| **状态标志** | 新增/删除状态变量（boolean/int flags） |

### Step 5: 执行更新

对于每个需要更新的章节：

1. **精准定位**：找到文档中对应章节的起止位置
2. **最小化修改**：只改受 diff 影响的部分，不重写整段
3. **保持风格**：匹配文档现有的格式、缩进、术语
4. **标注来源**：如果新增了内容，确保与代码一致

使用 `search_replace` 工具逐章节更新。

### Step 6: 确认与收尾

1. 展示更新摘要（哪些章节改了什么）
2. 让用户审查
3. 如果用户确认，执行 `git add <架构文档>`

## 更新原则

1. **只改受影响的部分**：diff 没涉及的章节不动
2. **保持准确**：所有描述必须与代码一致，不猜测
3. **伪代码 > 源码**：流程描述用伪代码风格，不粘贴大段源码
4. **行号是参考**：Skyworth Patch 登记表中的行号需要重新查实际代码确认
5. **不动变更日志**：第 N 节的变更日志由 pre-commit hook 自动维护，本 Skill 不碰

## 示例

用户修改了 `VolumeDialogImpl.java` 的 `checkEarc()` 方法，新增了 TYPE_HDMI 判断：

**diff 片段**:
```diff
+ if (type == AudioDeviceInfo.TYPE_HDMI_EARC
+         || type == AudioDeviceInfo.TYPE_HDMI_ARC
+         || type == AudioDeviceInfo.TYPE_HDMI) {
```

**需要更新的章节**:
- 4.1 设备检测（checkEarc）：伪代码第 2 步新增 TYPE_HDMI
- 无其他章节受影响

**更新内容**:
```markdown
  2. 是否存在 TYPE_HDMI_EARC 或 TYPE_HDMI_ARC 或 TYPE_HDMI？
```
