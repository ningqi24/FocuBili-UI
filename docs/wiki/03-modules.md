# 03 · 目录结构与模块职责

本章按 `lib/` 的子目录说明职责，并给出关键类索引。服务层细节见 [05-services-data.md](05-services-data.md)，播放器细节见 [04-player.md](04-player.md)。

## 3.1 `lib/core/` — 横切基础设施

| 文件 | 职责 |
|---|---|
| [router/app_router.dart](../../lib/core/router/app_router.dart) | `AppRoutes` 路由常量、`AppRouter.onGenerateRoute` 唯一导航入口 |
| [theme/app_theme.dart](../../lib/core/theme/app_theme.dart) | `AppTheme.light/dark`、`systemOverlayStyle` |
| [theme/app_text_scale.dart](../../lib/core/theme/app_text_scale.dart) | `AppTextScale` Scope，统一文字缩放 |
| [layout/adaptive_layout.dart](../../lib/core/layout/adaptive_layout.dart) | 宽/窄屏判定与断点 |
| [layout/adaptive_page_frame.dart](../../lib/core/layout/adaptive_page_frame.dart) | 页面统一边距/最大宽度框架 |
| [layout/adaptive_two_column_list.dart](../../lib/core/layout/adaptive_two_column_list.dart) | 宽屏双列列表 |
| [layout/device_orientation_policy.dart](../../lib/core/layout/device_orientation_policy.dart) | 启动/播放方向策略 |
| [layout/app_scroll_behavior.dart](../../lib/core/layout/app_scroll_behavior.dart) | 桌面滚动条/拖拽行为 |
| [widgets/editable_card_board.dart](../../lib/core/widgets/editable_card_board.dart) | 可排序卡片板（首页/“我的”布局） |
| [widgets/editable_card_tile.dart](../../lib/core/widgets/editable_card_tile.dart) | 可编辑卡片项 |
| [widgets/home_theme_background.dart](../../lib/core/widgets/home_theme_background.dart) | 首页主题背景 |
| [utils/bilibili_id_converter.dart](../../lib/core/utils/bilibili_id_converter.dart) | BV/AV 号互转 |
| [build_metadata.g.dart](../../lib/core/build_metadata.g.dart) | 构建期生成：BuildTime、git 修订、兜底版本 |

## 3.2 `lib/models/` — 纯数据模型

| 分组 | 模型 |
|---|---|
| 视频与搜索 | `VideoPreview`、`VideoPart`、`VideoAuthor`、`VideoStats`、`VideoCollection`、`VideoCollectionEntry`、`VideoSearchResult`、`VideoSearchFilter`、`VideoSearchPage`、`SearchOrder`、`PublishedRange`、`DurationRange`、`VideoDescriptionSegment` |
| 订阅 | `SubscriptionKind`、`SubscriptionSource`、`SubscriptionFeedItem`、`SourceCheckpoint`、`subscription_history.dart` 中的历史模型 |
| 专注 | `FocusSession`、`FocusSessionStatus`、`PauseReason`、`InterruptionKind`、`FocusInterruption`、`focus_statistics.dart` |
| 学习/笔记/历史 | `LearningListEntry`、`LearningListStatus`、`VideoNote`、`WatchHistoryEntry`、`VideoShotPreview` |
| 收藏 | `AppFavorite`、`AppFavoritesBackup`、`account_collection.dart`、`public_profile.dart`、`user_search.dart` |
| 播放 | `PlaybackPreferences`、`PreferredPlaybackQuality`、`DoubleTapAction`、`DoubleTapRegions`、`PlaybackBufferRange`、`PlaybackRequestDiagnostic`、`PlayerEnhancement`、`player_overlay_data.dart` |
| 弹幕 | `DanmakuPreferences`、`DanmakuLaunchScheduler`、`DanmakuPresentationWindow`、`DanmakuTimelineIndex` |
| 离线 | `OfflineVideoDownload`、`OfflineDownloadStatus`、`OfflineDownloadTask` |
| 布局 | `DashboardLayout` |

