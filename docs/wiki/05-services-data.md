# 05 · 服务层、业务域与数据

`lib/services/` 是应用的核心业务层，向上被页面/协调器调用，向下封装网络、存储、缓存与原生通道。本章按业务域说明关键类与函数，并汇总持久化键。

## 5.1 B 站接口与鉴权

### 视频与搜索

| 类型 | 文件 | 关键函数/接口 |
|---|---|---|
| `BilibiliService` | [bilibili_service.dart](../../lib/services/bilibili_service.dart) | `lookupVideo(bvid)`、`searchVideos(query, filter, page)`、`suggestKeywords` |
| `BilibiliVideoInfoService` | 同上 | 请求 `api.bilibili.com/x/web-interface/view`、`/x/tag/archive/tags`、`/x/web-interface/wbi/search/type`、`s.search.bilibili.com/main/suggest` |
| `BilibiliLookupException` | 同上 | 稳定、可展示的查询失败信息 |
| `BilibiliPublicContentService` | [bilibili_public_content_service.dart](../../lib/services/bilibili_public_content_service.dart) | `loadProfile`、`loadVideos`、`loadArticles`、`loadCollections`、`loadCollectionVideos` |
| `BilibiliHttpPublicContentService` | 同上 | WBI 签名的公开内容请求；仅在投稿风控时临时复用已登录会话 |
| `BilibiliInteractionService` | [bilibili_interaction_service.dart](../../lib/services/bilibili_interaction_service.dart) | 关注/点赞/投币/收藏写操作；`BilibiliInteractionState`、`BilibiliFavoriteFolder` |
| `BilibiliPlayerEnhancementService` | [bilibili_player_enhancement_service.dart](../../lib/services/bilibili_player_enhancement_service.dart) | `loadMetadata`、`loadInteractiveNode`（章节、互动节点） |

### 登录与 Cookie

| 类型 | 文件 | 说明 |
|---|---|---|
| `BilibiliAccount` / `SessionStatus`（signedOut/active/expired/networkError）/ `SessionState` | [bilibili_auth_service.dart](../../lib/services/bilibili_auth_service.dart) | 单账号会话状态；不保存密码 |
| `BilibiliAuthApi` / `BilibiliHttpAuthApi` | 同上 | `/x/web-interface/nav` 校验会话 |
| `BilibiliAuthService` | 同上 | 登录、校验、退出、`cookieStoreSource` 诊断 |
| `BilibiliQrLoginService` | [bilibili_qr_login_service.dart](../../lib/services/bilibili_qr_login_service.dart) | 二维码轮询登录（桌面） |
| `BilibiliCookieStore` | [bilibili_cookie_store.dart](../../lib/services/bilibili_cookie_store.dart) | `readCookies`、`replaceCookies`、`clearBilibiliCookies` |
| `PlatformBilibiliCookieStore` | 同上 | Android/iOS 原生容器，通道 `com.focubili.app/auth` |
| `WindowsSecureBilibiliCookieStore` | 同上 | 键 `focubili_bilibili_cookie`，系统加密存储 |
| `AppleBilibiliCookieStore` | 同上 | 额外实现 `BilibiliPlaybackSessionStore`：`readPlaybackSession`、`validatePlaybackSession`、`mergePlaybackResponseCookies`（12s 超时） |
| `UnavailableBilibiliCookieStore` | 同上 | 未支持平台拒绝保存，读取返回空 |

### 请求安全与 WBI

| 类型 | 文件 | 要点 |
|---|---|---|
| `BilibiliRequestPolicy` | [bilibili_request_policy.dart](../../lib/services/bilibili_request_policy.dart) | 官方 H5 登录 URI、补 `Mobile` UA、geetest 识别、按 endpoint 生成 Referer；公开请求头不含 Cookie |
| `BilibiliWbiSigningService` | [bilibili_wbi_signing_service.dart](../../lib/services/bilibili_wbi_signing_service.dart) | `signParameters`（1 小时内存缓存、并发共享一次获取）、`deriveMixinKey`、`sign`、`encodeQuery`、`invalidate` |
| `WbiSigningException` | 同上 | 只暴露 HTTP/API 错误码，不回显 URL/Cookie/正文 |
| `MediaUrlPolicy` | [media_url_policy.dart](../../lib/services/media_url_policy.dart) | `normalize`/`isSafe`：仅 HTTPS、已知 CDN 后缀，拒绝凭据/片段/字面 IP |
| `BilibiliDeepLinkService` | [bilibili_deep_link_service.dart](../../lib/services/bilibili_deep_link_service.dart) | 通道 `focubili/deep_links`；冷启动与 `singleTask` 新 Intent |

