# 04 · 播放器子系统

播放器是仓库中最大、约束最多的子系统。分层规则另见 [docs/PLAYER_ARCHITECTURE.md](../PLAYER_ARCHITECTURE.md)。

## 4.1 设计目标

1. **单一播放器所有权**：全应用同一时刻只有一个活跃 `PlaybackService` 会话；打开新视频前先挂起旧会话，返回时恢复。
2. **主文件只做装配**：`player_page.dart` 负责创建服务和状态，具体逻辑拆到协调器 mixin 与视图 extension。
3. **同一 library**：子文件以 `part` 声明，协调器可以直接访问 `_PlayerPageState` 私有成员，无需暴露公共 API。
4. **代次校验**：视频切换、字幕请求、弹幕预加载、曲目加载都带 generation/revision，旧异步结果不得写入新上下文。
5. **平台后端可替换**：页面只依赖 `PlaybackService` 接口，Android 用 Media3，桌面/Apple 用 media_kit。

## 4.2 文件组合

[player_page.dart](../../lib/features/player/player_page.dart) 声明 22 个 `part`：

```text
协调器 mixin（12）
├── _PlayerPlaybackSession          # 会话快照、纹理、清晰度、续播、在线/本地切换
├── _PlayerVideoCoordinator         # 分P/章节/互动剧情/合集/嵌套播放器导航
├── _PlayerControlsCoordinator      # 控制层自动隐藏、播放命令、选集、键盘、画幅
├── _PlayerOverlayCoordinator       # 字幕轨道/Cue、弹幕分段预加载与配置
├── _PlayerViewportCoordinator      # 方向、系统栏、移动端自动全屏、Windows 窗口全屏
├── _PlayerGestureCoordinator       # 单击/双击/长按/滑动/双击区域
├── _PlayerNotesWorkspace           # 笔记面板、800ms 自动保存、截图
├── _PlayerNoteFlagsCoordinator     # 时间线笔记标记
├── _PlayerLearningCoordinator      # 学习清单联动
├── _PlayerFocusCoordinator         # 专注计时联动
├── _PlayerListeningCoordinator     # Android 听视频
└── _PlayerSleepTimerCoordinator    # 睡眠定时

视图/构建 extension（7）
├── _PlayerPageView                 # build 入口
├── _PlayerControlsView             # 控制层布局
├── _PlayerFeedbackView             # 手势反馈/提示
├── _PlayerDetailsView              # 详情区、收藏、合集
├── _PlayerLocalLibrary             # 本地库/离线操作
├── _PlayerCollectionView           # 合集列表
└── _PlayerTimelineView             # 时间线/进度条/笔记标记

独立 part（3）
├── player_collection_sheet.dart    # 合集选择底部弹层
├── player_layout_widgets.dart      # 全屏状态、头部折叠、跑马灯
└── player_danmaku_rendering.dart   # 弹幕轨道规划与 CustomPainter
```

`PlayerPage` 构造参数几乎覆盖全部依赖（播放、历史、学习、设备状态、字幕弹幕、B 站接口、公开内容、互动、截图、笔记、弹幕/播放偏好、增强数据、离线、下载队列、收藏、专注控制器、外链启动器、平台、起始分P/位置），测试可逐项注入假实现。

## 4.3 播放服务抽象

| 类型 | 文件 | 说明 |
|---|---|---|
| `PlaybackPhase` / `PlaybackQuality` / `SavedPlaybackState` / `SystemPlaybackLevels` / `PlaybackSnapshot` | [native_playback_service.dart](../../lib/services/native_playback_service.dart) | 跨平台播放状态模型；`PlaybackSnapshot.fromPlatformMap` 解析原生字典 |
| `PlaybackService` | 同上 | `states` 流、`initialize()`、`openVideo`、`play/pause/seek/setSpeed/setVolume` 等 |
| `NativePlaybackService` | 同上 | Android MethodChannel `com.focubili.app/playback` |
| `WindowsPlaybackService` | [windows_playback_service.dart](../../lib/services/windows_playback_service.dart) | media_kit `Player` + `VideoController`；实现 `PlaybackService`、`PlaybackVideoSurface`、`ListeningPlaybackService`、`LocalTrackPlaybackService`；5 秒进度保存、帧捕获、Apple/Linux 会话与迷你播放器 |
| `_UnavailablePlaybackService` | [platform_services.dart](../../lib/platform/platform_services.dart) | 未支持平台返回稳定的 `error` 状态，不申请纹理 |

`createDefaultPlaybackService()`（[playback_service_factory.dart](../../lib/services/playback_service_factory.dart)）统一从 `PlatformServices.current` 创建后端，未知平台不会回退到 Android。

### 播放数据来源（桌面）

[desktop_playback_source_service.dart](../../lib/services/desktop_playback_source_service.dart)：

- `DesktopPlaybackSources`：视频/音频 URL、Referer、Cookie 头、codecs、可用清晰度、媒体请求头。
- `BilibiliDesktopPlaybackSourceService`：请求 DASH 播放数据，经 `MediaUrlPolicy` 校验后返回。

Android 端播放数据、字幕、弹幕均由原生 `NativePlaybackController` 内部请求，Dart 不接触 Cookie。

## 4.4 原生 Android 播放链

`android/app/src/main/kotlin/com/focubili/app/`：

