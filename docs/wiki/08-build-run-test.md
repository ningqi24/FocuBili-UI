# 08 · 构建、运行与测试

## 8.1 环境要求

| 平台 | 要求 |
|---|---|
| 通用 | Flutter 3.44.6（Linux 构建使用 3.47.5），Dart 随 Flutter；Git |
| Android | JDK 21、Android SDK 36、NDK 28.2.13676358 |
| Windows | Visual Studio 2022“C++ 桌面开发”、Windows SDK、ATL；安装器另需 Inno Setup 6 |
| iOS/macOS | Xcode、CocoaPods；iOS 真机需自签名与 provisioning profile |
| Linux | Ubuntu 24.04 系列、GTK/libmpv/dbus 开发库、CMake |

## 8.2 初始化

```bash
git clone https://github.com/ningqi24/FocuBili-UI.git
cd FocuBili
flutter pub get
dart tool/write_build_metadata.dart
```

`write_build_metadata.dart` 读取 `pubspec.yaml` 版本与 `git HEAD`，生成 [lib/core/build_metadata.g.dart](../../lib/core/build_metadata.g.dart)（`appBuildTime`、`appSourceRevision`、`appFallbackVersion`）。CI 在构建 APK/Windows 前都会执行。

## 8.3 运行与构建

### Android

```bash
flutter run
flutter build apk --debug
flutter build apk --release   # 需要发布签名配置
```

- debug 包名 `com.focubili.app.preview`，版本后缀 `-preview`。
- beta 包为 `.preview` + `-beta.N`。
- 正式包与 debug/beta 数据不自动迁移。

### Windows

```bash
flutter build windows --release
.\windows\installer\build_windows_packages.ps1
```

- 编译输出：`build/windows/x64/runner/Release/`。
- 安装器/便携 ZIP 输出：`build/windows/x64/installer/`。
- `FocuBili.exe` 依赖同目录 DLL 与 `data/`，不能单独复制。
- MSIX 使用 `msix` 与 `msix_config`（`identity_name com.focubili.app`）。

### Apple

构建与签名限制见 [docs/APPLE_PLATFORMS.md](../APPLE_PLATFORMS.md)。要点：

- iOS Release 为未签名真机 IPA，不是模拟器包，也不是 App Store/TestFlight 包。
- macOS 为 universal DMG，ad-hoc 签名、未公证。
- CI 使用 [tool/verify_macos_dmg.py](../../tool/verify_macos_dmg.py)、[tool/check_apple_sources.py](../../tool/check_apple_sources.py) 等探针。

### Linux

```bash
tool/package_linux.sh
```

- 产物为 `.deb`（Ubuntu 24.04 系列 / amd64）。
- 构建检查脚本：[tool/check_linux_runtime.sh](../../tool/check_linux_runtime.sh)、[tool/check_linux_launch.sh](../../tool/check_linux_launch.sh)。

## 8.4 代码质量与测试

### Dart

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

### Android JVM

```bash
cd android
./gradlew :app:testDebugUnitTest :focubili_android:testDebugUnitTest --no-daemon
```

覆盖：方向策略、缓存键、编码边界、播放阶段/恢复/续播、轨道策略、字幕文档身份、WBI 策略等。

### Python 工具

```bash
python3 -m unittest discover -s tool -p "test_*.py" -v
```

覆盖发布、Linux 打包/替换、macOS 身份与 DMG、原生订阅探针等。

### 测试规模

| 类型 | 位置 | 数量 |
|---|---|---|
| Dart 单元/Widget 测试 | `test/` | 184 个 `*_test.dart`，含 `fixtures/` 与 `support/` |
| 集成测试 | `integration_test/` | 4 个：`apple_smoke_test`、`media_fixture`、`player_windows_v18_test`、`subscription_snapshot_store_test` |
| Kotlin JVM 单测 | `android/app/src/test`（11）、`packages/focubili_android/android/src/test`（6） | 17 个 |
| Python 工具测试 | `tool/test_*.py` | 覆盖打包/发布/探针 |

常见专项回归：

