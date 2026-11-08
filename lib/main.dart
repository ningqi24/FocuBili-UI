import 'services/media_cache_service.dart';
import 'services/cache_lifecycle.dart';
import 'services/image_resource_cache.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'platform/platform_services.dart';
import 'platform/app_platform.dart';
import 'platform/platform_capabilities.dart';
import 'services/problem_diagnostics_service.dart';
import 'services/apple_video_capabilities.dart';
import 'services/linux_focus_notification_service.dart';
import 'services/linux_mini_player.dart';
import 'services/subscription_service.dart';
import 'services/app_layout_preferences_service.dart';
import 'core/layout/device_orientation_policy.dart';

/// 注册框架和 Dart 未捕获错误的最小诊断记录；只保存固定操作名与异常类型，绝不保存异常原文或堆栈。
void _installProblemDiagnostics() {
  final ProblemDiagnosticsService diagnostics = ProblemDiagnosticsService();
  final void Function(FlutterErrorDetails details)?
  previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // 框架错误回调先沿用原来的控制台呈现行为，避免改变开发和测试时的报错可见性。
    previousFlutterErrorHandler?.call(details);
    // runtimeType 只包含异常类名，可帮助区分布局、状态和平台错误，同时不会带入异常正文或用户数据。
    unawaited(
      diagnostics.recordUnexpectedError(
        operation: 'flutter_framework',
        errorType: details.exception.runtimeType.toString(),
      ),
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    // Dart 异步未捕获错误同样只写固定分类和异常类名；返回 false 保留系统原有的未处理错误行为。
    unawaited(
      diagnostics.recordUnexpectedError(
        operation: 'dart_runtime',
        errorType: error.runtimeType.toString(),
      ),
    );
    return false;
  };
}

/// 按能力表初始化桌面媒体后端与窗口；移动平台不会加载这些桌面行为。
Future<void> _prepareWindowsDesktop({
  PlatformServices? platformServices,
}) async {
  final PlatformServices services =
      platformServices ?? PlatformServices.current;
  if (services.capabilities.playbackBackend == PlaybackBackendKind.mediaKit) {
    MediaKit.ensureInitialized();
    await AppleVideoCapabilities.initialize();
  }
  if (!services.capabilities.supportsDesktopWindow) {
    return;
  }
  await windowManager.ensureInitialized();
  var initialSize = const Size(1280, 800);
  var minimumSize = const Size(900, 640);
  if (services.platform == AppPlatform.macos ||
      services.platform == AppPlatform.linux) {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      final display = views.first.display;
      final screen = display.size / display.devicePixelRatio;
      if (screen.width > 0 && screen.height > 0) {
        initialSize = Size(
          (screen.width - 40).clamp(640.0, 1280.0),
          (screen.height - 100).clamp(480.0, 800.0),
        );
        minimumSize = Size(
          initialSize.width.clamp(640.0, 900.0),
          initialSize.height.clamp(480.0, 640.0),
        );
      }
    }
  }
  if (services.platform == AppPlatform.linux) {
    LinuxMiniPlayer.normalMinimumSize = minimumSize;
  }
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: initialSize,
      minimumSize: minimumSize,
      center: true,
      backgroundColor: Color(0xFFF7F8FC),
      title: 'Focubili-UIX',
    ),
  );
  await windowManager.show();
  await windowManager.focus();
  if (services.platform == AppPlatform.linux) {
    await LinuxFocusNotificationBackend.instance.isAvailable();
  }
}

/// 启动页展示期间读取并解码全部声明的图片资源，避免主界面首帧出现占位或闪烁。
Future<void> _preloadStartupResources() async {
  try {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<String> assets = manifest.listAssets();
    // 先把所有声明资源读入内存，字体与图片随后分别由引擎和图片缓存接管。
    await Future.wait<void>(
      assets.map((String asset) async {
        try {
          await rootBundle.load(asset);
        } catch (_) {}
      }),
    );
    // 图片需要真正解码进图片缓存，主界面复用时才能首帧直接绘制。
    await Future.wait<void>(
      assets.where(_isImageAsset).map(_precacheAssetImage),
    );
  } catch (_) {}
}

/// 只预加载构建产物中的图片资源，JSON 等文本资源按需读取。
bool _isImageAsset(String asset) {
  final String lower = asset.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}

/// 将单张图片解码到全局图片缓存；失败时静默跳过，不阻塞启动门控。
Future<void> _precacheAssetImage(String asset) {
  final Completer<void> completer = Completer<void>();
  final ImageStream stream = AssetImage(
    asset,
  ).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo image, bool synchronousCall) {
      stream.removeListener(listener);
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
    onError: (Object error, StackTrace? stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
  );
  stream.addListener(listener);
  return completer.future;
}

/// 启动动画期间并行加载资源、预热缓存与订阅；全部完成后才显示主界面。
Future<void> _warmUpStartup() async {
  await _preloadStartupResources();
  try {
    await CacheLifecycle.initialize();
  } catch (_) {}
  unawaited(ImageResourceCache.cleanLegacyCache());
  unawaited(
    ImageResourceCache.instance.status().catchError(
      (Object _) => const ImageCacheUsage(0, 0, 0),
    ),
  );
  if (PlatformServices.current.capabilities.mediaCacheBackend ==
      MediaCacheBackendKind.windowsMediaKit) {
    try {
      await WindowsMediaCacheService().maintain();
    } catch (_) {}
  }
  // Reconcile persisted opt-in after an upgrade/restart; disabled by default.
  try {
    await SubscriptionService.instance.initialize();
    await SubscriptionService.instance.reconcileBackgroundSchedule();
  } catch (_) {
    // Subscription storage/scheduler failures must not prevent app startup.
    // The subscriptions page exposes its persisted/error status for retry.
  }
}

/// 初始化 Flutter 绑定、系统栏样式，并启动Focubili-UIX应用。
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // WebView2 子窗口进程只绘制插件标题栏，不重复初始化完整Focubili-UIX应用。
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  _installProblemDiagnostics();
  // 液态玻璃底栏需要预先载入着色器，避免首帧出现空白或闪烁；失败时继续启动。
  try {
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  } catch (_) {}
  // 布局只在启动时载入；设置页明确提示重启，避免播放中强制旋转。
  try {
    await const AppLayoutPreferencesService().initialize();
  } catch (_) {
    // 偏好读取失败时仍使用原有自动布局，让应用可进入设置恢复。
  }
  if (AppPlatformDetector.current == AppPlatform.ios) {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      await SystemChrome.setPreferredOrientations(
        DeviceOrientationPolicy.startupOrientations(
          logicalSize: DeviceOrientationPolicy.logicalSizeForView(views.first),
          isMobile: true,
        ),
      );
    }
  }
  await _prepareWindowsDesktop();
  // Android 启动方向由 MainActivity 在 Flutter 首帧前决定，避免未稳定的窗口尺寸把平板误判成手机。
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 首帧前先按浅色背景设置深色系统图标，后续由应用主题自动同步明暗模式。
  SystemChrome.setSystemUIOverlayStyle(
    AppTheme.systemOverlayStyle(Brightness.light),
  );
  runApp(
    LiquidGlassWidgets.wrap(
      // MaterialApp 下必须桥接应用主题的明暗，否则玻璃边框和阴影在系统深色模式下会错位。
      brightnessResolver: Theme.maybeBrightnessOf,
      child: const FocuBiliApp(
        checkForUpdatesOnStart: true,
        // 真实启动展示启动页；资源加载与缓存预热全部完成后进入主界面。
        showSplash: true,
        startupTasks: _warmUpStartup,
      ),
    ),
  );
}
