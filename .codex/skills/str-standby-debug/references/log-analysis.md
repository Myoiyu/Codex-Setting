# STR Log Analysis Reference

## Keyword Map

- `scancode=116`: TV power-key mapping. Use this as the hardware/user input anchor for standby or wake.
- `Skyglobalservice`: Customized app service that calls standby APIs and emits STR-related logs.
- `going to`: PowerManager standby/shutdown direction log. Use to confirm Framework accepted a sleep/standby path.
- `waking up`: PowerManager wake direction log. Use to confirm Framework accepted a wake path.
- `force-suspend`: Slow standby fallback, usually after about 30 seconds. Expect related `dumpsys power` output nearby.
- `wakelock`, `wake lock`, `WAKE_LOCK`: Lock state that may block or delay suspend.
- `suspend entry`: Kernel reached suspend entry.
- `suspend exit`: Kernel exited suspend/resume path.
- `PM:`, `suspend`, `resume`, `freeze`, `thaw`, `wakeup`, `rtc`, `pcm`: Kernel/low-level suspend and wake clues.
- `panel`, `display on`, `SurfaceFlinger`, `Layer`, `first frame`, `ActivityTaskManager`, `WindowManager`: Display/window/app readiness clues after wake.
- `frozen`, `unfreeze`, `force stopping`, `package`, `install`, `launcher`, `home`: App/package state changes that may overlap STR wake and affect first frame.
- `display_get_win_attr`, `no win is opened`, `window open`, `window close`: Display/video window reconstruction clues after wake.

## Timeline Checklist

1. Anchor the event with `scancode=116` or `Skyglobalservice`.
2. Find the nearest PowerManager `going to` after a standby request.
3. Find the nearest kernel `suspend entry`.
4. Find `suspend exit` or wake-source logs after resume.
5. Find PowerManager `waking up`.
6. For display symptoms, continue the timeline through panel/display on, Activity resume, Window/Surface creation, SurfaceFlinger layer, first frame, and video/window open state.
7. Compare timestamps between each boundary:
   - trigger to PowerManager: app/input dispatch delay.
   - PowerManager to kernel `suspend entry`: Framework/native suspend preparation delay.
   - kernel `suspend entry` to low-level suspend complete or wake: kernel/driver/PCM area.
   - wake source to `waking up`: kernel to Framework resume handoff.
   - `waking up` to first valid frame/window: display, WindowManager, SurfaceFlinger, launcher/app, or video path.

## Slow Standby Analysis

Use this flow when standby is slow, fails to enter STR, or only enters after force-suspend:

1. Confirm the standby request exists:
   - power key path: `scancode=116`.
   - app path: `Skyglobalservice` calling standby API.
2. Confirm Framework handled it with PowerManager `going to`.
3. Check whether the gap after `going to` exceeds about 30 seconds.
4. If `force-suspend` appears, inspect nearby `dumpsys power` lines:
   - active wakefulness state.
   - held `WAKE_LOCK` / wakelock records.
   - owning package, UID, tag, or service.
5. If abnormal wakelock exists, attribute first to the owning app/service unless Framework is incorrectly holding or failing to release it.
6. If no abnormal wakelock exists, inspect kernel suspend logs for the last successful step before delay or failure.
7. If `suspend entry` is missing, suspect Framework/native preparation, wakelock, binder/service blocking, or suspend request not reaching kernel.
8. If `suspend entry` exists but suspend stalls, suspect kernel driver, device suspend callback, interrupt, wake source, or PCM.

## Slow Wake Analysis

Use this flow when wake takes too long after key/remote/RTC/network wake:

1. Find kernel wake source or `suspend exit`.
2. Find PowerManager `waking up`.
3. Compare:
   - wake source to `suspend exit`: low-level wake or PCM.
   - `suspend exit` to Android resume logs: kernel driver resume and native handoff.
   - Android resume to `waking up` / display-ready logs: Framework, display, app, or service readiness.
4. If kernel exits quickly but Android wakes slowly, inspect Framework services, display/power state, and app startup/service callbacks.
5. If kernel or PCM consumes most time, ask for kernel timestamps, driver suspend/resume traces, PCM logs, and wake source details.

## Wake Gray/Black Screen Analysis

Use this flow when STR wake completes but the user reports gray screen, black screen, screenshot black, UI exists but video is missing, or home appears stuck:

1. First prove whether STR itself completed:
   - `suspend exit` exists.
   - PowerManager `waking up` exists.
   - panel/display on logs exist.
   - Activity or launcher/home resume logs exist.
2. If these exist, do not conclude “STR 未唤醒” unless there is direct evidence that suspend/resume is still blocked.
3. Check whether package or app state changed during the wake window:
   - silent install/update.
   - package `frozen` / unfreeze.
   - `force stopping`.
   - launcher/home process restart or Activity recreation.
4. Check display/window readiness after wake:
   - WindowManager transition and focused window.
   - Surface creation/destruction.
   - SurfaceFlinger layer visibility.
   - first frame or draw completion.
   - video/window open state.
5. If logs repeatedly show `display_get_win_attr ... no win is opened` or equivalent messages after wake, treat this as evidence that the display/video window did not reconstruct normally.
6. Compare a normal STR wake round if available. Standard freeze mute/unmute, LockWindow, panel on, or display-on logs should not be treated as root cause unless they differ from the normal round.
7. Attribute by the first abnormal segment:
   - package/app state overlap before missing first frame: app/package manager or launcher path.
   - Activity resumed but no Surface/first frame: WindowManager, SurfaceFlinger, or app rendering.
   - Surface/layer ready but no video window/frame: display/video path.
   - wake Framework delayed before display readiness: Framework/display power transition.

## Ownership Heuristics

- App: `Skyglobalservice` delay before API call, app-held wakelock, service/broadcast delay, app-triggered repeated standby/wake, launcher/home restart, missing app first frame.
- Package manager: install/update, `frozen` / unfreeze, `force stopping`, package state transition overlapping STR wake.
- Framework: large gap between PowerManager `going to` and kernel suspend without app wakelock, PowerManager state inconsistency, Display/Window/ActivityManager blocking power transition.
- Display/window stack: panel/display on but no valid Window/Surface/Layer/first frame, video window not opened, repeated display window query failure.
- Kernel: `suspend entry` reached but device suspend/resume step stalls, kernel wake source immediately aborts suspend, driver PM callback delay.
- PCM: low-level power controller delay, late suspend completion, early wake, board-specific STR sequence issues, missing/slow power-domain transition.

## Report Template

```text
结论:
- 是否调用待机:
- 是否进入 suspend entry:
- 是否出现 suspend exit / waking up:
- 是否已完成 panel/display on:
- 是否出现 Activity/Window/Surface/first frame:
- 初步归属:

关键时间线:
- <timestamp> <file:line> <event>

分段耗时:
- 触发 -> PowerManager:
- PowerManager -> suspend entry:
- suspend entry -> suspend exit / wake source:
- suspend exit -> waking up:
- waking up -> display/window/first frame:

异常证据:
- wakelock:
- force-suspend:
- kernel/PCM:
- package/app state:
- display/window/first frame:

建议:
- 下一步模块:
- 需要补充的日志:
```