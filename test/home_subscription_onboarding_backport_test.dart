import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focubili/core/widgets/editable_card_board.dart';
import 'package:focubili/features/focus/focus_dashboard.dart';
import 'package:focubili/features/focus/focus_timer_controller.dart';
import 'package:focubili/services/subscription_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ScrollController> mountHome(
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
    return tester
        .widget<CustomScrollView>(find.byType(CustomScrollView).first)
        .controller!;
  }

  /// 首页取消吸附后拖动停在自然位置，松手不再自动跳到卡片区。
  Future<void> dragAndExpectNaturalScroll(
    WidgetTester tester,
    ScrollController scroll,
  ) async {
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(8, 400));
    await gesture.moveBy(const Offset(0, -160));
    await tester.pump(const Duration(milliseconds: 500));
    final double draggedOffset = scroll.offset;
    expect(draggedOffset, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(draggedOffset, 2));
  }

  for (final editing in [false, true]) {
    testWidgets('1.8 接受首次订阅提示后恢复自然滚动，原编辑状态 $editing', (tester) async {
      final scroll = await mountHome(tester);
      final originalKey = tester
          .widget<EditableCardBoard>(find.byType(EditableCardBoard))
          .key;
      if (editing) {
        await tester.ensureVisible(find.text('自定义').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('自定义').last);
        await tester.pumpAndSettle();
        expect(find.text('完成'), findsOneWidget);
        scroll.jumpTo(0);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('new-focus-subscription')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('好，开启焦点订阅'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('好的'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableCardBoard>(find.byType(EditableCardBoard)).key,
        isNot(originalKey),
      );
      expect(find.text('自定义').last, findsOneWidget);
      expect(find.byKey(const Key('new-focus-subscription')), findsNothing);
      await dragAndExpectNaturalScroll(tester, scroll);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('1.8 窄屏大字拒绝提示恢复高度，首页保持自然滚动', (tester) async {
    final scroll = await mountHome(
      tester,
      size: const Size(360, 720),
      textScale: 2.5,
    );
    final hero = find.byKey(const Key('focus-home-hero'));
    final visibleHeight = tester.getSize(hero).height;
    await tester.ensureVisible(find.byKey(const Key('new-focus-subscription')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-focus-subscription')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我不需要焦点订阅'));
    await tester.pumpAndSettle();
    expect(tester.getSize(hero).height, lessThan(visibleHeight));
    expect(find.byKey(const Key('new-focus-subscription')), findsNothing);
    await dragAndExpectNaturalScroll(tester, scroll);
    expect(tester.takeException(), isNull);
  });
}
