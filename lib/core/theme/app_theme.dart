import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 集中保存应用主题，避免每个页面重复定义颜色和控件样式。
///
/// 视觉遵循“Quiet Focus 静谧专注”设计规范：中性阶固定，唯一强调色为静谧蓝，
/// 只有用户主动选择时才允许切换为其它低饱和强调色。
abstract final class AppTheme {
  static const Color _brandColor = Color(0xFF2B57C4);

  /// 国庆红的持久化色值，与设置页色块使用同一个常量。
  static const int nationalDayRedValue = 0xFFCE2D35;

  /// 国庆红的原始主题色，同时用于识别首页的节日装饰。
  static const Color nationalDayRed = Color(nationalDayRedValue);

  /// 中性阶令牌：纸面背景、卡片表面、下沉填充与发丝分隔线。
  static const Color _paperLight = Color(0xFFFAFAF8);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _sunkenLight = Color(0xFFF1F0EC);
  static const Color _ruleLight = Color(0xFFE4E3DE);
  static const Color _mutedLight = Color(0xFF6E6E78);
  static const Color _inkLight = Color(0xFF1A1A20);
  static const Color _backgroundDark = Color(0xFF121216);
  static const Color _surfaceDark = Color(0xFF1C1C22);
  static const Color _sunkenDark = Color(0xFF232329);
  static const Color _ruleDark = Color(0xFF2E2E36);
  static const Color _mutedDark = Color(0xFF9B9BA5);
  static const Color _inkDark = Color(0xFFEDEDF2);

  /// 低饱和语义色，只用于成功/警告/错误反馈，不参与装饰。
  static const Color successColor = Color(0xFF4F7A5F);
  static const Color warningColor = Color(0xFF8A6A33);
  static const Color errorColor = Color(0xFFA8443C);

  /// 根据页面明暗背景返回可读的 Android 状态栏与导航栏图标颜色。
  static SystemUiOverlayStyle systemOverlayStyle(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isLight
          ? Brightness.dark
          : Brightness.light,
    );
  }

  /// 创建跟随静谧蓝的浅色 Material 3 主题。
  static ThemeData light({Color seedColor = _brandColor}) {
    return _buildTheme(Brightness.light, seedColor);
  }

  /// 创建适合夜间观看的深色 Material 3 主题。
  static ThemeData dark({Color seedColor = _brandColor}) {
    return _buildTheme(Brightness.dark, seedColor);
  }

  /// Preserves a chosen accent's chroma while meeting text contrast on its surface.
  static Color _accessibleAccent(
    Color seed,
    Color surface,
    Brightness brightness,
  ) {
    final target = brightness == Brightness.dark ? Colors.white : Colors.black;
    final background = surface.computeLuminance();
    for (var step = 0; step <= 20; step++) {
      final candidate = Color.lerp(seed, target, step / 20)!;
      final luminance = candidate.computeLuminance();
      final contrast = luminance > background
          ? (luminance + 0.05) / (background + 0.05)
          : (background + 0.05) / (luminance + 0.05);
      if (contrast >= 4.5) return candidate;
    }
    return target;
  }

  /// 根据明暗模式生成固定的中性阶、圆角与组件样式。
  static ThemeData _buildTheme(Brightness brightness, Color seedColor) {
    final bool isLight = brightness == Brightness.light;
    final Color paper = isLight ? _paperLight : _backgroundDark;
    final Color surface = isLight ? _surfaceLight : _surfaceDark;
    final Color sunken = isLight ? _sunkenLight : _sunkenDark;
    final Color rule = isLight ? _ruleLight : _ruleDark;
    final Color muted = isLight ? _mutedLight : _mutedDark;
    final Color ink = isLight ? _inkLight : _inkDark;

    ColorScheme colors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: seedColor == _brandColor
          ? DynamicSchemeVariant.tonalSpot
          : DynamicSchemeVariant.fidelity,
    ).copyWith(
      // 中性阶不随强调色变化，保证界面色调统一简约。
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outlineVariant: rule,
      error: isLight ? errorColor : const Color(0xFFC9736B),
      onError: isLight ? Colors.white : const Color(0xFF2A1210),
    );
    if (seedColor == _brandColor) {
      // 静谧蓝的精确令牌：主色与容器色直接取自设计规范。
      colors = colors.copyWith(
        primary: isLight ? _brandColor : const Color(0xFF9DB4EE),
        onPrimary: isLight ? Colors.white : _inkLight,
        primaryContainer: isLight
            ? const Color(0xFFE6EBF8)
            : const Color(0xFF2B3A63),
        onPrimaryContainer: isLight
            ? const Color(0xFF16305F)
            : const Color(0xFFDCE4F8),
      );
    } else {
      final accent = _accessibleAccent(seedColor, colors.surface, brightness);
      colors = colors.copyWith(
        primary: accent,
        onPrimary: accent.computeLuminance() > 0.179
            ? Colors.black
            : Colors.white,
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      extensions: <ThemeExtension<dynamic>>[
        AppThemeAccent(seedColor: seedColor),
      ],
      scaffoldBackgroundColor: paper,
      dividerColor: rule,
      disabledColor: muted.withValues(alpha: 0.5),
      switchTheme: SwitchThemeData(
        // 开关滑块独立配色，任意强调色下都使用柔白圆圈而非黑色前景。
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.38);
          }
          return states.contains(WidgetState.selected)
              ? const Color(0xFFFFF8F2)
              : colors.onSurfaceVariant;
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: rule),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sunken,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 44),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: rule),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        backgroundColor: sunken,
        selectedColor: colors.primaryContainer,
        side: BorderSide(color: rule),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: systemOverlayStyle(brightness),
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: colors.primaryContainer,
        elevation: 0,
        // 药丸形选中指示器。
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.onPrimaryContainer);
          }
          return IconThemeData(color: colors.onSurfaceVariant);
        }),
      ),
    );
  }
}

/// 保留未经明暗模式调整的主题色，让背景装饰准确跟随用户选择。
class AppThemeAccent extends ThemeExtension<AppThemeAccent> {
  /// 保存本次主题的原始强调色。
  const AppThemeAccent({required this.seedColor});

  final Color seedColor;

  /// 判断用户是否选中了国庆红，避免深色主题调亮后的颜色影响识别。
  bool get isNationalDay => seedColor == AppTheme.nationalDayRed;

  /// 创建更新强调色的主题扩展副本。
  @override
  AppThemeAccent copyWith({Color? seedColor}) =>
      AppThemeAccent(seedColor: seedColor ?? this.seedColor);

  /// 在主题切换动画中平滑过渡原始强调色。
  @override
  AppThemeAccent lerp(covariant AppThemeAccent? other, double t) {
    if (other == null) {
      return this;
    }
    return AppThemeAccent(seedColor: Color.lerp(seedColor, other.seedColor, t)!);
  }
}
