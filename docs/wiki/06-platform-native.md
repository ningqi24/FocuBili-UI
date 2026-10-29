# 06 · 平台能力与原生层

## 6.1 平台抽象三件套

| 文件 | 作用 |
|---|---|
[app_platform.dart](../../lib/platform/app_platform.dart) | `AppPlatform` 枚举（android/windows/ios/macos/linux/unsupported）、`AppPlatformDetector`、扩展属性 |
[platform_capabilities.dart](../../lib/platform/platform_capabilities.dart) | 不可变能力表，描述每个平台的播放、叠加、缓存、Cookie、通知、登录、系统能力页、更新目标、PiP、勿扰、桌面窗口 |
[platform_services.dart](../../lib/platform/platform_services.dart) | 唯一装配入口：按能力表创建具体实现；未支持平台返回 `_Unavailable*` |

页面与服务不得直接 `Platform.isAndroid` 分支；应读取 `PlatformCapabilities` 或调用 `PlatformServices.createXxx()`。

## 6.2 能力矩阵（源码事实）

| 能力 | Android | Windows | iOS / macOS | Linux | unsupported |
|---|---|---|---|---|---|
| 播放后端 | `androidMedia3` | `mediaKit` | `mediaKit` | `mediaKit` | `unavailable` |
| 字幕弹幕 | `androidChannel` | `dartHttp` | `dartHttp` | `dartHttp` | `unavailable` |
| 媒体缓存页 | `androidMedia3` | `windowsMediaKit` | `windowsMediaKit` | `windowsMediaKit` | `unavailable` |
| Cookie 容器 | `androidWebView` | `windowsSecureStorage` | `androidWebView`* | `windowsSecureStorage` | `unavailable` |
| 专注通知 | `androidChannel` | `windowsToast` | `appleNotifications` | `linuxNotifications` | `unavailable` |
| 登录体验 | `officialWebView` | `officialQrCode` | `officialWebView` | `officialQrCode` | `unavailable` |
| 系统能力页 | `androidPermissions` | `windowsDesktop` | `apple` | `linuxDesktop` | `unavailable` |
| 更新目标 | `android` | `windows` | `macos` / `other`（iOS） | `linux` | `other` |
| 画中画 | 是 | 否 | 是 | 是 | 否 |
| 勿扰 | 是 | 否 | 否 | 否 | 否 |
| 桌面窗口 | 否 | 是 | 仅 macOS | 是 | 否 |

\* Apple 的 `cookieStoreBackend` 在能力表中标记为 `androidWebView`，但 `PlatformServices.createBilibiliCookieStore()` 对 `platform.isApple` 优先返回 `AppleBilibiliCookieStore`（WKWebView 作用域事务），实际实现并非 Android 通道。

## 6.3 MethodChannel 清单

| 通道 | Dart 侧 | 原生侧 | 主要用途 |
|---|---|---|---|
| `com.focubili.app/playback` | `NativePlaybackService`、`NativePlayerOverlayService` | `NativePlaybackController.kt` | 播放、缓存、字幕轨道/条目、弹幕分段、PiP |
| `com.focubili.app/auth` | `PlatformBilibiliCookieStore`、`AppleBilibiliCookieStore` | `BilibiliCookieController`（Android 插件）、`FocuBiliApplePlugin` | Cookie 读取/替换/清理；Apple 播放会话事务 |
| `com.focubili.app/focus_notifications` | `FocusNotificationService` | `FocusNotificationController.kt`、Apple 插件、Windows/Linux 实现 | 专注完成/提醒通知、权限与勿扰状态 |
| `com.focubili.app/subscription_notifications` | `SubscriptionNotificationService` | `SubscriptionNotificationController.kt`、Apple 插件 | 订阅摘要/条目通知、点击回传（`subscriptionTapped`） |
| `com.focubili.app/subscription_scheduler` | `NativeSubscriptionScheduler` | Android WorkManager / Apple BGTask / 桌面定时器 | `configure(enabled, generation, intervalSeconds)`、状态查询 |
| `com.focubili.app/subscription_worker` | `subscription_background_service` | Android/iOS headless 引擎 | 后台检查入口与结果回传 |
| `com.focubili.app/device_status` | `DeviceStatusService` | `DeviceStatusController.kt`、Apple 插件 | 电量、网络、勿扰等设备状态 |
| `com.focubili.app/downloads` | `DownloadNotificationService` | `DownloadProgressController.kt` / `DownloadProgressService.kt` | 下载进度通知 |
| `com.focubili.app/windows_experience` | `WindowsExperienceService` | Windows Runner `windows_experience.cpp/h` | Windows 桌面体验与窗口集成 |
| `com.focubili.app/windows_do_not_disturb` | `WindowsDoNotDisturbService` | Windows Runner | Windows 专注助手/勿扰状态 |
| `com.focubili.app/apple_media` | `ApplePlaybackSession` | `FocuBiliApplePlugin` | Apple 媒体会话与播放状态 |
| `focubili/deep_links` | `BilibiliDeepLinkService` | `DeepLinkController.kt` | 冷启动与 `singleTask` 新 Intent 的外部链接 |

通道约定：

- 参数只允许 BV、CID、轨道号、段号、generation 等安全值。
- 不通过通道传递 Cookie、临时字幕地址、原始 Protobuf。
- 原生返回错误码，Dart 统一映射为可展示文案。

## 6.4 Android 原生层

