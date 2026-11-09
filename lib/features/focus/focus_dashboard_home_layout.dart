part of 'focus_dashboard.dart';

/// 首页的欢迎区与响应式容器；专注业务卡片继续由页面状态维护。
extension _FocusDashboardHomeLayout on _FocusDashboardState {
  /// 按当前时段给出问候语，建立学习工作台的每日开场感。
  String _homeGreeting() {
    final int hour = DateTime.now().hour;
    final String slot = hour < 6
        ? '早上好'
        : hour < 12
        ? '上午好'
        : hour < 14
        ? '中午好'
        : hour < 18
        ? '下午好'
        : '晚上好';
    return '$slot，继续学习';
  }

  /// 首页日期文案，只保留日期信息。
  String _homeTodayMeta() {
    final DateTime now = DateTime.now();
    return '${now.month} 月 ${now.day} 日';
  }

  /// 创建静态首页：品牌栏、问候、日期、订阅入口和底部两个主操作。
  Widget _buildHomeScreen(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color actionColor = theme.colorScheme.primary;
    final Color actionTextColor = theme.colorScheme.onPrimary;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalPadding =
            AdaptiveLayout.centeredHorizontalPadding(
              width: constraints.maxWidth,
              maxContentWidth: AdaptiveLayout.homeContentMaxWidth,
              compact: 24,
            );
        return Padding(
          key: const Key('focus-home-hero'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            12 + FloatingBottomBarInset.of(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      key: const Key('home-open-about'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.about),
                      child: Text(
                        'Focubili-UIX',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  _buildSubscriptionButton(),
                  IconButton(
                    key: const Key('home-profile-button'),
                    // 我的按钮函数切换到个人中心页面。
                    onPressed: widget.onOpenProfile,
                    tooltip: '我的',
                    style: IconButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: actionTextColor,
                      fixedSize: const Size.square(46),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    icon: _buildProfileIcon(actionTextColor),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _homeGreeting(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _homeTodayMeta(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // 订阅引导位于日期下方，首次使用提示不再占据标题区域。
              Align(
                alignment: Alignment.centerLeft,
                child: _buildSubscriptionIntroduction(),
              ),
              const Spacer(),
              _buildHomePrimaryActions(context),
              // 保留旧入口文字节点，实际入口由上方动作行承担。
              const SizedBox.shrink(child: Text('打开视频')),
            ],
          ),
        );
      },
    );
  }

  /// 创建首页动作行：进入独立专注页与开始搜索，保持唯一强调色。
  Widget _buildHomePrimaryActions(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool running = widget.controller.activeSession != null;
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.tonalIcon(
            key: const Key('home-start-focus'),
            // 首页不再内嵌专注计时，按钮和下拉手势都直接切换到专注一级页。
            onPressed: widget.onOpenFocus,
            icon: Icon(running ? Icons.adjust_rounded : Icons.timer_outlined),
            label: Text(running ? '查看专注' : '进入专注'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            key: const Key('home-start-search'),
            // 开始搜索按钮函数进入搜索页面，保持主题主色的唯一强调。
            onPressed: widget.onOpenVideo,
            icon: const Icon(Icons.search_rounded),
            label: const Text('开始搜索'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// 创建「今日专注目标」仪表盘：今日专注分钟、目标进度与进入计时动作。
  Widget _buildTodayGoalCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int todayMinutes = widget.controller.todayFocusedDuration().inMinutes;
    final double goalProgress =
        (todayMinutes / _FocusDashboardState._dailyGoalMinutes)
            .clamp(0, 1)
            .toDouble();
    final int percent = (goalProgress * 100).round();
    final bool running = widget.controller.activeSession != null;
    return Card(
      key: const Key('focus-daily-goal'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '今日专注目标',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$todayMinutes / ${_FocusDashboardState._dailyGoalMinutes} 分钟',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: goalProgress,
                      minHeight: 8,
                      backgroundColor: AppTheme.sunkenOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const Key('focus-goal-start'),
              // 目标卡在专注页顶部，按钮把计时卡滚动到可见位置。
              onPressed: () => _scrollToFocusSessionCard(context),
              icon: Icon(running ? Icons.adjust_rounded : Icons.timer_outlined),
              label: Text(running ? '查看专注计时' : '开始专注'),
            ),
          ],
        ),
      ),
    );
  }

  /// 「开始专注」一步直达专注任务卡；卡片被隐藏时退回到卡片区起点。
  void _scrollToFocusSessionCard(BuildContext context) {
    final BuildContext? cardContext = _focusSessionCardKey.currentContext;
    if (cardContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          cardContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  /// 创建首页账号入口的头像或主题色默认人物图标。
  Widget _buildProfileIcon(Color fallbackColor) {
    final String avatarUrl = widget.profileAvatarUrl?.trim() ?? '';
    if (avatarUrl.isEmpty) {
      return Icon(Icons.person_outline_rounded, color: fallbackColor);
    }
    return ClipOval(
      child: AppNetworkImage(
        imageUrl: avatarUrl,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        // 头像加载失败函数回退为人物图标，避免网络图片破坏按钮布局。
        errorWidget: (context, url, error) =>
            _buildProfileAvatarError(context, error, null),
      ),
    );
  }

  /// 创建头像请求失败时使用的主题色人物图标占位。
  Widget _buildProfileAvatarError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primary,
      child: Icon(
        Icons.person_outline_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  /// 创建专注一级页的卡片列表，按今日目标、计时和历史记录顺序排列。
  Widget _buildCardsSliver(
    BuildContext context,
    FocusSession? activeSession,
    FocusSession? finishedSession,
  ) {
    return SliverLayoutBuilder(
      // 卡片区按照实际横向约束居中，容器复用外层滚动控制器。
      builder: (BuildContext context, SliverConstraints constraints) {
        final double horizontalPadding =
            AdaptiveLayout.centeredHorizontalPadding(
              width: constraints.crossAxisExtent,
              maxContentWidth: AdaptiveLayout.homeContentMaxWidth,
            );
        return SliverPadding(
          key: const Key('focus-adaptive-cards'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              if (!widget.controller.isReady)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else ...<Widget>[
                // 专注一级页先展示今日目标进度，再进入实际计时。
                _buildTodayGoalCard(context),
                const SizedBox(height: 14),
                if (widget.continueLearningCard != null) ...<Widget>[
                  widget.continueLearningCard!,
                  const SizedBox(height: 14),
                ],
                if (finishedSession != null) ...<Widget>[
                  _buildFinishedCard(context, finishedSession),
                  const SizedBox(height: 14),
                ],
                // 同一编号在准备和计时状态之间切换，不因状态变化重置位置。
                KeyedSubtree(
                  key: _focusSessionCardKey,
                  child: activeSession != null
                      ? _buildActiveCard(context, activeSession)
                      : _buildReadyCard(context),
                ),
                const SizedBox(height: 14),
                _buildTodaySummary(context),
                const SizedBox(height: 14),
                _buildRecentHistory(context),
              ],
            ],
          ),
        );
      },
    );
  }
}
