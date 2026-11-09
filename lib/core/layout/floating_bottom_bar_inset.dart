import 'package:flutter/widgets.dart';

/// 为悬浮底栏提供额外的底部留白。
///
/// 液态玻璃底栏悬浮在页面内容之上时，页面本身仍然铺满整屏，玻璃才能折射
/// 真实的内容；可滚动区域再通过本作用域预留出底栏高度，避免最后一项被遮挡。
/// 未使用玻璃底栏时作用域不存在，读取结果为 0，页面保持原有内边距。
class FloatingBottomBarInset extends InheritedWidget {
  /// 创建底栏留白作用域。
  const FloatingBottomBarInset({
    super.key,
    required this.value,
    required super.child,
  });

  /// 页面内容需要额外让出的底部高度（已包含系统底部安全区）。
  final double value;

  /// 返回当前页面需要预留的底部高度；不在悬浮底栏内时为 0。
  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<FloatingBottomBarInset>()
            ?.value ??
        0;
  }

  @override
  bool updateShouldNotify(FloatingBottomBarInset oldWidget) {
    return oldWidget.value != value;
  }
}
