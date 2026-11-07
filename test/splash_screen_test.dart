import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focubili/features/splash/splash_screen.dart';

void main() {
  /// 用真实主题包裹启动页，验证亮色和深色都能完成首帧绘制。
  Future<void> pumpSplash(WidgetTester tester, Brightness brightness) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('启动页显示矢量标记与单行 Slogan', (WidgetTester tester) async {
    await pumpSplash(tester, Brightness.light);

    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(find.byKey(const Key('splash-slogan')), findsOneWidget);
    expect(find.text('安静地，专注一件事'), findsOneWidget);
    // 启动页不提供广告位、加载指示或额外文案。
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('深色模式启动页同样可渲染且不留白闪', (WidgetTester tester) async {
    await pumpSplash(tester, Brightness.dark);

    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('启动页在矮屏和大字体下不溢出', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('启动门控至少展示动画时长后再进入主界面', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashGate(
          warmUp: _fastWarmUp,
          child: Scaffold(body: Text('主界面')),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('主界面'), findsNothing);

    // 预热很快完成，但动画未结束前仍停留在启动页。
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('主界面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('预热超时不会阻塞主界面', (WidgetTester tester) async {
    final Completer<void> never = Completer<void>();
    addTearDown(() {
      if (!never.isCompleted) never.complete();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          warmUp: () => never.future,
          child: const Scaffold(body: Text('主界面')),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('主界面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关闭启动页时直接显示主界面', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashGate(enabled: false, child: Scaffold(body: Text('主界面'))),
      ),
    );

    expect(find.text('主界面'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}

/// 模拟很快完成的本地预热任务。
Future<void> _fastWarmUp() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}
