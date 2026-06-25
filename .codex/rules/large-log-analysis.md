# 大日志与多分片日志分析规则

本规则适用于读取、搜索、分析大体积日志、滚动日志、多分片日志、串口日志、kernel 日志、logcat、CTS/XTS 日志、pstore/last_kmsg 等场景。

## 基本原则

- 不要整文件盲读大日志。先确认文件大小、时间范围、分片顺序和日志来源。
- 优先使用 `rg` 搜索关键词；没有 `rg` 时再用平台可用的文本搜索工具。
- 读取中文日志或路径时按 `read-text.md` 显式使用 UTF-8，但不要因此改写原文件编码。
- 保留来源信息：文件名、分片名、时间戳、必要时记录行号。
- 先建立时间线，再做归因；不要只凭单个关键词定责。

## 分析流程

1. 盘点日志集合：
   - 列出目录下相关文件、大小、修改时间。
   - 判断是否为滚动分片，例如 `log_1.txt`、`log_62_.txt`、串口独立文件、kernel 独立文件。
   - 不要只看最后一个分片，除非已确认目标时间只在该分片内。

2. 锚定目标时间：
   - 从用户给出的发生时间、复现动作、设备重启时间、boot reason、power key、crash、panic 等建立候选窗口。
   - 如果日志时间跨重启，注意区分旧系统末尾和新系统开机后的时间。

3. 关键词分层搜索：
   - 先搜强锚点：崩溃、panic、reboot、power key、module/case 名、包名、错误码。
   - 再搜链路词：Framework、HAL、kernel、driver、service、wakelock、suspend、resume 等。
   - 每次命中只取足够前后文，不展开无关整段。

4. 构建时间线：
   - 按时间顺序合并不同日志源。
   - 标出关键边界：请求发起、Framework 接收、native/HAL 下发、kernel 进入、硬件动作、异常、恢复或重启。
   - 对缺失区间明确写“当前日志缺失”，不要脑补。

5. 输出结论：
   - 先写能被日志直接证明的事实。
   - 再写推断条件和待补证据。
   - 给出最小下一步动作，例如补哪段串口、查哪个 pstore、复跑哪个 case、加哪个脚本探针。

## 显示、灰屏与视频链路日志

当问题涉及 HDMI 灰屏、黑屏、截图黑、UI 存在但视频不出图、STR 唤醒后灰屏、LockWindow 遮挡、FRC/WBC/VO/MEMC/AIPQ 等显示链路时，额外遵守：

- 同时串联异常轮次和正常轮次。不要只看失败那一次；用正常轮次确认哪些遮挡、mute、切源、解冻、恢复日志是标准流程。
- 把上层遮挡状态和底层视频链路分开判断。LockWindow、freeze mute、unmute、遮黑解除只能证明保护层状态，不能单独证明底层视频已经恢复。
- 优先锚定更早出现的底层异常，例如视频延迟持续累积、取帧失败、FRC/WBC timeout、VO/FRC/MEMC task timeout、video window 未打开。
- 若日志打印顺序和毫秒时间戳不一致，按可验证的调用链和绝对时间重排，并在报告中说明排序依据。
- 对“最后看到的现象”保持克制：最后出现的黑屏、灰屏、解遮挡、切源日志未必是根因，必须回溯到第一处持续异常。
- 结论中明确区分：显示保护遮挡未解除、遮挡已解除但视频无帧、视频窗口未打开、底层 FRC/VO/MEMC 超时、应用/Activity/Surface 未完成首帧。

建议搜索词按层次组合：

```text
LockWindow|MuteType|freeze|unmute|black|gray|grey
HDMI|source|input|signal|4K|60|timing|hpd|rx
videoDelay|video delay|AIPQ|frame|capture|get frame
FRC|WBC|VO|MEMC|timeout|task timeout
SurfaceFlinger|Layer|first frame|ActivityTaskManager|WindowManager
no win is opened|display_get_win_attr|window open|window close
```

## 大文件操作约束

- 遇到超大文件时，只做：
  - 文件大小/时间范围检查。
  - 关键词搜索。
  - 命中附近窗口读取。
  - 头尾少量行读取。
- 避免把 100MB 以上日志完整输出到对话或终端。
- 处理 10GB 级日志时，优先搜索高选择性关键词；必要时先按时间或关键词抽取小样本。
- 不要对原始日志做破坏性清理、移动或重编码，除非用户明确要求。

## 常用排查提示

- “脚本里命令结果”和“手动串口命令结果”不一致时，先比较执行环境：`id`、`groups`、`/proc/self/attr/current`、init rc 的 `user/group/seclabel`。
- `top/ps` 看不到应用进程时，优先检查 `readproc`、SELinux domain、`/proc` 可见性，而不是先改命令参数。
- 设备重启类问题要找 `boot reason`、`kernel panic`、`Oops`、`WDT reset`、pstore/ramoops/last_kmsg。
- STR/待机唤醒类问题要同时对齐 Android logcat、kernel suspend/resume、串口 power down/up、wakeup source。
- 显示灰屏类问题要同时对齐 Android Window/Surface、输入源切换、底层视频窗口、FRC/WBC/VO/MEMC、屏幕保护遮挡状态。