| 文件 | 职责 |
|---|---|
| `NativePlaybackController.kt` | Media3 ExoPlayer/DASH、缓存、字幕/弹幕、PiP；通道 `com.focubili.app/playback`（约 3000 行） |
| `PlaybackTrackPolicy.kt` | 轨道选择：AVC 优先、清晰度上限、音频兼容 |
| `PlaybackPhasePolicy.kt` / `PlaybackRecoveryPolicy.kt` / `PlaybackResumePolicy.kt` | 状态映射、错误恢复、续播 |
| `ListeningMediaService.kt` | 听视频前台媒体服务与通知控制 |
| `PlaybackSleepTimer.kt` | 原生睡眠定时 |
| `PlaybackCacheIdentity.kt` / `PinnedLruCacheEvictor.kt` / `OptionalCacheDataSink.kt` | 缓存键、固定 LRU 淘汰、可选缓存写入 |
| `SubtitleDocumentIdentity.kt` | 字幕文档身份与过期判断 |
| `PlaybackRequestDiagnostic.kt` / `WbiSigningPolicy.kt` | 脱敏诊断与 WBI 原生策略 |

Media3 版本统一为 1.10.1；AVC 优先以保证跨设备兼容。

## 4.5 字幕与弹幕

| 层 | 实现 |
|---|---|
| 接口 | `PlayerOverlayService`（`loadSubtitleTracks/loadSubtitleCues/loadDanmakuSegment`） |
| Android | `NativePlayerOverlayService` → `com.focubili.app/playback`；只接受合法 BV/CID/轨道号/段号 |
| 桌面/Apple | `DesktopPlayerOverlayService`（Dart HTTP 拉取，经 `MediaUrlPolicy`），实现 `SubtitleSessionInvalidator` |
| 缓存 | `CachedPlayerOverlayService` 按 BV/CID/轨道/代次缓存；`SubtitleMemoryCache` 上限 8MB、5 分钟 TTL、每 64 条清理 |
| 失效 | `CacheLifecycle.subtitles` / `CacheLifecycle.account` ValueNotifier；账号切换或代次变化立即清空 |
| 诊断 | `SubtitleDiagnosticLog` 记录阶段、HTTP/API 码、轨道/条目哈希，不记录地址与正文 |

弹幕：`_PlayerOverlayCoordinator` 以 30s 阈值预加载，最多缓存 3 段，失败重试 3 次；解析/渲染由 `DanmakuTimelineIndex` + `player_danmaku_rendering.dart` 完成。

## 4.6 播放会话与续播

- [player_route_session.dart](../../lib/services/player_route_session.dart) 维护当前路由会话；`suspendCurrent()` 返回可恢复句柄，`restoreAfterRoute(route)` 在新路由关闭后恢复。
- [playback_resume_plan.dart](../../lib/features/player/playback_resume_plan.dart) 描述续播位置与来源；`PlayerInitialPositionSource`（note/focus/learning/externalLink）决定提示文案。
- [playback_resume_policy.dart](../../lib/services/playback_resume_policy.dart) 与 `windows_playback_recovery_policy.dart` 处理“上次进度/异常退出”的恢复边界。
- 仅累计真实播放区间：专注计时与观看记录都按播放状态推进，暂停/缓冲不计入。

## 4.7 离线与本地播放

- `PlaybackSourceResolver.resolve(bvid, cid, preferLocal, requireLocal)` 只返回**已验证完成**的本地文件；`requireLocal` 时找不到抛 `OfflineVideoException`。
- `LocalFilePlaybackService` / `LocalTrackPlaybackService` 负责本地文件与双轨（video/audio）播放。
- `OfflineDownloadQueue` 的完成事件在根组件显示全局 Snackbar；离线视频从 `OfflineVideosPage` 或播放页进入。

## 4.8 控制层与手势

- `PlayerControlSize`（0.8–2 倍）统一控制层缩放；`PlayerCompactIconButton`、`PlayerPartSelectorButton`、`PlayerProgressSlider` 等为标准控件。
- `PlayerTimelineGeometry` / `PlayerTimelineTrackShape` 负责进度条形状、缓冲段、笔记标记。
- `PlayerTapGestureRecognizer` 与 `_PlayerGestureCoordinator` 处理单击显隐、双击区域（左/中/右可配置）、长按临时倍速（1–5 倍，默认 3 倍）、双指缩放。
- `_PlayerControlsCoordinator` 在播放中 5 秒自动隐藏控制层，暂停/操作时保持显示。

## 4.9 全屏、方向与窗口

- `_PlayerViewportCoordinator`：移动端按视频比例自动全屏，桌面切换窗口全屏；系统栏显隐与方向锁定统一走 `DeviceOrientationPolicy`。
- Windows/Linux 使用 `window_manager`；Linux 另有 `LinuxMiniPlayer` 迷你播放器。
- Apple 画中画由 `FocuBiliApplePictureInPicture` 与 `ApplePlaybackSession` 提供。

## 4.10 回归命令

```bash
dart analyze lib test
flutter test
flutter build apk --debug
```

与播放器相关的测试集中在 `test/player_*`、`test/desktop_*`、`test/cached_player_overlay_service_test.dart`、`test/windows_media_cache_service_test.dart` 以及 `integration_test/player_windows_v18_test.dart`。

下一章：[05-services-data.md](05-services-data.md) → 服务层、业务域与持久化。