```bash
flutter test test/player_action_feedback_test.dart test/player_feedback_layout_test.dart \
  test/player_tap_gesture_test.dart test/subscription_migration_test.dart \
  test/subscription_request_scope_test.dart test/cache_file_lock_test.dart \
  test/image_resource_cache_test.dart test/cached_player_overlay_service_test.dart \
  test/windows_media_cache_service_test.dart test/desktop_disk_cache_session_test.dart
```

## 8.5 CI 工作流（`.github/workflows/`）

| 工作流 | 触发 | 内容 |
|---|---|---|
| `ci.yml` | PR（dev/master/`iOS＆MacOS`）、push（dev/master）、手动 | **quality**：格式、`flutter analyze`、`flutter test`、Beta 工具测试；**android**：JVM 测试 + debug APK + 元数据/签名校验；**windows**：手势/缓存/历史回归 + debug 构建 + 原生订阅探针 |
| `apple-build.yml` | push/PR（ios、macos、packages、lib、tool、pubspec 变更）、手动、可复用 | Python 工具检查、`flutter pub get`、格式、analyze、test、iOS/macOS 构建、原生探针、DMG 校验 |
| `apple-session.yml` | `packages/focubili_apple`、`lib/services/bilibili*`、会话探针脚本变更 | WK Cookie/播放会话探针（`bilibili_session_probe.swift`、`run_apple_cookie_probe.py`） |
| `linux-build.yml` | linux/lib/test/third_party/pubspec/tool 变更、手动、可复用 | Linux 构建与运行检查、`.deb` 打包 |
| `release-build.yml` | master 上 `pubspec.yaml`/Release Notes/Android 构建脚本变更 | 正式构建（Android/Windows/Apple/Linux） |
| `beta-release.yml` | 手动（输入 source_sha 与 beta_number） | Beta 版本发布与 APK 元数据校验 |
| `publish-release.yml` | master 上 Release Notes/替换脚本变更 | Release 资产上传与校验 |
| `macos-hotfix.yml` | 手动（输入 source_sha） | macOS 1.8 热修复包构建 |

CI 固定 `FLUTTER_VERSION: 3.44.6`；质量任务是 Android/Windows 构建的前置。

## 8.6 发布与版本

- 版本唯一来源：`pubspec.yaml` 的 `version: 1.8.1+31`。
- Windows 安装器从 `pubspec.yaml` 读取版本。
- Android 正式发布链路会核对历史签名证书；debug/beta 使用不同 applicationId 后缀。
- 发布说明格式见 `docs/RELEASE_NOTES_v1.8.1.md`；Beta 发布工具见 [tool/beta_release.py](../../tool/beta_release.py) 与 [tool/test_beta_release.py](../../tool/test_beta_release.py)。

## 8.7 常见问题排查

| 现象 | 排查 |
|---|---|
| 桌面播放黑屏/无纹理 | 确认 `MediaKit.ensureInitialized()`、`media_kit_video` 补丁与本平台 libs |
| 字幕/弹幕为空 | 检查登录状态、`CacheLifecycle` 代次、原生通道 `com.focubili.app/playback` |
| 订阅后台不执行 | Android 检查通知/后台权限、省电策略、WorkManager；iOS 检查 BGAppRefresh；桌面仅进程存活时有效 |
| Windows 登录窗口异常 | 确认使用 `third_party/desktop_webview_window` 而非 pub 版本 |
| 设置导入失败 | 检查 2MB 上限与白名单 schema；导入前会校验并回滚 |
| Linux Cookie 保存失败 | 检查 libsecret/密钥环可用性 |

## 8.8 贡献流程

1. PR 目标分支为 `dev`。
2. 提交前执行格式、analyze、test；涉及播放器时按 [docs/PLAYER_ARCHITECTURE.md](../PLAYER_ARCHITECTURE.md) 回归命令验证。
3. 不提交真实 Cookie、构建产物或签名材料。
4. 遵守 GPL-3.0 与第三方许可（[THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md)）。

返回索引：[README.md](README.md)
