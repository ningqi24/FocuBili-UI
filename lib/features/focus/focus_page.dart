import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/home_theme_background.dart';
import '../../models/focus_session.dart';
import 'focus_dashboard.dart';
import 'focus_timer_scope.dart';
import 'focus_video_launcher.dart';

/// 独立“专注”一级页面，与首页共用同一个应用级计时控制器。
class FocusPage extends StatelessWidget {
  /// 创建专注页，并接收主框架的一级页面切换回调。
  const FocusPage({
    super.key,
    required this.onOpenVideo,
    required this.onOpenStatistics,
    required this.onOpenSubscriptions,
    required this.onOpenLearningList,
  });

  /// 切换到搜索一级页。
  final VoidCallback onOpenVideo;

  /// 打开本机专注统计看板。
  final VoidCallback onOpenStatistics;

  /// 切换到“关注”一级页。
  final VoidCallback onOpenSubscriptions;

  /// 切换到“清单”一级页。
  final VoidCallback onOpenLearningList;

  @override
  Widget build(BuildContext context) {
    return HomeThemeBackground(
      child: FocusDashboard(
        key: const Key('focus-primary-page'),
        controller: FocusTimerScope.of(context),
        appBarTitle: '专注',
        onOpenVideo: onOpenVideo,
        onOpenStatistics: onOpenStatistics,
        onOpenSubscriptions: onOpenSubscriptions,
        onOpenLearningList: onOpenLearningList,
        onOpenLinkedVideo: (FocusSession session) =>
            unawaited(FocusVideoLauncher.open(context, session)),
      ),
    );
  }
}
