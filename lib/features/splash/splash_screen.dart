import 'dart:async';

import 'package:flutter/material.dart';

/// 启动页：首帧直接铺满与原生启动背景一致的图片，资源就绪后交给主界面。
class SplashScreen extends StatelessWidget {
  /// 创建启动页；首帧即满不透明，避免与原生启动屏之间闪一次品牌图。
  const SplashScreen({super.key});

  /// 启动图资源路径；Android/iOS 原生启动背景使用同一张图片。
  static const String imageAsset = 'assets/splash/bilibili_splash.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 启动图为白底构图，固定使用白色背景，原生启动背景与裁切留白保持同色。
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          imageAsset,
          key: const Key('splash-image'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          // 图片缺失时保留纯白背景，启动流程不被资源异常阻塞。
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) {
                return const ColoredBox(color: Colors.white);
              },
        ),
      ),
    );
  }
}

/// 启动门控：至少展示最短时长，并等待全部启动资源加载完成后再显示主界面。
class SplashGate extends StatefulWidget {
  /// 创建启动门控；测试或桌面调试可关闭启动页直接显示子组件。
  const SplashGate({
    super.key,
    required this.child,
    this.enabled = true,
    this.warmUp,
  });

  final Widget child;
  final bool enabled;

  /// 与启动动画并行的资源加载；全部完成后才切换主界面。
  final Future<void> Function()? warmUp;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

/// 协调最短展示时长与资源加载，并用 150ms 交叉淡出到主界面。
class _SplashGateState extends State<SplashGate> {
  /// 资源加载的最长等待；插件 Future 卡住时也要放行，避免永久停留启动页。
  static const Duration _warmUpTimeout = Duration(seconds: 8);

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _ready = true;
      return;
    }
    unawaited(_runStartup());
  }

  /// 资源加载与最短展示并行；失败或超时都放行，避免首屏出现占位或卡死。
  Future<void> _runStartup() async {
    final Future<void> warmUp = _warmUpSafely();
    await Future.wait<void>(<Future<void>>[
      Future<void>.delayed(const Duration(milliseconds: 420)),
      warmUp,
    ]);
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  /// 预热失败或超过等待上限都放行主界面，避免启动页永久停留。
  Future<void> _warmUpSafely() async {
    final Future<void> task = widget.warmUp?.call() ?? Future<void>.value();
    try {
      await task.timeout(_warmUpTimeout);
    } catch (_) {
      // 忽略失败与超时，主界面照常显示。
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: _ready
          ? widget.child
          : const SplashScreen(key: ValueKey<String>('splash-screen')),
    );
  }
}
