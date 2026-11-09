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

  testWidgets('启动页全屏铺满启动图', (WidgetTester tester) async {
    await pumpSplash(tester, Brightness.light);

    final Finder image = find.byKey(const Key('splash-image'));
    expect(image, findsOneWidget);
    final Image widget = tester.widget<Image>(image);
    expect(widget.fit, BoxFit.cover);
    expect((widget.image as AssetImage).assetName, SplashScreen.imageAsset);
    // 启动页不提供广告位、加载指示或额外文案。
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('深色模式启动页同样铺满启动图', (WidgetTester tester) async {
    await pumpSplash(tester, Brightness.dark);

    expect(find.byKey(const Key('splash-image')), findsOneWidget);
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

  testWidgets('启动门控至少展示最短时长后再进入主界面', (WidgetTester tester) async {
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

    // 预热很快完成，但最短展示未结束前仍停留在启动页。
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('主界面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('资源加载完成前保持启动页', (WidgetTester tester) async {
    final Completer<void> pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          warmUp: () => pending.future,
          child: const Scaffold(body: Text('主界面')),
        ),
      ),
    );

    // 最短展示早已结束，但资源仍未就绪，主界面不得提前出现。
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('主界面'), findsNothing);

    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('主界面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('资源加载超时后仍进入主界面', (WidgetTester tester) async {
    final Completer<void> pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          warmUp: () => pending.future,
          child: const Scaffold(body: Text('主界面')),
        ),
      ),
    );

    expect(find.text('主界面'), findsNothing);

    // 预热一直不返回时，超时兜底应放行主界面而不是永久停留。
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('主界面'), findsOneWidget);
    expect(tester.takeException(), isNull);
    pending.complete();
  });

  testWidgets('资源加载失败时不会永久停留在启动页', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(
          warmUp: () async => throw StateError('资源损坏'),
          child: const Scaffold(body: Text('主界面')),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));
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