## 5.2 焦点订阅

`SubscriptionService extends ChangeNotifier`（[subscription_service.dart](../../lib/services/subscription_service.dart)），静态 `instance`。

关键配置：存储键 `focubili_subscriptions_v1`、显示上限 500、已读保留 7 天、来源上限 50、分页预算 `pageBudget`、`requestTimeout`。

关键函数：

- 初始化：`initialize()` / `_initialize()`（兼容 v1/v2 与 backup 恢复）。
- 开关：`setEnabled`、`setNotificationsEnabled`、`setBackgroundRefreshEnabled`、`reconcileBackgroundSchedule`。
- 检查：`refresh({manual})`、`runBackgroundCheck`、`cancelBackgroundCheck`、`reload`。
- 来源：`addSource`、`pauseSource(s)`、`deleteSource(s)`。
- 已读：`markRead`、`markReadBatch`、`markAllRead`、`clearDisplayCache`、`clearExpiredRead`。
- 前台状态：`setForeground`；后台中断记录：`recordBackgroundInterruption`。
- 租约：`_acquireLease()` 防止前台/后台同时刷新。

配套组件：

| 类型 | 文件 | 作用 |
|---|---|---|
| `SubscriptionSnapshotStore` | [subscription_snapshot_store.dart](../../lib/services/subscription_snapshot_store.dart) | SQLite `subscriptions_v2.db`，单行 snapshot 表含 backup/quarantine；`read/recover/transact` CAS |
| `subscriptionAppleBackgroundMain()` / `runAppleSubscriptionWorker` | [subscription_background_service.dart](../../lib/services/subscription_background_service.dart) | iOS headless 入口；runId/generation/budget ≤20s；专注中抑制通知 |
| `NativeSubscriptionScheduler` | [native_subscription_scheduler.dart](../../lib/services/native_subscription_scheduler.dart) | 通道 `com.focubili.app/subscription_scheduler`；`configure(enabled, generation, intervalSeconds≤86400)` |
| `SubscriptionNotificationService` | [subscription_notification_service.dart](../../lib/services/subscription_notification_service.dart) | 通道 `com.focubili.app/subscription_notifications`；`showSummary/showItems`、点击回调、generation guard |
| `SubscriptionHistoryStore` | [subscription_history_store.dart](../../lib/services/subscription_history_store.dart) | 历史导入进度与结果 |
| `SubscriptionRequestScope` | [subscription_request_scope.dart](../../lib/services/subscription_request_scope.dart) | 单轮请求的取消/超时作用域 |

去重模型 `SourceCheckpoint` 保存 seen 集合、锚点、签名、watermark、`scanNewest`、blocked 等索引（[subscription.dart](../../lib/models/subscription.dart)）。

## 5.3 专注

| 类型 | 文件 | 关键函数 |
|---|---|---|
| `FocusTimerController extends ChangeNotifier with WidgetsBindingObserver` | [focus_timer_controller.dart](../../lib/features/focus/focus_timer_controller.dart) | `startFocus`、`pauseFocus`、`interruptFocus`、`resumeFocus`、`updatePlaybackState`、`completeForPlaybackPart`、`associateVideo`、`extendFocus`、`extendCompletedFocus`、`endFocusEarly`、`deleteHistoryEntry`、`clearHistory`、`todayCompletedCount`；目标文字上限 60，时长 1min–3h |
| `FocusSessionService` | [focus_session_service.dart](../../lib/services/focus_session_service.dart) | `loadState` / `saveState`；键 `focubili_focus_active_session`、`focubili_focus_history`；历史上限 200 |
| `FocusSession` | [focus_session.dart](../../lib/models/focus_session.dart) | `start/pauseAt/addInterruption/remainingAt/elapsedAt/progressAt`、打断记录、来源视频、`dailyFocusMilliseconds` |
| `FocusPreferencesService` | [focus_preferences_service.dart](../../lib/services/focus_preferences_service.dart) | 专注偏好与本机开关 |
| `FocusNotificationService` | [focus_notification_service.dart](../../lib/services/focus_notification_service.dart) | Android 通道 / Windows Toast / Linux / Apple；勿扰检查；`AndroidPermissionOverview` |
| `FocusEncouragementService` | [focus_encouragement_service.dart](../../lib/services/focus_encouragement_service.dart) | 读取 `assets/data/focus_encouragements.json` |
| `FocusShareService` | [focus_share_service.dart](../../lib/services/focus_share_service.dart) | 生成专注分享图 |

专注只累计**真实播放区间**：`updatePlaybackState` 依据播放状态推进计时，暂停/缓冲不计入。

