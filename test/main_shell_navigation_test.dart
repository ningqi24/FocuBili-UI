import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focubili/core/router/app_router.dart';
import 'package:focubili/features/focus/focus_timer_controller.dart';
import 'package:focubili/features/focus/focus_timer_scope.dart';
import 'package:focubili/features/shell/main_shell.dart';
import 'package:focubili/services/app_behavior_preferences_service.dart';

/// 在固定手机尺寸中创建主框架，并注入已经初始化的专注控制器。
Future<void> _pumpMainShell(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final FocusTimerController focusController = FocusTimerController(
    tickInterval: const Duration(days: 1),
  );
  addTearDown(focusController.dispose);
  await focusController.initialize();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: FocusTimerScope(
        controller: focusController,
        child: const MainShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 在固定平板横屏尺寸中创建主框架，验证工作台导航不会退化成手机切页。
Future<void> _pumpLandscapeMainShell(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1067, 600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final FocusTimerController focusController = FocusTimerController(
    tickInterval: const Duration(days: 1),
  );
  addTearDown(focusController.dispose);
  await focusController.initialize();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: FocusTimerScope(
        controller: focusController,
        child: const MainShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 注册主框架的系统返回和隐藏输入焦点回归测试。
void main() {
  /// 每项测试清空本机偏好，避免学习清单或搜索历史影响页面状态。
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // 主框架账号读取使用空内存容器，不依赖系统凭据插件。
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  /// 验证搜索页和“我的”页先返回首页，只有首页把返回继续交给系统。
  testWidgets('一级子页系统返回首页且首页允许退出', (WidgetTester tester) async {
    await _pumpMainShell(tester);

    await tester.tap(find.byKey(const Key('home-start-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-back-button')), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-start-search')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-profile-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-back-button')), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-start-search')), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isFalse);
  });

  /// 验证离开搜索页会断开输入焦点，设置页返回后隐藏搜索框不会接收文字。
  testWidgets('设置页返回不会恢复隐藏搜索框焦点', (WidgetTester tester) async {
    await _pumpMainShell(tester);

    await tester.tap(find.byKey(const Key('home-start-search')));
    await tester.pumpAndSettle();
    final Finder visibleSearchInput = find.byKey(
      const Key('search-input-field'),
    );
    await tester.tap(visibleSearchInput);
    await tester.enterText(visibleSearchInput, '原有搜索');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const Key('search-back-button')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(const Key('home-profile-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('个性化设置'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    final TextField hiddenSearchInput = tester.widget<TextField>(
      find.byKey(const Key('search-input-field'), skipOffstage: false),
    );
    expect(hiddenSearchInput.focusNode?.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(const Key('profile-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-start-search')));
    await tester.pumpAndSettle();
    final TextField restoredSearchInput = tester.widget<TextField>(
      find.byKey(const Key('search-input-field')),
    );
    expect(restoredSearchInput.controller?.text, '原有搜索');
  });

  /// 验证开启液态玻璃后底栏换成玻璃胶囊，五格都在页面内切换且底栏常驻。
  testWidgets('液态玻璃底栏保留五格跳转', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppBehaviorPreferencesService.liquidGlassBottomBarKey: true,
    });
    await _pumpMainShell(tester);

    final Finder bar = find.byKey(const Key('liquid-glass-bottom-bar'));
    expect(bar, findsOneWidget);
    expect(find.byKey(const Key('bottom-bar-focus')), findsNothing);

    await tester.tap(find.descendant(of: bar, matching: find.text('关注')).first);
    await tester.pumpAndSettle();
    // 关注是一级页面：底栏仍在，页面内容直接切换。
    expect(bar, findsOneWidget);
    expect(find.text('焦点订阅'), findsWidgets);

    await tester.tap(find.descendant(of: bar, matching: find.text('专注')).first);
    await tester.pumpAndSettle();
    // 专注是独立一级页面，首页的专注卡片不再出现。
    expect(bar, findsOneWidget);
    expect(find.byKey(const Key('focus-primary-page')), findsOneWidget);
    expect(find.byKey(const Key('focus-daily-goal')), findsOneWidget);
    expect(find.byKey(const Key('focus-ready-card')), findsOneWidget);
    expect(find.byKey(const Key('focus-home-hero')), findsNothing);

    await tester.tap(find.descendant(of: bar, matching: find.text('清单')).first);
    await tester.pumpAndSettle();
    expect(bar, findsOneWidget);
    expect(find.byKey(const Key('search-learning-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  /// 验证首页只保留静态内容，不再有下拉展开或专注计时卡片。
  testWidgets('首页保持静态且不含专注卡片', (WidgetTester tester) async {
    await _pumpMainShell(tester);

    expect(find.byKey(const Key('focus-home-hero')), findsOneWidget);
    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.byKey(const Key('focus-ready-card')), findsNothing);
    expect(find.byKey(const Key('focus-today-summary')), findsNothing);
    expect(find.byKey(const Key('focus-recent-history')), findsNothing);
    expect(find.byKey(const Key('home-start-focus')), findsOneWidget);
    expect(find.byKey(const Key('home-start-search')), findsOneWidget);
    expect(find.textContaining('下拉进入专注'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  /// 验证横屏平板通过左侧导航直接切换五个一级页面，子页不再显示返回首页按钮。
  testWidgets('平板横屏使用左侧一级导航', (WidgetTester tester) async {
    await _pumpLandscapeMainShell(tester);

    final Finder rail = find.byKey(const Key('workspace-navigation-rail'));
    expect(rail, findsOneWidget);
    expect(find.byKey(const Key('focus-home-hero')), findsOneWidget);
    expect(find.byKey(const Key('home-start-focus')), findsOneWidget);
    expect(find.byKey(const Key('focus-ready-card')), findsNothing);

    await tester.tap(find.descendant(of: rail, matching: find.text('关注')));
    await tester.pumpAndSettle();
    expect(find.text('焦点订阅'), findsWidgets);

    await tester.tap(find.descendant(of: rail, matching: find.text('专注')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focus-primary-page')), findsOneWidget);
    expect(find.byKey(const Key('focus-ready-card')), findsOneWidget);

    await tester.tap(find.descendant(of: rail, matching: find.text('清单')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-learning-list')), findsOneWidget);

    await tester.tap(find.descendant(of: rail, matching: find.text('我的')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-workspace-layout')), findsOneWidget);
    expect(find.byKey(const Key('profile-back-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
