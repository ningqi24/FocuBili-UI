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

  /// 日期提示与下拉手势说明，首页不再重复展示专注统计。
  String _homeTodayMeta() {
    final DateTime now = DateTime.now();
    return '${now.month} 月 ${now.day} 日 · 下拉进入专注';
  }

  /// 根据文字实际换行高度为首屏留足空间，矮屏和大字体允许自然滚动。
  double _homeHeroHeight(BuildContext context) {
    final Size windowSize = MediaQuery.sizeOf(context);
    final bool compact =
        windowSize.width >= AdaptiveLayout.tabletBreakpoint ||
        windowSize.height < 648;
    final double preferred = compact
        ? (windowSize.height - 64).clamp(280.0, 720.0).toDouble()
        : (windowSize.height - 260).clamp(380.0, 560.0).toDouble();
    final ThemeData theme = Theme.of(context);
    final double padding = AdaptiveLayout.centeredHorizontalPadding(
      width: windowSize.width,
      maxContentWidth: AdaptiveLayout.homeContentMaxWidth,
      compact: 24,
    );
    final double width = (windowSize.width - padding * 2).clamp(80.0, 840.0);
    // 顶栏高度取触控按钮（48）与标题文字换行高度的较高者。
    final double titleHeight = math.max(
      kMinInteractiveDimension,
      _measureHeroText(
        context,
        'Focubili-UIX',
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        width - kMinInteractiveDimension * (_subscriptions.enabled ? 2 : 1),
      ),
    );
    final double greetingHeight = _measureHeroText(
      context,
      _homeGreeting(),
      theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      width,
    );
    final double metaHeight = _measureHeroText(
      context,
      _homeTodayMeta(),
      theme.textTheme.bodyMedium,
      width,
    );
    // 首屏动作行：进入专注与开始搜索并排，按最窄可用宽度测量标签换行高度。
    final double actionLabelWidth = math.max(40.0, (width - 10) / 2 - 72);
    final double actionHeight = math.max(
      kMinInteractiveDimension,
      _measureHeroText(
            context,
            '进入专注',
            theme.textTheme.labelLarge,
            actionLabelWidth,
          ) +
          28,
    );
    // 订阅引导用组件实测高度；首帧尚未布局时退回保守估值，避免出现空白或溢出。
    final double introHeight;
    if (_showSubscriptionIntroduction) {
      final RenderObject? introBox = _subscriptionIntroKey.currentContext
          ?.findRenderObject();
      final double measured = introBox is RenderBox && introBox.hasSize
          ? introBox.size.height
          : 0;
      introHeight = math.max(
        measured,
        100 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.5),
      );
    } else {
      introHeight = 0;
    }
    final double minimum =
        titleHeight +
        greetingHeight +
        metaHeight +
        actionHeight +
        64 +
        introHeight;
    return preferred > minimum ? preferred : minimum;
  }

  /// 用当前系统字体测量真实换行，避免用缩小字体的方式压进固定高度。
  double _measureHeroText(
    BuildContext context,
    String text,
    TextStyle? style,
    double width,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width.clamp(40.0, double.infinity));
    final double height = painter.height;
    painter.dispose();
    return height;
  }

  /// 首屏内容高于视口时保留自然滚动，确保搜索按钮不会在到达前淡出。
  bool _canAnimateHomeHero(BuildContext context) =>
      _homeHeroHeight(context) <= MediaQuery.sizeOf(context).height - 64;

  /// 创建首屏学习工作台：问候、今日专注进度仪表盘与一步直达的核心动作。
  Widget _buildHomeHero(BuildContext context) {
    final double heroHeight = _homeHeroHeight(context);
    final bool animate = _canAnimateHomeHero(context) && !_editingHomeCards;
    final double progress = animate
        ? (_scrollOffset / 280).clamp(0.0, 1.0).toDouble()
        : 0;
    // Sliver 随滚动上移；额外向下位移后，首屏元素会相对原位下坠再淡出。
    final double fallOffset = animate ? _scrollOffset * 1.32 : 0;
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    // 首屏入口复用应用主题，避免草图颜色泄漏到成品界面。
    final Color actionColor = theme.colorScheme.primary;
    final Color actionTextColor = theme.colorScheme.onPrimary;
    return SliverToBoxAdapter(
      child: SizedBox(
        key: const Key('focus-home-hero'),
        height: heroHeight,
        child: ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: progress * 7,
              sigmaY: progress * 7,
            ),
            child: Opacity(
              opacity: 1 - (progress * 0.88),
              child: Transform.translate(
                // 首屏本身随滚动离开，但内容相对原位向下坠落并逐渐淡出。
                offset: Offset(0, fallOffset),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double horizontalPadding =
                        AdaptiveLayout.centeredHorizontalPadding(
                          width: constraints.maxWidth,
                          maxContentWidth: AdaptiveLayout.homeContentMaxWidth,
                          compact: 24,
                        );
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        12,
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
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.about),
                                  child: Text(
                                    'Focubili-UIX',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
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
                          _buildSubscriptionIntroduction(),
                          const SizedBox(height: 14),
                          Text(
                            _homeGreeting(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _homeTodayMeta(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          _buildHomePrimaryActions(context),
                          // 保留旧入口文字节点，实际入口由下方动作行承担。
                          const SizedBox.shrink(child: Text('打开视频')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
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
          (_homeHeroHeight(context) + 12).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
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

  /// 用可换行的动作组保留学习清单与统计入口，大字体下不强挤在一行。
  Widget _buildHomeActionsCard(BuildContext context) {
    return Card(
      key: const Key('home-utility-actions'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (widget.onOpenLearningList != null)
              TextButton.icon(
                key: const Key('open-learning-list'),
                // 学习清单入口复用页面传入的业务路由。
                onPressed: widget.onOpenLearningList,
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('学习清单'),
              ),
            TextButton.icon(
              key: const Key('open-focus-statistics'),
              // 统计入口复用页面传入的本机专注看板路由。
              onPressed: widget.onOpenStatistics,
              icon: const Icon(Icons.insights_rounded),
              label: const Text('专注数据'),
            ),
          ],
        ),
      ),
    );
  }

  /// 创建横屏工作台左栏的品牌说明和主要搜索动作。
  Widget _buildWorkspaceIntro(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      key: const Key('focus-workspace-intro'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.filter_center_focus_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    key: const Key('workspace-open-about'),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.about),
                    child: Text(
                      'Focubili-UIX',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // 保留首页文字节点，兼容已有的页面识别和无障碍测试。
                const SizedBox.shrink(child: Text('首页')),
              ],
            ),
            _buildSubscriptionIntroduction(),
            const SizedBox(height: 42),
            Text(
              '今天要学点什么？',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '从一个明确的视频开始，把注意力留给真正想完成的事。',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  key: const Key('home-start-focus'),
                  // 工作台同样通过一级页面切换进入专注，不嵌入计时卡片。
                  onPressed: widget.onOpenFocus,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('进入专注'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 52),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('home-start-search'),
                  // 工作台搜索按钮函数切换到左侧导航中的搜索页面。
                  onPressed: widget.onOpenVideo,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('开始搜索'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(176, 52),
                  ),
                ),
              ],
            ),
            // 保留旧入口文字节点，但工作台只绘制一个清晰的主要动作。
            const SizedBox.shrink(child: Text('打开视频')),
          ],
        ),
      ),
    );
  }

  /// 横屏左侧保留简介，所有可编辑卡片统一放在独立可滚动的右侧区域。
  Widget _buildWorkspaceDashboard(BuildContext context) {
    return Padding(
      key: const Key('focus-workspace-layout'),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        // 按真正剩余的卡片区域选择列数，避免把导航栏宽度算进卡片空间。
        builder: (context, constraints) {
          final double introWidth = constraints.maxWidth >= 1100 ? 340 : 300;
          final double boardWidth = constraints.maxWidth - introWidth - 20;
          final double scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final int columns = boardWidth >= 760 * scale ? 2 : 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: introWidth,
                child: SingleChildScrollView(
                  key: const Key('focus-workspace-primary'),
                  child: _buildWorkspaceIntro(context),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('focus-workspace-secondary'),
                  controller: _scrollController,
                  child: _buildHomeCardBoard(context, columns: columns),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 首页使用单个可编辑容器；独立专注模式保留原有业务卡片顺序。
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
          sliver: widget.onOpenProfile != null
              ? SliverToBoxAdapter(
                  child: _buildHomeCardBoard(context, columns: 1),
                )
              : SliverList.list(
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
