# 01 · 项目概览与技术栈

## 1.1 项目定位

FocuBili（焦点哔哩）是一个**面向学习的第三方 B 站客户端**：不做无限推荐流，而是“主动搜索、按需订阅、专注观看”。项目为个人学习与技术研究项目，与哔哩哔哩官方无隶属关系，依赖非官方公开接口，不绕过付费、会员、课堂、私密内容等访问控制。

核心产品思路：

- 首页不给推荐流，只提供“开始搜索”和少量焦点订阅卡片。
- 订阅在本机完成轮询与更新聚合，可选系统通知与后台检查。
- 观看与专注结合：专注计时、学习清单、时间点笔记、专注统计。
- 所有个人数据保存在当前设备，无自建服务器、无云端同步。

## 1.2 功能清单

| 功能域 | 能力 |
|---|---|
| 搜索与浏览 | 关键词 / BV 号 / B 站链接搜索；UP 主主页、投稿、专栏、合集；分 P；UGC 合集 |
| 焦点订阅 | 本机订阅 UP 主与合集；首页更新卡片；多选、已读、加入学习清单；后台检查与系统通知 |
| 播放 | DASH 播放、清晰度、倍速、字幕、弹幕、画中画（Android/Apple）、听视频（Android）、后台媒体控制（Android） |
| 学习 | 学习清单（按分 P 记录）、当前任务、完成后继续、与播放器联动 |
| 专注 | 专注计时（1 分钟 ~ 3 小时）、暂停/打断记录、免打扰、专注统计、分享 |
| 笔记 | 时间点笔记、当前画面截图、跨分 P、导出/分享、笔记提示 |
| 本机数据 | 软件收藏夹、观看记录、搜索记录、离线视频、缓存管理、设置导入导出、登录信息迁移 |
| 个性化 | 主题、文字缩放 80%–200%、首页/“我的”卡片排序、双击区域、长按倍速、控制层尺寸 |
| 诊断与更新 | 问题诊断（构建号/BuildTime/脱敏状态）、GitHub Release 更新检查、系统能力页 |

## 1.3 平台支持

| 平台 | 最低版本 | 播放后端 | 登录方式 | 特殊能力 |
|---|---|---|---|---|
| Android | 7.0+（`minSdkVersion` 由 Flutter 决定） | Media3（ExoPlayer，原生 Kotlin） | 官方 WebView | 画中画、勿扰、听视频、后台媒体控制、WorkManager 后台订阅 |
| Windows | 10 1809+ / x64 | media_kit（libmpv） | 官方二维码 + WebView2（`desktop_webview_window`） | 桌面窗口、系统 Toast、Windows 体验通道 |
| iOS | 真机（未签名 IPA 分发） | media_kit（Apple 原生 libs） | 官方 WebView | 画中画、BGAppRefresh 后台订阅 |
| macOS | universal DMG（ad-hoc 签名） | media_kit | 官方 WebView | 画中画、桌面窗口、桌面定时调度 |
| Linux | Ubuntu 24.04 系列 / amd64 | media_kit（libmpv，dbus） | 官方二维码 | 桌面窗口、Linux 通知、桌面定时调度 |

平台能力并不等价，统一由 [platform_capabilities.dart](../../lib/platform/platform_capabilities.dart) 描述，详见 [06-platform-native.md](06-platform-native.md)。

## 1.4 技术栈

| 层面 | 选型 |
|---|---|
| UI 框架 | Flutter / Material 3，中文 `flutter_localizations`，自建 `AppTheme` 明暗主题 |
| 状态管理 | `ChangeNotifier` + 自定义 Scope/InheritedWidget；无 Provider/Bloc/Riverpod |
| 页面导航 | `onGenerateRoute` + 集中式 `AppRouter`（无 go_router） |
| 网络 | `dart:io HttpClient`（公开 JSON、DASH、下载）、原生 HTTP（Android 字幕/弹幕/播放数据） |
| 本地存储 | `SharedPreferences`（JSON）、`sqflite`（订阅快照）、文件（离线视频/截图）、`flutter_secure_storage`（Windows/Linux Cookie） |
| 播放 | Android Media3；桌面/Apple `media_kit` + 仓库内补丁版 `media_kit_video` |
| 原生桥接 | `MethodChannel`，通道名统一 `com.focubili.app/*` |
| 通知/后台 | `flutter_local_notifications`（Windows Toast）、原生通知通道、WorkManager（Android）、BGTask（Apple） |
| 分享/导出 | `share_plus`、`file_picker`、`archive` |
| WebView | `webview_flutter`（Android/iOS）、补丁版 `desktop_webview_window`（Windows） |
| 测试 | `flutter_test`、`integration_test`、Kotlin JVM 单测、Python `unittest` 工具测试 |