`android/app/src/main/kotlin/com/focubili/app/`（24 个主文件 + 11 个 JVM 单测）：

| 文件 | 职责 |
|---|---|
| `MainActivity.kt` | 方向策略、深链、注册 NativePlaybackController/DeviceStatus/FocusNotification/DeepLink/DownloadProgress；`onNewIntent` 处理 VIEW/SEND；前后台暂停恢复、PiP |
| `NativePlaybackController.kt` | Media3 ExoPlayer/DASH/缓存/字幕弹幕/PiP；`com.focubili.app/playback` |
| `PlaybackTrackPolicy.kt` | 轨道选择（AVC 优先） |
| `PlaybackPhasePolicy.kt` / `PlaybackRecoveryPolicy.kt` / `PlaybackResumePolicy.kt` | 状态映射、错误恢复、续播 |
| `PlaybackCacheIdentity.kt` / `PinnedLruCacheEvictor.kt` / `OptionalCacheDataSink.kt` | 缓存键、LRU 淘汰、可选缓存写入 |
| `PlaybackRequestDiagnostic.kt` / `WbiSigningPolicy.kt` | 脱敏诊断、WBI 原生策略 |
| `SubtitleDocumentIdentity.kt` | 字幕文档身份 |
| `ListeningMediaService.kt` | 听视频前台服务 |
| `PlaybackSleepTimer.kt` | 睡眠定时 |
| `FocusNotificationController.kt` / `FocusReminderScheduler.kt` / `FocusReminderReceiver.kt` / `FocusReminderRestoreReceiver.kt` | 专注通知、AlarmManager 提醒与重启恢复 |
| `DeviceStatusController.kt` | 设备状态通道 |
| `DeepLinkController.kt` | `focubili/deep_links` |
| `DownloadProgressController.kt` / `DownloadProgressService.kt` | 下载进度通知 |
| `LargeScreenOrientationPolicy.kt` | 大屏方向策略 |

Android 插件 `packages/focubili_android/`：

- `FocuBiliAndroidPlugin.kt` 注册 `BilibiliCookieController`（`auth`）与 `SubscriptionNotificationController`（`subscription_notifications`），兼容 WorkManager headless engine。
- `SubscriptionNotificationController` 读最新开关与发通知在同一原生 SQLite 短事务中，与停用 CAS 串行；使用 `DatabaseErrorHandler {}` 避免默认损坏处理器删库。

Android 包名/版本：正式 `com.focubili.app`；debug 后缀 `.preview`（`-preview`）；beta 后缀 `.preview` + `-beta.N`。`compileSdkVersion 36`。

## 6.5 Apple 原生层

`packages/focubili_apple/ios/Classes/` 与 `macos/Classes/`（两份同构）：

| 文件 | 职责 |
|---|---|
| `FocuBiliApplePlugin.swift` | 注册 `auth`、`focus_notifications`、`subscription_notifications`、`device_status`、`apple_media`；WKWebView Cookie、PiP、通知、网络状态、深链 |
| `BilibiliPlaybackSession.swift` | WK 容器内 Cookie 的读取/校验/合并事务，generation 保护 |
| `FocuBiliApplePictureInPicture.swift` | AVKit 画中画 |
| `SubscriptionScheduler.swift` | iOS `BGAppRefreshTask` + headless Flutter engine；macOS 桌面定时调度 |
| `SubscriptionRunGate.swift` | 跨进程运行门，防止并发刷新 |

Runner：`ios/Runner/AppDelegate.swift`、`SceneDelegate.swift`；`macos/Runner/AppDelegate.swift`、`MainFlutterWindow.swift`。

## 6.6 Windows 与 Linux 原生层

### Windows（`windows/runner/`）

- `main.cpp`：单实例互斥锁 `Local\FocuBili.SingleInstance`；WebView 标题栏子进程豁免；窗口居中；激活已有窗口。
- `flutter_window.cpp/h`、`win32_window.cpp/h`：Flutter 视图与窗口。
- `windows_experience.cpp/h`：`com.focubili.app/windows_experience` 实现。
- `fullscreen_mouse_guard.h`：全屏鼠标保护。
- 安装器脚本 `windows/installer/build_windows_packages.ps1`；`msix` 配置 `identity_name com.focubili.app`。

### Linux（`linux/`）

- `CMakeLists.txt`、`runner/main.cc`、`runner/my_application.cc/h`：GTK 应用入口。
- `packaging/com.focubili.app.desktop`：桌面条目。
- 依赖 `dbus`、`media_kit_libs_linux`；打包脚本 [tool/package_linux.sh](../../tool/package_linux.sh)。

## 6.7 原生安全模型

1. **Cookie 隔离**：Android 的播放/字幕/弹幕请求在原生容器内完成；Dart 只拿到业务数据。Windows/Linux 使用系统加密存储；Apple 使用 WK 容器事务。
2. **地址白名单**：`MediaUrlPolicy` 只允许 HTTPS + `bilivideo.com`/`bilivideo.cn` 子域；重定向每一跳都校验，最多 5 跳。
3. **断点续传**：`.resume` sidecar 只保存 ETag/Last-Modified 等 validator，不保存 URL 或 Cookie。
4. **诊断脱敏**：原生错误只回传稳定错误码与纯数字 HTTP 状态。
5. **数据库防删**：订阅通知的原生只读事务使用空 `DatabaseErrorHandler`，损坏时保留数据供恢复。

下一章：[07-dependencies.md](07-dependencies.md) → 依赖关系。