模型约定：JSON 编解码多写在模型内部（`toJson`/`tryParse`/`from...`），服务层只负责读写与合并。

## 3.3 `lib/features/` — 页面与功能模块

| 目录 | 主要页面/组件 | 关键类与职责 |
|---|---|---|
| `shell/` | `MainShell` | 三页常驻、360ms 切换、宽屏 `NavigationRail`、`PopScope` 回首页 |
| `home/` | `HomePage` | 首页卡片板、焦点订阅卡片、专注看板入口 |
| `search/` | `SearchPage`、`search_filter_sheet.dart`、`search_video_row.dart` | 关键词/BV/链接搜索、筛选、结果列表 |
| `player/` | `PlayerPage` 及协调器/视图扩展 | 播放、字幕、弹幕、笔记、专注、学习、听视频、睡眠定时（见 04） |
| `profile/` | `ProfilePage`、`LoginPage`、`UserProfilePage`、`WatchHistoryPage`、`CacheManagementPage`、`OfflineVideosPage`、`FavoriteFoldersPage`、`PersonalizationSettingsPage`、`AboutPage`、`ProblemDiagnosticsPage`、`SystemCapabilitiesPage` 等 | “我的”入口与所有设置/数据管理页面 |
| `subscriptions/` | `SubscriptionUpdatesPage`、`SubscriptionHistoryPage`、`subscription_home_card.dart` | 订阅更新列表、历史导入、首页卡片与引导 |
| `focus/` | `FocusDashboard`、`FocusStatisticsPage`、`FocusTimerController`、`FocusTimerScope`、`FocusDashboardHomeCards` | 专注计时、看板、统计、分享、免打扰、打断弹窗 |
| `learning/` | `LearningListPage`、`LearningAddSheet`、`LearningVideoLauncher` | 学习清单增删、当前任务、从清单打开视频 |
| `notes/` | `VideoNotesPage`、`VideoNoteDetailPage`、`VideoNoteComposer`、`VideoNoteSharePreview` | 时间点笔记浏览、编辑、分享 |
| `onboarding/` | `FirstLaunchGate`、`UserAgreementPage` | 首次启动协议门、协议内容 |
| `common/` | `AppNetworkImage`、`WatchHistoryBadge` | 统一网络图片（带缓存/占位）与观看进度角标 |

### 关键类速查（页面层）

| 类 | 位置 | 说明 |
|---|---|---|
| `PlayerPage` / `_PlayerPageState` | [player_page.dart](../../lib/features/player/player_page.dart) | 播放页唯一 State，混入 12 个协调器 |
| `PlaybackResumePlan` | [playback_resume_plan.dart](../../lib/features/player/playback_resume_plan.dart) | 续播位置、来源、跨路由恢复计划 |
| `PlayerEnhancementController` | [enhancements/player_enhancement_controller.dart](../../lib/features/player/enhancements/player_enhancement_controller.dart) | 章节、互动节点、播放完成覆盖层 |
| `FocusTimerController` | [focus_timer_controller.dart](../../lib/features/focus/focus_timer_controller.dart) | 专注状态机、历史、免打扰、播放联动 |
| `AppThemeModeController` | [app_theme_mode_controller.dart](../../lib/features/profile/app_theme_mode_controller.dart) | 主题模式持久化 |
| `AppTextScaleController` | [app_text_scale_controller.dart](../../lib/features/profile/app_text_scale_controller.dart) | 文字缩放持久化 |
| `FirstLaunchGate` | [first_launch_gate.dart](../../lib/features/onboarding/first_launch_gate.dart) | 协议同意前阻止外部导航与剪贴板监听 |

## 3.4 `lib/platform/` — 平台抽象