## 5.4 学习、笔记、历史、收藏

| 服务 | 存储 | 关键函数与限制 |
|---|---|---|
| `LearningListService` | `focubili_learning_list_v2` | `loadCurrentTask`、`currentTask`、`findEntryForPart`、`nextIncompleteAfter`；上限 100；v1 迁移并备份；串行写队列 |
| `VideoNoteService` | `video_timepoint_notes_v1` | 保存/删除/查询，上限 500；静态 `changes` 广播流；保存时清理旧截图 |
| `VideoNoteExportService` / `VideoNoteShareService` | 文件 | 导出 Markdown/文本与分享 |
| `VideoShotService` | 文件 | 截图保存、缩略图与清理 |
| `WatchHistoryService` | `focubili_watch_history` | `record`、`remove`、`backfillThumbnails`；上限 50；行为开关 |
| `SearchHistoryService` | 偏好键 | 搜索记录上限与清理 |
| `AppFavoritesService` | `app_favorites.folders_v1`、`app_favorites.items_v1.` | 串行 `_mutate`、严格解码、P 数回填 |
| `AppFavoriteImportService` / `AppFavoritesFileService` | 文件 | B 站收藏夹导入、导出文件 |

`LearningListEntry.stableId` 为 `bvid:cid`，`matchesPart` 用于跨分 P 匹配。

## 5.5 离线下载与缓存

### 离线视频

| 类型 | 文件 | 说明 |
|---|---|---|
| `OfflineVideoService` | [offline_video_service.dart](../../lib/services/offline_video_service.dart) | 键 `focubili_offline_videos_v1`；`loadDownloads`、`isDownloaded`、`totalSizeBytes`、`discardPartial`、`availableQualities`、`download`、`delete`、`clearAll`；`revision` ValueNotifier、`activeDownloads`、串行元数据写 |
| `OfflineDownloadQueue` | [offline_download_queue.dart](../../lib/services/offline_download_queue.dart) | 键 `focubili_download_queue_v2`；FIFO 持久任务；`completions` 流；恢复时中断任务转 `paused` |
| `OfflineMediaPlan` | [offline_media_plan.dart](../../lib/services/offline_media_plan.dart) | 解析 DASH 音视频轨或单文件 durl；同档位 AVC/AAC 优先、再选高码率 |
| `ResumableMediaDownload` | [resumable_media_download.dart](../../lib/services/resumable_media_download.dart) | 断点续传；sidecar `.resume` 只存 validator；最多 5 跳重定向；Cookie 头不转发 |
| `DownloadControl` | [download_control.dart](../../lib/services/download_control.dart) | 取消/暂停控制 |
| `DownloadNotificationService` | [download_notification_service.dart](../../lib/services/download_notification_service.dart) | 通道 `com.focubili.app/downloads`，进度通知 |
| `PlaybackSourceResolver` | [playback_source_resolver.dart](../../lib/services/playback_source_resolver.dart) | 仅返回已完成且 BV/CID 精确匹配的本地文件 |

文件保存在应用 documents 目录下按 BV 分目录；DASH 为 video/audio 双文件（`OfflineVideoDownload`）。

### 缓存

| 类型 | 文件 | 说明 |
|---|---|---|
| `MediaCacheService` / `NativeMediaCacheService` / `WindowsMediaCacheService` | [media_cache_service.dart](../../lib/services/media_cache_service.dart) | 容量 128MB–2GB，默认 512MB；Android 走 Media3 持久缓存，桌面管理 libmpv 缓冲 |
| `ImageResourceCache` | [image_resource_cache.dart](../../lib/services/image_resource_cache.dart) | 有界编码图片缓存：默认 256MB、单对象 16MB、容量档 64–512MiB；键为 URL+headers+账户的 sha256；接 `CacheLifecycle`；清理 legacy |
| `CacheLifecycle` | [cache_lifecycle.dart](../../lib/services/cache_lifecycle.dart) | `subtitles`/`account` 失效栅栏；`accountScope`（guest / `mid:`）；`setAccount` |
| `CacheFileLock` | [cache_file_lock.dart](../../lib/services/cache_file_lock.dart) | 跨 isolate/引擎的文件锁 |
| `DesktopDiskCacheSession` | [desktop_disk_cache_session.dart](../../lib/services/desktop_disk_cache_session.dart) | 桌面磁盘缓存会话与清理 |

## 5.6 设置、更新、诊断

