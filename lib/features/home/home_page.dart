import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/home_theme_background.dart';
import '../../models/focus_session.dart';
import '../../services/bilibili_auth_service.dart';
import '../../services/dashboard_layout_service.dart';
import '../focus/focus_dashboard.dart';
import '../focus/focus_timer_scope.dart';
import '../focus/focus_video_launcher.dart';

/// 专注导向的首页，只保留品牌、问候和两个主入口。
class HomePage extends StatefulWidget {
  /// 创建首页，并接收搜索、个人中心入口和可替换的本机服务。
  const HomePage({
    super.key,
    required this.onSearchRequested,
    this.onProfileRequested,
    this.onFocusRequested,
    this.onOpenSubscriptions,
    this.authService,
    this.layoutService,
    this.refreshGeneration = 0,
  });

  final VoidCallback onSearchRequested;
  final VoidCallback? onProfileRequested;

  /// 切入独立专注一级页的回调；由主框架提供，保证底栏常驻。
  final VoidCallback? onFocusRequested;

  /// 切入“关注”一级页的回调；为空时焦点订阅入口退回自己的路由跳转。
  final VoidCallback? onOpenSubscriptions;

  final BilibiliAuthService? authService;
  final int refreshGeneration;

  /// 首页订阅引导使用的布局存储。
  final DashboardLayoutService? layoutService;

  /// 创建首页状态，用于读取账号头像。
  @override
  State<HomePage> createState() => _HomePageState();
}

/// 管理首页账号头像读取和一级页面跳转。
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final BilibiliAuthService _authService;
  BilibiliSessionState _homeSession = const BilibiliSessionState.signedOut();
  int _accountReloadGeneration = 0;

  /// 初始化账号服务，并在首帧后读取已登录头像。
  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? BilibiliAuthService();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_reloadHomeSession());
  }

  /// 主框架每次重新选择首页都会递增刷新代次，首页据此重新读取账号头像。
  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshGeneration != widget.refreshGeneration) {
      unawaited(_reloadHomeSession());
    }
  }

  /// 应用从后台回到前台时重新读取账号状态。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reloadHomeSession());
    }
  }

  /// 读取首页右上角需要的已登录头像；网络错误时保留主题色默认图标。
  Future<void> _reloadHomeSession() async {
    final int generation = ++_accountReloadGeneration;
    final BilibiliSessionState session;
    try {
      session = await _authService.loadCurrentSession();
    } catch (_) {
      if (!mounted || generation != _accountReloadGeneration) {
        return;
      }
      setState(() => _homeSession = const BilibiliSessionState.networkError());
      return;
    }
    if (!mounted || generation != _accountReloadGeneration) {
      return;
    }
    setState(() => _homeSession = session);
  }

  /// 页面销毁时解除应用生命周期监听，避免旧首页继续响应前后台事件。
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 打开专注统计看板，查看趋势并统一管理本机记录。
  void _openFocusStatistics(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.focusStatistics);
  }

  /// 从首页 Pin 查询视频详情并恢复到关联分P和上次看到的位置。
  void _openLinkedVideo(BuildContext context, FocusSession session) {
    FocusVideoLauncher.open(context, session);
  }

  /// 为首页添加随主题变化的背景，并复用应用级计时控制器保持专注状态。
  @override
  Widget build(BuildContext context) {
    return HomeThemeBackground(
      child: FocusDashboard(
        controller: FocusTimerScope.of(context),
        layoutService: widget.layoutService,
        onOpenVideo: widget.onSearchRequested,
        onOpenProfile: widget.onProfileRequested,
        profileAvatarUrl: _homeSession.isActive
            ? _homeSession.account?.avatarUrl
            : null,
        onOpenStatistics: () => _openFocusStatistics(context),
        onOpenLinkedVideo: (FocusSession session) =>
            _openLinkedVideo(context, session),
        onOpenFocus: widget.onFocusRequested,
        onOpenSubscriptions: widget.onOpenSubscriptions,
      ),
    );
  }
}
