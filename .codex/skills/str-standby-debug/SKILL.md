---
name: str-standby-debug
description: Android TV STR/Suspend-to-RAM standby and wake bug diagnosis from logs. Use only when diagnosing actual TV standby/wake bugs, abnormal suspend/resume, slow suspend/resume, force-suspend, wakelock, PowerManager, kernel suspend, PCM, app-triggered standby, Skyglobalservice, power-key scancode=116, or STR wake black/gray screen issues in serial, kernel, Android, logcat, or combined logs. Do not use for normal code flow explanation, architecture documentation, feature design, or non-bug implementation planning unless the user explicitly asks for STR debugging.
---

# STR Standby Debug

## Overview

Analyze Android TV STR standby bugs from logs. Build a timeline from power-key/app trigger to Framework PowerManager, force-suspend/wakelock state, kernel suspend entry/exit, wake path, display/window readiness, and first-frame evidence; then attribute slow standby, failed standby, unexpected wake, reboot, panic, slow wake, or wake-after-STR gray/black screen to app, Framework, display/window stack, kernel, or PCM.

Use this skill only for bug/abnormal/log diagnosis. For normal code reading, STR flow documentation, architecture explanation, feature design, or implementation planning, do not apply this skill's debug report format unless the user explicitly asks for STR issue analysis.

## Quick Workflow

1. Locate the relevant log files first. Prefer `rg` for large logs and preserve source filenames in notes.
2. Search the baseline keywords: `scancode=116`, `going to`, `waking up`, `suspend entry`, `suspend exit`, `wakelock`, `Skyglobalservice`.
3. Treat `scancode=116` as the TV product power-key mapping. Use it to anchor manual power-key standby/wake events.
4. Treat `Skyglobalservice` as the customized app path that calls standby APIs and prints STR-related traces.
5. Use PowerManager `going to` and `waking up` logs to decide whether Framework received standby/wake requests and when they started.
6. For slow standby, check whether force-suspend triggers after about 30 seconds. If it does, inspect the printed `dumpsys power` state and identify abnormal held `WAKE_LOCK` / wakelock owners.
7. Use kernel suspend logs to determine whether the system reached `suspend entry`, where suspend stopped, and whether `suspend exit` appeared.
8. For slow standby or slow wake, split elapsed time by app, Framework, kernel, and PCM where timestamps allow, then point the optimization owner to the slow segment.
9. For wake-after-STR gray/black screen, first verify whether STR itself completed. If `suspend exit`, PowerManager `waking up`, panel/display on, or home Activity resumed are present, continue into display/window/app first-frame analysis instead of attributing the issue only to suspend/resume.
10. Check non-power-chain interference around wake, especially package install/update, `frozen`, `force stopping`, app restart, launcher/home Activity recreation, SurfaceFlinger layer creation, first frame, and video/window open state.

## Commands

Use case-insensitive searches unless the log format requires exact case:

```powershell
rg -n -i "scancode=116|going to|waking up|suspend entry|suspend exit|wakelock|Skyglobalservice" <log-path>
rg -n -i "force-suspend|dumpsys power|WAKE_LOCK|wake lock|wakelock" <log-path>
rg -n -i "PM:|suspend|resume|freeze|thaw|wakeup|rtc|pcm" <log-path>
rg -n -i "black|gray|grey|panel|display on|SurfaceFlinger|first frame|Layer|ActivityTaskManager|WindowManager" <log-path>
rg -n -i "frozen|force stopping|package|install|unfreeze|launcher|home|no win is opened|display_get_win_attr|window open|window close" <log-path>
```

When logs are large, search each keyword separately around candidate timestamps and include enough surrounding lines to understand causality.

## Analysis Rules

Read `references/log-analysis.md` when the issue needs detailed triage, timing attribution, or report wording.

Always distinguish:

- Request path: power key (`scancode=116`) or app/API (`Skyglobalservice`).
- Framework decision: PowerManager `going to` and `waking up`.
- Force-suspend path: roughly 30s standby delay plus `dumpsys power` snapshot.
- Kernel path: `suspend entry`, intermediate suspend/resume steps, `suspend exit`.
- Display/window readiness: panel on, display power state, Activity resume, Window/Surface creation, SurfaceFlinger layer, first frame, video window open state.
- Non-power interference: package install/update, `frozen` / unfreeze, `force stopping`, launcher/home restart, app-triggered standby/wake overlap.
- Ownership: app, Framework, display/window stack, kernel, or PCM based on the segment with abnormal delay or blocking state.

For STR wake gray/black screen:

- If panel/display has already turned on and Framework has completed wake, do not classify it as “STR 未唤醒” without evidence.
- If home/launcher Activity resumes but no valid first frame or video window appears, prioritize SurfaceFlinger, WindowManager, app rendering, and display/video window evidence.
- If package `frozen`、静默安装、`force stopping` 与唤醒窗口重叠，列为强相关干扰因素，但仍需用 Activity/Surface/first frame 证明是否造成灰屏。
- If logs show `display_get_win_attr ... no win is opened` or similar repeated window-missing messages after wake, treat it as display/video window reconstruction evidence and ask for corresponding layer/window traces.
- Compare at least one normal wake round when available, so standard logs such as freeze mute/unmute, LockWindow, or display-on are not mistaken for the root cause.

## Output

Report in Chinese when the user writes Chinese. For bug/log diagnosis, prefer this structure:

1. 现象结论: whether standby/wake was called, whether suspend entry/exit occurred, whether Framework wake completed, and whether the issue is slow standby, failed standby, slow wake, unexpected wake, or wake-after-STR gray/black screen.
2. 关键时间线: timestamped events with file/line references when available.
3. 分段耗时: app, Framework, kernel, PCM, display/window, and first-frame timings; mark unknown segments clearly.
4. 异常点: wakelock holder, missing suspend entry/exit, force-suspend trigger, panel/display state mismatch, missing first frame, package frozen/install/force-stop overlap, or module-specific delay.
5. 建议归属: module/team to investigate and concrete next logs to collect if evidence is insufficient.

If the user asks for a code flow or architecture document related to STR rather than a bug diagnosis, use normal documentation style instead of the above debug structure.