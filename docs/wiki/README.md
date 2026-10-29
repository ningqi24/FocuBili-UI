# FocuBili · 焦点哔哩 — Code Wiki

> 本目录是 FocuBili 项目的结构化 Code Wiki。内容基于仓库源码（`lib/`、`android/`、`ios/`、`macos/`、`linux/`、`windows/`、`packages/`、`third_party/`、`tool/`）整理，面向希望快速理解、修改或扩展本项目的开发者。

## 文档索引

| 文档 | 内容 |
|---|---|
| [01-overview.md](01-overview.md) | 项目定位、功能清单、平台支持、技术栈与版本、仓库顶层结构、隐私边界 |
| [02-architecture.md](02-architecture.md) | 分层架构、启动流程、路由与状态管理、平台能力抽象、关键跨模块约束 |
| [03-modules.md](03-modules.md) | `lib/core`、`lib/models`、`lib/features` 的目录职责与关键类索引 |
| [04-player.md](04-player.md) | 播放器子系统的所有权模型、协调器、视图扩展、平台播放实现、字幕弹幕缓存 |
| [05-services-data.md](05-services-data.md) | 服务层目录、B 站接口与鉴权、六大业务域、持久化键与数据流 |
| [06-platform-native.md](06-platform-native.md) | 平台能力矩阵、MethodChannel 清单、Android/iOS/macOS/Windows/Linux 原生层 |
| [07-dependencies.md](07-dependencies.md) | 外部依赖、本地路径包、`third_party`、内部模块依赖方向与依赖图 |
| [08-build-run-test.md](08-build-run-test.md) | 环境要求、构建与运行命令、测试体系、代码质量检查、CI 工作流与发布 |

## 快速事实

| 项目 | 值 |
|---|---|
| 应用名 | FocuBili（焦点哔哩），第三方 B 站客户端 |
| 版本 | `1.8.1+31`（见 [pubspec.yaml](../../pubspec.yaml)） |
| 框架 | Flutter 3.44.6（Linux 使用 3.47.5），Dart SDK `>=3.10.0 <4.0.0` |
| 支持平台 | Android 7.0+、Windows 10 1809+（x64）、iOS、macOS、Ubuntu 24.04 系列（amd64） |
| Dart 代码规模 | `lib/` 约 251 个文件、约 77,000 行 |
| 入口 | [lib/main.dart](../../lib/main.dart) → [lib/app.dart](../../lib/app.dart) |
| 原生包 | [packages/focubili_android](../../packages/focubili_android)、[packages/focubili_apple](../../packages/focubili_apple) |
| 补丁依赖 | [third_party/desktop_webview_window](../../third_party/desktop_webview_window)、[third_party/media_kit_video](../../third_party/media_kit_video)、[third_party/workmanager](../../third_party/workmanager) |
| 许可证 | GPL-3.0 |

## 推荐阅读路径

- **想快速跑起来**：先读 [01-overview.md](01-overview.md)，再按 [08-build-run-test.md](08-build-run-test.md) 配置环境。
- **想理解整体设计**：按 [02-architecture.md](02-architecture.md) → [03-modules.md](03-modules.md) 顺序阅读。
- **要改播放器**：直接读 [04-player.md](04-player.md)，并配合 [docs/PLAYER_ARCHITECTURE.md](../PLAYER_ARCHITECTURE.md) 的分层规则。
- **要改业务/存储**：读 [05-services-data.md](05-services-data.md)。
- **要动原生代码**：读 [06-platform-native.md](06-platform-native.md)，确认通道契约与平台能力表。
- **要加依赖或拆分模块**：读 [07-dependencies.md](07-dependencies.md)。

## 文档约定

- 文中源码链接均使用相对路径（如 `../../lib/main.dart`），可直接在编辑器或 GitHub 中跳转。
- “关键类/函数”以仓库中实际存在的声明为准；行号易随重构漂移，因此以符号名和文件名定位为主。
- 涉及平台能力时，以 [platform_capabilities.dart](../../lib/platform/platform_capabilities.dart) 的能力表为唯一事实来源，页面不直接判断 `Platform.isX`。

## 文档维护约定

> [!IMPORTANT]
> 本 Wiki 必须与代码同步维护。任何影响架构、模块职责、关键类/函数、依赖关系、持久化键、平台通道、构建或测试流程的新改动，都应在**同一个 PR / 同一批提交**中更新对应章节；不得留到后续“有空再补”。

维护对照：

| 代码改动 | 需要同步的文档 |
|---|---|
| 启动流程、路由、全局控制器、跨模块约束 | [02-architecture.md](02-architecture.md) |
| 新增/删除页面、目录职责、关键类 | [03-modules.md](03-modules.md) |
| 播放器协调器、播放后端、字幕弹幕、原生播放链 | [04-player.md](04-player.md) |
| 服务函数、业务域、SharedPreferences/SQLite/文件键 | [05-services-data.md](05-services-data.md) |
| 平台能力表、MethodChannel、原生 Runner/插件 | [06-platform-native.md](06-platform-native.md) |
| `pubspec.yaml`、`third_party/`、模块依赖方向 | [07-dependencies.md](07-dependencies.md) |
| 构建命令、测试数量/入口、CI 工作流、发布流程 | [08-build-run-test.md](08-build-run-test.md) |
| 版本号、平台支持范围、产品能力清单 | [01-overview.md](01-overview.md) 与 [README.md](../../README.md) |

审阅时若发现文档未同步，应将其视为 PR 的阻塞项。更新文档时请同步修改“最后核对”信息，便于判断时效性。

- 最后核对：`1.8.1+31` / Flutter `3.44.6`（2026-10-29）。