| 类型 | 文件 | 要点 |
|---|---|---|
| `SettingsTransferService` | [settings_transfer_service.dart](../../lib/services/settings_transfer_service.dart) | `_schema` 白名单（app_behavior、appearance、app_update、focus、playback_preferences、danmaku、dashboard layout、cache capacity、search filter、device settings）；上限 2MB；`exportSettings` / `parseSettings` |
| `SettingsRuntimeAdapter` | [settings_runtime_adapter.dart](../../lib/services/settings_runtime_adapter.dart) | 导入后应用运行时设置 |
| `AppUpdateService` / `AppUpdateController` | [app_update_service.dart](../../lib/services/app_update_service.dart) | GitHub Release 检查；偏好 `app_update.check_on_start`、`app_update.ignored_release` |
| `ProblemDiagnosticsService` | [problem_diagnostics_service.dart](../../lib/services/problem_diagnostics_service.dart) | 11 类诊断记录；只保存操作名、异常类型、稳定错误码 |
| `AppBehaviorPreferencesService` | [app_behavior_preferences_service.dart](../../lib/services/app_behavior_preferences_service.dart) | 只读保护、观看记录开关等行为偏好 |
| `AppLayoutPreferencesService` / `DashboardLayoutService` | 对应文件 | 布局偏好、首页/“我的”卡片顺序 |
| `FirstLaunchService` | [first_launch_service.dart](../../lib/services/first_launch_service.dart) | 首次启动与协议同意状态 |
| `DeviceStatusService` | [device_status_service.dart](../../lib/services/device_status_service.dart) | 电量/网络/勿扰等设备状态（通道 `com.focubili.app/device_status`） |

## 5.7 持久化键总表

| 存储 | 键/文件 | 内容 |
|---|---|---|
| SharedPreferences | `focubili_subscriptions_v1` | 订阅源、feed、checkpoint、开关 |
| SharedPreferences | `focubili_learning_list_v2` | 学习清单 |
| SharedPreferences | `video_timepoint_notes_v1` | 时间点笔记 |
| SharedPreferences | `focubili_watch_history` | 观看记录（≤50） |
| SharedPreferences | `app_favorites.folders_v1` / `app_favorites.items_v1.` | 软件收藏夹 |
| SharedPreferences | `focubili_offline_videos_v1` | 离线视频元数据 |
| SharedPreferences | `focubili_download_queue_v2` | 下载队列 |
| SharedPreferences | `focubili_focus_active_session` / `focubili_focus_history` | 专注当前/历史（≤200） |
| SharedPreferences | `app_update.check_on_start` / `app_update.ignored_release` | 更新检查 |
| SQLite | `subscriptions_v2.db`（`snapshot` 表） | 订阅原子快照 + backup/quarantine |
| 安全存储 | `focubili_bilibili_cookie` | Windows/Linux 单账号 Cookie |
| 文件 | `documents/` 下 BV 目录 | 离线 video/audio、`.resume` sidecar |
| 文件 | 应用支持目录 | 笔记截图、分享图、导出文件 |
| 原生容器 | Android WebView / Apple WKWebView | B 站 Cookie（Dart 不落盘） |

## 5.8 典型数据流

### 登录

`LoginPage` → `BilibiliAuthService`（官方 WebView/二维码）→ 校验 `/x/web-interface/nav` → `BilibiliCookieStore.replaceCookies` → `CacheLifecycle.setAccount(mid)` → 清空账号相关缓存。

### 订阅刷新

`SubscriptionService.refresh` → `_acquireLease` → 逐源检查（UP 主最近两页；合集正/反各前两页）→ 生成 `SubscriptionFeedItem` → `_mutate` 写快照（SQLite CAS）→ 更新通知 generation → `notifySummary/notifyItems`（专注中抑制）。

### 离线下载

播放页/离线页 → `OfflineMediaPlan.fromData` → `OfflineDownloadQueue.enqueue` → `ResumableMediaDownload`（双轨）→ `OfflineVideoService` 写入元数据 → `completions` → 根组件 Snackbar + `DownloadNotificationService`。

### 专注

`FocusTimerController.startFocus` → 每秒 tick → `FocusSessionService.saveState` → 完成时 `lastFinishedSession` → 根组件庆祝弹窗 → 可续时。

## 5.9 失败与降级原则

1. 存储失败保留内存状态，页面不崩溃。
2. 原生通道缺失（`MissingPluginException`）转为“当前设备暂不支持”提示。
3. 网络失败保留离线元数据（如 `BilibiliVideoInfoService` 的 `_cachedVideo` 回退）。
4. 任何错误消息不得包含 Cookie、临时媒体地址、响应正文。
5. 后台任务有预算上限，未完成内容留给前台或下一轮。

下一章：[06-platform-native.md](06-platform-native.md) → 平台能力与原生层。
