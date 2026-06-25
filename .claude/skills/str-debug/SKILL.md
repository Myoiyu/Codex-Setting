---
name: str-debug
description: Android STR (Suspend-to-RAM) 待机问题日志分析。过滤关键词：powermanager|str|suspend|PM|wakelock|screen_off|screen_on|androidruntime，排查异常待机、黑屏、开机异常。当用户提供串口日志或要求分析 STR 问题时使用此 skill。
---

# STR Debug Skill

## 概述

专门用于 Android STR 待机问题的日志分析。从大量串口日志中过滤出 STR 相关行，并自动检测异常模式。

## 日志文件路径

- **日志目录**：`E:\日志\`（bash 中为 `/e/日志/`）
- **文件命名格式**：`%H_%Y%M%D_%h%m%s.log`（SecureCRT 自动变量替换）
- **实际文件名示例**：`Serial-COM3_20260512_143022.log`
- **获取最新日志**：`ls -t /e/日志/Serial-COM3_*.log | head -1`

实时监控时自动取目录下最新的 `Serial-COM3_*.log` 文件，无需询问用户。

## 过滤关键词

```
powermanager|str|suspend|PM|wakelock|screen_off|screen_on|androidruntime
```

大小写不敏感。

## 执行流程

### Step 1：确认日志来源

默认自动定位日志：`ls -t /e/日志/Serial-COM3_*.log | head -1` 取最新文件。

支持两种模式：
- **一次性分析**：分析最新或用户指定的日志文件
- **实时监控**：用户正在串口测试，日志持续写入最新文件。用 `tail -f` 跟踪

### Step 2：过滤日志

对日志文件执行关键词过滤，保存到临时文件以减少后续分析开销：

```bash
grep -iE "powermanager|str\b|suspend|PM|wakelock|screen_off|screen_on|androidruntime" <日志文件> > /tmp/str_filtered.log
```

注意：`PM` 作为短关键词会匹配较多行（如 PMIC、spmi），需在分析时区分。对于匹配过多的日志，可追加 `head -2000` 限制行数。

对实时监控场景，使用 `tail -f` + `grep --line-buffered` 持续过滤。

### Step 3：STR 异常模式检测

按以下维度检查过滤后的日志：

#### 一、待机异常 (Suspend Abnormal)

| 检测项 | 匹配模式 | 含义 |
|--------|----------|------|
| 待机入口失败 | `suspend_abort`, `PM: Device.*failed to suspend`, `dpm_suspend.*error` | 设备驱动挂起失败 |
| 待机被唤醒打断 | `suspend.*abort.*wakeup`, `wakeup.*suspend in progress` | 待机过程中被唤醒源打断 |
| 待机超时 | `suspend.*timeout`, `freeze of tasks.*fail` | 进程冻结超时失败 |
| WakeLock 持锁 | `wakelock.*held`, `WakeLock.*prevent`, `acquire.*timeout` | 锁未释放导致无法待机 |
| PowerManager 异常 | `PowerManagerService.*error`, `PowerManagerService.*fail` | 电源管理服务自身异常 |
| STR 入口日志缺失 | 无 `suspend_enter` 行 | 系统未进入 STR 流程 |

#### 二、黑屏异常 (Black Screen)

| 检测项 | 匹配模式 | 含义 |
|--------|----------|------|
| 屏幕关闭失败 | `screen_off.*fail`, `request_suspend_state.*sleep.*error` | 关屏流程异常 |
| 屏幕唤醒失败 | `screen_on.*fail`, `request_suspend_state.*wakeup.*error` | 亮屏流程异常 |
| 显示子系统崩溃 | `display.*error`, `DSI.*error`, `fb.*error`, `panel.*fail` | 显示驱动故障 |
| 背光异常 | `backlight.*error`, `pwm_bl.*fail` | 背光控制失败 |
| SurfaceFlinger 异常 | `SurfaceFlinger.*error`, `surfaceflinger.*died` | 显示合成服务异常 |

#### 三、开机异常 (Boot Abnormal)

| 检测项 | 匹配模式 | 含义 |
|--------|----------|------|
| AndroidRuntime 崩溃 | `AndroidRuntime.*FATAL`, `FATAL EXCEPTION` | Java 层崩溃 |
| 系统服务启动失败 | `SystemServer.*fail`, `Zygote.*die`, `boot.*timeout` | 系统服务异常 |
| 内核 panic | `Kernel panic`, `Unable to handle kernel` | 内核崩溃重启 |
| 看门狗超时 | `Watchdog.*timeout`, `hung_task`, `blocked for more than` | 任务卡死 |
| 重启循环 | 短时间内多次出现 `boot` 序列 | 反复重启 |

#### 四、STR 流程完整性检查

从过滤结果中提取完整的 STR 周期时间线：

```
suspend_entry → dpm_suspend_start → (各设备suspend) → dpm_suspend_end → (唤醒源) → dpm_resume → screen_on
```

标注每次 STR 的耗时和是否有异常跳变。

### Step 4：输出分析报告

按以下结构输出紧凑报告：

```
=== STR 日志分析报告 ===
日志文件: xxx
时间范围: xxx ~ xxx (或文件起止行)
STR 周期数: N 次待机/唤醒

--- 发现异常 ---
1. [严重/警告] <异常类型> — <行号/时间戳>
   关键日志: <原文摘录>
   可能原因: <简要分析>

2. ...

--- 建议 ---
- 排查方向1
- 排查方向2
```

正常时仅输出一行摘要，不说废话。发现异常时才展开。

### Step 5（实时模式）：持续监控

实时模式下，每 30 秒检查一次 `tmp/str_filtered.log` 的新增内容。发现 STR 异常时主动通知用户，不等到会话结束。

## 常用排查要点

1. **WakeLock 是 STR 第一排查对象** — `cat /sys/power/wake_lock` 和 `dumpsys power | grep -i wake` 是最直接的检查手段
2. **suspend_abort 后的第一行唤醒源日志** — 能定位谁打断了待机
3. **dpm_suspend 阶段若某个设备耗时异常长** — 该驱动的 suspend 回调有问题
4. **Kernel panic 复现时关注 Call trace 的栈回溯** — 定位崩溃函数
5. **屏幕黑屏但系统响应的** — 多数是背光或 panel 初始化问题
6. **屏幕亮但无显示** — 检查 SurfaceFlinger 和 HWC

## 注意事项

- 此 skill 只做**日志分析和过滤**，不修改任何代码
- 如用户提供的日志中包含 `dmesg` 或 `logcat` 中未捕获的其他信息，需额外确认
- 分析始终是**辅助性质**的，严重问题请结合 Trace32 / JTAG 等硬件调试手段确认