| 文件 | 关键类型 |
|---|---|
| [app_platform.dart](../../lib/platform/app_platform.dart) | `AppPlatform` 枚举；`AppPlatformDetector.current/resolve/isFlutterTest`；`isApple/isDesktop/isMobile/displayName` |
| [platform_capabilities.dart](../../lib/platform/platform_capabilities.dart) | `PlaybackBackendKind`、`PlayerOverlayBackendKind`、`MediaCacheBackendKind`、`CookieStoreBackendKind`、`FocusNotificationBackendKind`、`LoginExperience`、`SystemCapabilitiesExperience`、`AppUpdateTargetPlatform`、`PlatformCapabilities` |
| [platform_services.dart](../../lib/platform/platform_services.dart) | `PlatformServices.current`；`createPlaybackService/createPlayerOverlayService/createMediaCacheService/createBilibiliCookieStore/createFocusNotificationService` |

详见 [06-platform-native.md](06-platform-native.md)。

## 3.5 `lib/services/` — 服务层

81 个文件、约 227 个类/枚举/mixin/typedef 声明，按领域划分为 9 组：

1. B 站接口与鉴权（`bilibili_service`、`bilibili_auth_service`、`bilibili_public_content_service`、`bilibili_interaction_service`、`bilibili_wbi_signing_service`、`bilibili_qr_login_service`、`bilibili_cookie_store`、`bilibili_request_policy`、`bilibili_account_data_service`、`bilibili_deep_link_service`、`bilibili_player_enhancement_service`）。
2. 播放抽象（`native_playback_service`、`windows_playback_service`、`playback_service_factory`、`player_overlay_service`、`desktop_player_overlay_service`、`cached_player_overlay_service`、`player_route_session`、`playback_source_resolver`、`playback_preferences_service`、`playback_resume_policy`）。
3. 缓存（`media_cache_service`、`media_cache_service_factory`、`image_resource_cache`、`cache_lifecycle`、`cache_file_lock`、`desktop_disk_cache_session`）。
4. 离线下载（`offline_video_service`、`offline_download_queue`、`offline_media_plan`、`resumable_media_download`、`download_control`、`download_notification_service`、`windows_dash_media_plan`）。
5. 订阅（`subscription_service`、`subscription_snapshot_store`、`subscription_background_service`、`native_subscription_scheduler`、`subscription_notification_service`、`subscription_notification_delivery`、`subscription_history_store`、`subscription_request_scope`、`subscription_onboarding_service`）。
6. 学习/笔记/历史/收藏（`learning_list_service`、`video_note_service`、`video_note_export_service`、`video_note_share_service`、`watch_history_service`、`app_favorites_service`、`app_favorite_import_service`、`app_favorites_file_service`、`search_history_service`）。
7. 专注（`focus_session_service`、`focus_preferences_service`、`focus_notification_service`、`windows_focus_notification_service`、`linux_focus_notification_service`、`focus_encouragement_service`、`focus_share_service`）。
8. 设置/更新/诊断（`settings_transfer_service`、`settings_runtime_adapter`、`app_update_service`、`app_behavior_preferences_service`、`app_theme_mode_service`、`app_text_scale_service`、`app_layout_preferences_service`、`dashboard_layout_service`、`problem_diagnostics_service`、`data_transfer_file_service`、`first_launch_service`）。
9. 平台桥接/桌面（`device_status_service`、`windows_experience_service`、`windows_do_not_disturb_service`、`windows_clipboard_link_service`、`windows_official_login_service`、`linux_media_session`、`linux_mini_player`、`external_link_service`、`webview_environment_service`、`subtitle_diagnostic_log`、`flutter_video_frame_capture`、`video_shot_service`）。

各组关键类/函数见 [05-services-data.md](05-services-data.md)。

## 3.6 依赖边界小结

| 允许的依赖 | 禁止的依赖 |
|---|---|
| `features → core/models/services` | `services → features`（除播放器 Scope 等极少数回调注入） |
| `services → models/platform` | `models → services`（模型不得反向依赖服务） |
| `platform → services/platform` | `core → features` |
| `features/player → services/player_*` | 页面直接 `MethodChannel` 调用（应经服务封装） |

下一章：[04-player.md](04-player.md) → 播放器子系统。
