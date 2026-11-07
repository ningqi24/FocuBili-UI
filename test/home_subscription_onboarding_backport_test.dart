import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focubili/features/focus/focus_dashboard.dart';
import 'package:focubili/features/focus/focus_timer_controller.dart';
import 'package:focubili/services/subscription_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mountHome(
    WidgetTester tester, {
    Size size = const Size(430, 900),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final focus = FocusTimerController(tickInterval: const Duration(days: 1));
    addTearDown(focus.dispose);
    await focus.initialize();
    final subscriptions = SubscriptionService(
      backgroundScheduler: (_, _) async {},
    );
    addTearDown(subscriptions.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: FocusDashboard(
            controller: focus,
            subscriptionService: subscriptions,
            onOpenVideo: () {},
            onOpenStatistics: () {},
            onOpenProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('订阅入口位于日期下方且不再显示标题文字', (tester) async {
    await mountHome(tester);

    // 首页只有静态内容，不再提供可滚动卡片区。
    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.text('焦点订阅'), findsNothing);
    expect(find.textContaining('下拉进入专注'), findsNothing);

    final Rect dateRect = tester.getRect(find.textContaining('月'));
    final Rect buttonRect = tester.getRect(
      find.byKey(const Key('new-focus-subscription')),
    );
    expect(buttonRect.top, greaterThan(dateRect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('接受首次订阅提示后入口消失且排版正常', (tester) async {
    await mountHome(tester);

    await tester.tap(find.byKey(const Key('new-focus-subscription')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('好，开启焦点订阅'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('好的'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-focus-subscription')), findsNothing);
    expect(find.byKey(const Key('home-start-focus')), findsOneWidget);
    expect(find.byKey(const Key('home-start-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏大字拒绝提示后首页仍不溢出', (tester) async {
    await mountHome(tester, size: const Size(360, 720), textScale: 2.5);

    await tester.tap(find.byKey(const Key('new-focus-subscription')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我不需要焦点订阅'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-focus-subscription')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
