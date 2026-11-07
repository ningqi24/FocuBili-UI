import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 静默启动页：单色焦点标记 + 一行 Slogan，约 420ms 后交给主界面。
class SplashScreen extends StatefulWidget {
  /// 创建启动页；动画只播放一次，不循环。
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// 驱动 Slogan 在 Logo 之后淡入，并把系统栏图标交给应用主题统一管理。
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 与 Lottie 动画总时长保持一致，避免两段动效脱节。
  static const Duration _duration = Duration(milliseconds: 420);

  /// 轻色纸面背景，与 Flutter 首页保持同一中性阶。
  static const Color _backgroundLight = Color(0xFFFAFAF8);

  /// 深色背景，与应用主界面的深色底一致。
  static const Color _backgroundDark = Color(0xFF121216);

  /// 深色模式下的品牌提亮色，保证暗底上的可读对比。
  static const Color _brandDark = Color(0xFF8CA6EE);

  late final AnimationController _controller;
  late final Animation<double> _sloganOpacity;

  /// 启动动画立即播放，Slogan 在 Logo 完成大部分上浮后再出现。
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
    _sloganOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.81, curve: Curves.easeOut),
    );
  }

  /// 释放动画控制器，避免页面提前切换后继续占用帧回调。
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Size window = MediaQuery.sizeOf(context);
    final bool wide = window.width >= 900;
    final bool short = window.height < 640;
    final double logoSize = wide ? 112 : (short ? 72 : 96);
    final double offsetY = wide ? -32 : (short ? -12 : -24);
    final double sloganSize = wide ? 14 : (short ? 12 : 13);
    final Color brand = isDark ? _brandDark : const Color(0xFF2B57C4);
    return Scaffold(
      backgroundColor: isDark ? _backgroundDark : _backgroundLight,
      body: SafeArea(
        child: Center(
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // ColorFiltered 把单色 Lottie 标记染成当前模式的品牌色。
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(brand, BlendMode.srcIn),
                    child: SizedBox.square(
                      dimension: logoSize,
                      child: Lottie.asset(
                        'assets/splash/focubili_splash.json',
                        key: const Key('splash-logo'),
                        repeat: false,
                        fit: BoxFit.contain,
                        // 资源损坏时保留纯色标记，启动流程不被动画阻塞。
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.adjust_rounded,
                          size: logoSize,
                          color: brand,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: short ? 12 : (wide ? 20 : 16)),
                  FadeTransition(
                    opacity: _sloganOpacity,
                    child: Text(
                      '安静地，专注一件事',
                      key: const Key('splash-slogan'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sloganSize,
                        height: 1.4,
                        letterSpacing: 0.4,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 启动门控：启动页至少展示动画时长，异步预热最多等待 600ms 后进入主界面。
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

  /// 与启动动画并行的异步初始化；超时后不再阻塞主界面。
  final Future<void> Function()? warmUp;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

/// 协调动画时长与预热完成时间，并用 150ms 交叉淡出到主界面。
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

  /// 动画与预热并行；预热超时也继续进入主界面，剩余任务在后台完成。
  Future<void> _runStartup() async {
    final Future<void> warmUp = widget.warmUp?.call() ?? Future<void>.value();
    await Future.wait<void>(<Future<void>>[
      Future<void>.delayed(const Duration(milliseconds: 420)),
      warmUp.timeout(const Duration(milliseconds: 600), onTimeout: () {}),
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
