import 'dart:async';

import 'package:flutter/material.dart';

/// 静默启动页：全屏铺满与原生启动背景一致的图片，资源就绪后交给主界面。
class SplashScreen extends StatefulWidget {
  /// 创建启动页；图片只做一次淡入，不循环、不额外叠加文案。
  const SplashScreen({super.key});

  /// 启动图资源路径；Android/iOS 原生启动背景使用同一张图片。
  static const String imageAsset = 'assets/splash/bilibili_splash.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// 用 300ms 淡入替代首帧硬切，避免原生启动背景切换到 Flutter 时闪白。
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 淡入时长；启动门控至少展示该时长，保证过渡完整。
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  /// 首帧立即开始淡入，与并行资源预热互不阻塞。
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fadeDuration)
      ..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  /// 释放动画控制器，避免启动页切走后继续占用帧回调。
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 启动图为白底构图，固定使用白色背景，原生启动背景与裁切留白保持同色。
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _opacity,
          child: Image.asset(
            SplashScreen.imageAsset,
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
      ),
    );
  }
}

/// 启动门控：至少展示淡入时长，并等待全部启动资源加载完成后再显示主界面。
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

/// 协调淡入动画与资源加载，并用 150ms 交叉淡出到主界面。
class _SplashGateState extends State<SplashGate> {
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

  /// 动画与资源加载并行；资源未就绪时继续停留启动页，避免首屏出现占位。
  Future<void> _runStartup() async {
    // 预热失败也要放行主界面，否则启动页会永久停留。
    final Future<void> warmUp = (widget.warmUp?.call() ?? Future<void>.value())
        .catchError((Object _) {});
    await Future.wait<void>(<Future<void>>[
      Future<void>.delayed(const Duration(milliseconds: 420)),
      warmUp,
    ]);
    if (mounted) {
      setState(() => _ready = true);
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