## 1.5 版本与工具链

- 应用版本：`pubspec.yaml` 中 `version: 1.8.1+31`。
- Dart 约束：`sdk: >=3.10.0 <4.0.0`；Flutter 约束：`>=3.44.0`。
- CI 固定 Flutter `3.44.6`（Apple/Android/Windows），Linux 构建使用 Flutter `3.47.5`。
- Android：JDK 21、Android SDK 36（`compileSdkVersion 36`）、NDK 28.2.13676358。
- Windows：Visual Studio 2022 C++ 桌面开发、Windows SDK、ATL；安装器需要 Inno Setup 6。
- 构建元数据由 [tool/write_build_metadata.dart](../../tool/write_build_metadata.dart) 生成到 `lib/core/build_metadata.g.dart`（BuildTime、git HEAD、兜底版本）。

## 1.6 仓库顶层结构

```text
FocuBili/
├── lib/                 # Dart 应用代码（唯一的跨平台业务层）
│   ├── main.dart        # 进程入口与全局初始化
│   ├── app.dart         # 根组件、全局控制器与 Scope
│   ├── core/            # 路由、主题、自适应布局、通用组件、构建元数据
│   ├── features/        # 功能页面（shell/home/search/player/profile/...）
│   ├── models/          # 纯数据模型与序列化
│   ├── platform/        # 平台枚举、能力表、服务装配入口
│   └── services/        # 服务层（B 站接口、存储、缓存、通知、更新、诊断…）
├── android/             # Android Runner + Kotlin 原生播放/设备/深链/下载/提醒
├── packages/
│   ├── focubili_android/# Android 端插件（Cookie、订阅通知）
│   └── focubili_apple/  # iOS/macOS 插件（Cookie、通知、PiP、调度、媒体会话）
├── ios/  macos/         # Apple Runner
├── windows/             # Windows Runner（C++：单实例、窗口、体验通道）
├── linux/               # Linux Runner（CMake、打包元数据）
├── third_party/         # 仓库内补丁依赖（WebView、media_kit_video、workmanager）
├── assets/              # 图标与鼓励语料
├── tool/                # 构建元数据、平台探针、发布/打包脚本、Python 工具测试
├── test/                # 184 个 Dart 测试文件 + fixtures/support
├── integration_test/    # 4 个集成测试入口
├── docs/                # 设计与发布文档（本 Wiki 位于 docs/wiki）
└── .github/workflows/   # 8 条 CI/发布工作流
```

## 1.7 数据与隐私边界

- 无自建服务器；学习清单、笔记、专注记录、搜索/观看记录均在本机。
- 手机号、密码、人机验证在 B 站官方网页完成，应用不收集 B 站密码。
- Android 的 Cookie 保存在 WebView Cookie 容器，Dart 侧不落盘；Windows/Linux 使用系统加密存储；Apple 使用 WKWebView 容器并支持播放会话事务。
- 登录信息导出文件含明文 Cookie，导入前必须经 B 站接口验证成功才切换账号。
- 诊断与错误记录只保留操作名、异常类型、稳定错误码，不回显 Cookie、临时地址或响应正文。
- 媒体地址统一经过 `MediaUrlPolicy`：仅 HTTPS、仅 `bilivideo.com`/`bilivideo.cn` 及其子域。

## 1.8 第三方参考与许可

项目在 [README.md](../../README.md#致谢) 中致谢 PiliPala（Flutter 客户端架构思路）、PiliPlus（空间公开接口/WBI/弹幕调度）与 JKVideo（原生 DASH 与单一播放器所有权）。详细许可见 [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md)，项目整体以 GPL-3.0 发布。

下一章：[02-architecture.md](02-architecture.md) → 整体架构与启动流程。
