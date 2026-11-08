import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_behavior_preferences_service.dart';
import '../focus/focus_page.dart';
import '../home/home_page.dart';
import '../learning/learning_list_page.dart';
import '../profile/profile_page.dart';
import '../search/search_page.dart';
import '../subscriptions/subscription_updates_page.dart';

/// 应用主框架，负责首页、关注、专注、清单和“我的”五个底栏一级页面切换。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// 创建主框架的可变状态，用于保存当前一级页面位置。
  @override
  State<MainShell> createState() => _MainShellState();
}

/// 保存主框架页面状态，并负责不经过中间页的水平过渡动画。
class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _navigationController;
  late final AppBehaviorPreferencesService _behaviorPreferences;
  int _currentIndex = 0;
  int? _transitionFrom;
  int? _transitionTo;
  int _homeRefreshGeneration = 0;

  /// 是否使用 iOS 26 液态玻璃底栏；启动预热已读取偏好时直接沿用，避免首帧闪回经典五格底栏。
  bool _liquidGlassBottomBar =
      AppBehaviorPreferencesService.cachedLiquidGlassBottomBar ?? true;

  /// 页面栈顺序：首页、搜索、关注、专注、清单、我的；搜索从首页进入。
  static const int _searchPageIndex = 1;
  static const int _subscriptionsPageIndex = 2;
  static const int _focusPageIndex = 3;
  static const int _learningListPageIndex = 4;
  static const int _profilePageIndex = 5;
  static const int _pageCount = 6;

  /// 初始化一级页面过渡控制器，并在动画完成后提交目标页面索引。
  @override
  void initState() {
    super.initState();
    _navigationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addStatusListener(_handleNavigationStatus);
    _behaviorPreferences = AppBehaviorPreferencesService();
    AppBehaviorPreferencesService.changes.addListener(
      _handleBehaviorPreferencesChanged,
    );
    unawaited(_loadBottomBarStyle());
  }

  /// 读取底栏风格偏好；读取失败时继续使用当前样式，保证主框架始终可用。
  Future<void> _loadBottomBarStyle() async {
    final bool liquidGlass = await _behaviorPreferences
        .loadLiquidGlassBottomBar();
    if (!mounted || liquidGlass == _liquidGlassBottomBar) {
      return;
    }
    setState(() => _liquidGlassBottomBar = liquidGlass);
  }

  /// 设置页保存成功后广播偏好变化，主框架据此立即切换底栏样式。
  void _handleBehaviorPreferencesChanged() {
    unawaited(_loadBottomBarStyle());
  }

  /// 切换到指定一级页面；只让当前页和目标页参与直接滑入动画。
  void _selectPage(int index) {
    if (index < 0 ||
        index >= _pageCount ||
        index == _currentIndex ||
        _transitionTo != null) {
      return;
    }
    // 一级页面会常驻组件树；切走前必须解除当前输入焦点，避免隐藏搜索框继续接收键盘输入。
    FocusManager.instance.primaryFocus?.unfocus();
    if (AdaptiveLayout.usesWorkspace(MediaQuery.sizeOf(context))) {
      _navigationController.stop();
      setState(() {
        _currentIndex = index;
        _transitionFrom = null;
        _transitionTo = null;
        if (index == 0) {
          _homeRefreshGeneration += 1;
        }
      });
      return;
    }
    setState(() {
      _transitionFrom = _currentIndex;
      _transitionTo = index;
      if (index == 0) {
        _homeRefreshGeneration += 1;
      }
    });
    unawaited(_navigationController.forward(from: 0));
  }

  /// 动画完成后提交目标页面，让隐藏页面继续保留在同一层级中。
  void _handleNavigationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    final int? targetIndex = _transitionTo;
    if (targetIndex == null) {
      return;
    }
    setState(() {
      _currentIndex = targetIndex;
      _transitionFrom = null;
      _transitionTo = null;
    });
  }

  /// 从首页的搜索入口直接切换到搜索页面。
  void _openSearch() {
    _selectPage(_searchPageIndex);
  }

  /// 从“我的”页返回首页，并触发首页重新读取学习清单和账号头像。
  void _openHome() {
    _selectPage(0);
  }

  /// 从首页右上角的账号入口打开“我的”页。
  void _openProfile() {
    _selectPage(_profilePageIndex);
  }

  /// 底栏“关注”切换到焦点订阅更新页，底栏保持常驻。
  void _openSubscriptions() {
    _selectPage(_subscriptionsPageIndex);
  }

  /// 底栏“清单”切换到完整学习清单页，底栏保持常驻。
  void _openLearningList() {
    _selectPage(_learningListPageIndex);
  }

  /// 底栏中间按钮和首页下拉手势都切换到独立专注页。
  void _openFocus() {
    _selectPage(_focusPageIndex);
  }

  /// 打开本机专注统计看板；该页属于详情路由，退出后回到当前一级页面。
  void _openFocusStatistics() {
    Navigator.of(context).pushNamed(AppRoutes.focusStatistics);
  }

  /// 玻璃底栏的五格索引：搜索页属于首页入口，保持首页高亮。
  ///
  /// 页面过渡期间立即使用目标页，否则玻璃指示器会在松手后先回到原格，
  /// 等 360ms 过渡结束才追到松手位置。
  int get _bottomBarSelectedIndex => switch (_transitionTo ?? _currentIndex) {
    0 || _searchPageIndex => 0,
    _subscriptionsPageIndex => 1,
    _focusPageIndex => 2,
    _learningListPageIndex => 3,
    _ => 4,
  };

  /// 底栏点击分派；每一格都只是切换一级页面，不再压入独立路由。
  void _handleBottomBarDestination(int index) {
    switch (index) {
      case 0:
        _openHome();
      case 1:
        _openSubscriptions();
      case 2:
        _openFocus();
      case 3:
        _openLearningList();
      case 4:
        _openProfile();
    }
  }

  /// 处理 Android 系统返回：非首页一级页面先回首页，首页再交给系统退出。
  void _handleSystemBack(bool didPop, Object? result) {
    if (didPop || _transitionTo != null || _currentIndex == 0) {
      return;
    }
    _openHome();
  }

  /// 创建挂载到主框架的六个页面，搜索页作为首页的内部入口保留输入状态。
  List<Widget> _buildPages({required bool workspace}) {
    return <Widget>[
      HomePage(
        onSearchRequested: _openSearch,
        onProfileRequested: _openProfile,
        onFocusRequested: _openFocus,
        onOpenSubscriptions: _openSubscriptions,
        refreshGeneration: _homeRefreshGeneration,
      ),
      SearchPage(onBackRequested: workspace ? null : _openHome),
      const SubscriptionUpdatesPage(),
      FocusPage(
        onOpenVideo: _openSearch,
        onOpenStatistics: _openFocusStatistics,
        onOpenSubscriptions: _openSubscriptions,
        onOpenLearningList: _openLearningList,
      ),
      const LearningListPage(),
      ProfilePage(onBackRequested: workspace ? null : _openHome),
    ];
  }

  /// 左侧导航的五格对应页面栈顺序，搜索仍由首页入口进入。
  static const List<int> _railPageIndexes = <int>[
    0,
    _subscriptionsPageIndex,
    _focusPageIndex,
    _learningListPageIndex,
    _profilePageIndex,
  ];

  /// 创建横屏平板和桌面宽窗口使用的左侧一级导航。
  Widget _buildWorkspaceNavigation(Size windowSize) {
    final bool extended = AdaptiveLayout.usesExpandedWorkspace(windowSize);
    return NavigationRail(
      key: const Key('workspace-navigation-rail'),
      selectedIndex: math.max(0, _railPageIndexes.indexOf(_currentIndex)),
      extended: extended,
      minWidth: AdaptiveLayout.compactNavigationWidth,
      minExtendedWidth: AdaptiveLayout.expandedNavigationWidth,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/icon/focubili_icon.png',
            width: 42,
            height: 42,
          ),
        ),
      ),
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('首页'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.rss_feed),
          label: Text('关注'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer_rounded),
          label: Text('专注'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.checklist_rounded),
          label: Text('清单'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('我的'),
        ),
      ],
      // 左侧导航索引映射到页面栈索引，避免关注/专注等页面错位。
      onDestinationSelected: (int index) =>
          _selectPage(_railPageIndexes[index]),
    );
  }

  /// 创建仿 B 站手机底栏：五等分格，中间是凸起的专注按钮。
  Widget _buildBottomBar() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: AppTheme.ruleOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _buildBottomBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: '首页',
                  selected: _currentIndex <= _searchPageIndex,
                  onTap: _openHome,
                ),
              ),
              Expanded(
                child: _buildBottomBarItem(
                  icon: Icons.rss_feed,
                  activeIcon: Icons.rss_feed,
                  label: '关注',
                  selected: _currentIndex == _subscriptionsPageIndex,
                  onTap: _openSubscriptions,
                ),
              ),
              SizedBox(width: 72, child: Center(child: _buildFocusButton())),
              Expanded(
                child: _buildBottomBarItem(
                  icon: Icons.checklist_rounded,
                  activeIcon: Icons.checklist_rounded,
                  label: '清单',
                  selected: _currentIndex == _learningListPageIndex,
                  onTap: _openLearningList,
                ),
              ),
              Expanded(
                child: _buildBottomBarItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: '我的',
                  selected: _currentIndex == _profilePageIndex,
                  onTap: _openProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建底栏的图标加文字格；选中时使用唯一强调色，未选中保持中性灰。
  Widget _buildBottomBarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = selected ? colors.primary : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(selected ? activeIcon : icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 创建底栏中间凸起的专注按钮，向上偏移以越出底栏边界。
  Widget _buildFocusButton() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool selected = _currentIndex == _focusPageIndex;
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Material(
        color: colors.primary,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // 选中时用一圈内描边提示当前就在专注页，不新增颜色。
          side: selected
              ? BorderSide(color: colors.onPrimary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          key: const Key('bottom-bar-focus'),
          borderRadius: BorderRadius.circular(16),
          onTap: _openFocus,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.timer_rounded, size: 26, color: colors.onPrimary),
          ),
        ),
      ),
    );
  }

  /// 创建液态玻璃底栏；沿用静谧蓝强调色与中性灰图标，避免新增鲜艳色。
  Widget _buildLiquidGlassBar() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: GlassTabBar.bottom(
        key: const Key('liquid-glass-bottom-bar'),
        tabs: <GlassTab>[
          GlassTab(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: '首页',
            semanticLabel: '首页',
          ),
          GlassTab(
            icon: const Icon(Icons.rss_feed),
            label: '关注',
            semanticLabel: '关注',
          ),
          GlassTab(
            icon: const Icon(Icons.timer_outlined),
            activeIcon: const Icon(Icons.timer_rounded),
            label: '专注',
            semanticLabel: '专注',
          ),
          GlassTab(
            icon: const Icon(Icons.checklist_rounded),
            label: '清单',
            semanticLabel: '清单',
          ),
          GlassTab(
            icon: const Icon(Icons.person_outline_rounded),
            activeIcon: const Icon(Icons.person_rounded),
            label: '我的',
            semanticLabel: '我的',
          ),
        ],
        selectedIndex: _bottomBarSelectedIndex,
        onTabSelected: _handleBottomBarDestination,
        selectedIconColor: colors.primary,
        selectedLabelColor: colors.primary,
        unselectedIconColor: colors.onSurfaceVariant,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorColor: colors.primary.withValues(alpha: 0.16),
        horizontalPadding: 16,
        verticalPadding: 12,
        barHeight: 58,
        // 真实折射需要足够厚度；半径过大反而变成模糊圆盘，这里保持克制的玻璃感。
        settings: const LiquidGlassSettings(
          blur: 8,
          thickness: 22,
          saturation: 1.6,
          chromaticAberration: 0.02,
          lightIntensity: 0.55,
        ),
      ),
    );
  }

  /// 创建保持三个一级页面状态的页面堆栈，手机端可选择启用水平切换动画。
  Widget _buildPageStack({
    required List<Widget> pages,
    required double width,
    required bool animate,
  }) {
    if (!animate) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          for (int index = 0; index < pages.length; index++)
            Positioned.fill(
              child: Offstage(
                offstage: index != _currentIndex,
                child: ExcludeFocus(
                  excluding: index != _currentIndex,
                  child: TickerMode(
                    enabled: index == _currentIndex,
                    child: pages[index],
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _navigationController,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (int index = 0; index < pages.length; index++)
              _buildPageLayer(pages[index], index, width),
          ],
        );
      },
    );
  }

  /// 创建一个页面层；过渡期间目标页从相邻方向滑入，搜索页不会被绘制。
  Widget _buildPageLayer(Widget page, int index, double width) {
    final int? transitionFrom = _transitionFrom;
    final int? transitionTo = _transitionTo;
    final bool transitioning = transitionFrom != null && transitionTo != null;
    final bool isVisible = transitioning
        ? index == transitionFrom || index == transitionTo
        : index == _currentIndex;
    final double progress = Curves.easeOutCubic.transform(
      _navigationController.value,
    );
    final double direction = transitioning && transitionTo > transitionFrom
        ? 1
        : -1;
    final double translation = !transitioning
        ? 0
        : index == transitionTo
        ? (1 - progress) * direction * width
        : -progress * direction * width;
    return Positioned.fill(
      child: Offstage(
        offstage: !isVisible,
        child: ExcludeFocus(
          excluding: index != (_transitionTo ?? _currentIndex),
          child: TickerMode(
            enabled: isVisible,
            child: Transform.translate(
              offset: Offset(translation, 0),
              child: page,
            ),
          ),
        ),
      ),
    );
  }

  /// 创建直接页面过渡层；各页始终保留在树中，所以搜索输入和滚动状态不会丢失。
  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _currentIndex == 0 && _transitionTo == null,
      onPopInvokedWithResult: _handleSystemBack,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Size windowSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final bool workspace = AdaptiveLayout.usesWorkspace(windowSize);
              final List<Widget> pages = _buildPages(workspace: workspace);
              final Widget pageStack = ClipRect(
                child: _buildPageStack(
                  pages: pages,
                  width: constraints.maxWidth,
                  animate: !workspace,
                ),
              );
              if (workspace) {
                return Row(
                  children: <Widget>[
                    _buildWorkspaceNavigation(windowSize),
                    const VerticalDivider(width: 1),
                    Expanded(child: pageStack),
                  ],
                );
              }
              if (_liquidGlassBottomBar) {
                // 玻璃底栏悬浮在页面之上；页面整体上移一个底栏高度，避免底部按钮被遮挡。
                final double barInset =
                    58 + 12 * 2 + MediaQuery.paddingOf(context).bottom;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: barInset),
                        child: pageStack,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildLiquidGlassBar(),
                    ),
                  ],
                );
              }
              return Column(
                children: <Widget>[
                  Expanded(child: pageStack),
                  _buildBottomBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 释放页面动画控制器和偏好监听，避免主框架离开后继续持有动画资源。
  @override
  void dispose() {
    AppBehaviorPreferencesService.changes.removeListener(
      _handleBehaviorPreferencesChanged,
    );
    _navigationController
      ..removeStatusListener(_handleNavigationStatus)
      ..dispose();
    super.dispose();
  }
}
