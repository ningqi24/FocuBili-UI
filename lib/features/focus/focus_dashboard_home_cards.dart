part of 'focus_dashboard.dart';

/// 统一登记首页下方卡片；专注计时与统计已迁到独立专注页。
extension _FocusDashboardHomeCards on _FocusDashboardState {
  /// 始终登记全部编号，暂时不可用的卡片只暂停显示而不删除用户顺序。
  List<DashboardCardDefinition> _homeCardDefinitions() {
    return <DashboardCardDefinition>[
      DashboardCardDefinition(
        id: 'home.continue_learning',
        title: '继续学习',
        icon: Icons.play_circle_outline_rounded,
        available: widget.continueLearningCard != null,
        // 继续学习构建函数复用外层服务维护的加载、空状态和任务卡片。
        builder: (_) => widget.continueLearningCard ?? const SizedBox.shrink(),
      ),
      DashboardCardDefinition(
        id: 'home.quick_actions',
        title: '快捷入口',
        icon: Icons.apps_rounded,
        builder: _buildHomeActionsCard,
      ),
      DashboardCardDefinition(
        id: 'home.focus_subscriptions',
        title: '焦点订阅',
        icon: Icons.rss_feed_rounded,
        available: _subscriptions.enabled,
        builder: (_) => SubscriptionHomeCard(
          service: _subscriptions,
          onOpenFeed: widget.onOpenSubscriptions,
        ),
      ),
    ];
  }

  /// 所有首页卡片共享一个容器、存储身份和状态，跨行排序不会分成两套配置。
  Widget _buildHomeCardBoard(BuildContext context, {required int columns}) {
    return EditableCardBoard(
      key: _homeBoardKey,
      storageId: 'home',
      items: _homeCardDefinitions(),
      service: _homeLayouts,
      scrollController: _scrollController,
      onEditingChanged: _handleHomeEditingChanged,
      columnCount: columns,
      spacing: 14,
    );
  }
}
