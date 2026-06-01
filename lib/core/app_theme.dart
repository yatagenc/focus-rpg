import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color parchment = Color(0xFFFFF2D4);
  static const Color agedGold = Color(0xFFF0C15A);
  static const Color goldEdge = Color(0xFF9A6A22);
  static const Color amberFace = Color(0xFF9B520B);
  static const Color amberFaceLight = Color(0xFFC67918);
  static const Color darkWood = Color(0xFF1A120B);
  static const Color panelWood = Color(0xFF2B2117);
  static const Color disabledWood = Color(0xFF3A342C);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colors =
        ColorScheme.fromSeed(
          seedColor: agedGold,
          brightness: brightness,
        ).copyWith(
          primary: agedGold,
          onPrimary: const Color(0xFF241305),
          primaryContainer: amberFace,
          onPrimaryContainer: parchment,
          secondary: amberFaceLight,
          onSecondary: parchment,
          surface: brightness == Brightness.dark
              ? const Color(0xFF120D08)
              : const Color(0xFFFFF7E8),
          surfaceContainerHighest: brightness == Brightness.dark
              ? const Color(0xFF352B20)
              : const Color(0xFFF0E0C4),
          outline: goldEdge,
          outlineVariant: const Color(0xFF6F4A18),
        );

    final ThemeData base = ThemeData(colorScheme: colors, useMaterial3: true);
    final TextStyle buttonText = const TextStyle(
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: brightness == Brightness.dark ? parchment : darkWood,
        elevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: brightness == Brightness.dark ? parchment : darkWood,
          fontWeight: FontWeight.w800,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _FocusRpgPageTransitionsBuilder(),
          TargetPlatform.iOS: _FocusRpgPageTransitionsBuilder(),
          TargetPlatform.macOS: _FocusRpgPageTransitionsBuilder(),
          TargetPlatform.windows: _FocusRpgPageTransitionsBuilder(),
          TargetPlatform.linux: _FocusRpgPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _FocusRpgPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(colors, buttonText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(colors, buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(colors, buttonText),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(colors, buttonText),
      ),
      iconButtonTheme: IconButtonThemeData(style: _iconButtonStyle(colors)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(buttonText),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.onSurfaceVariant.withValues(alpha: 0.55);
            }
            if (states.contains(WidgetState.selected)) {
              return parchment;
            }
            return agedGold;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return amberFace;
            }
            return const Color(0xCC1B1209);
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: goldEdge, width: 1.25),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF20170F)
            : const Color(0xFFFFE4B6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: _ornateInputBorder(colors.outlineVariant),
        enabledBorder: _ornateInputBorder(colors.outlineVariant),
        focusedBorder: _ornateInputBorder(agedGold, width: 2),
        disabledBorder: _ornateInputBorder(disabledWood),
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: brightness == Brightness.dark
              ? const Color(0xFF20170F)
              : const Color(0xFFFFE4B6),
          border: _ornateInputBorder(colors.outlineVariant),
          enabledBorder: _ornateInputBorder(colors.outlineVariant),
          focusedBorder: _ornateInputBorder(agedGold, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return amberFaceLight;
          }
          return colors.surfaceContainerHighest;
        }),
        checkColor: const WidgetStatePropertyAll(parchment),
        side: const BorderSide(color: goldEdge, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return agedGold;
          }
          return colors.outlineVariant;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return agedGold;
          }
          return colors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return amberFace;
          }
          return colors.surfaceContainerHighest;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(goldEdge),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: amberFaceLight,
        linearTrackColor: Color(0xFF261C13),
      ),
    );
  }

  static ButtonStyle _filledButtonStyle(
    ColorScheme colors,
    TextStyle textStyle,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(textStyle),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return parchment.withValues(alpha: 0.45);
        }
        return parchment;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledWood;
        }
        if (states.contains(WidgetState.pressed)) {
          return const Color(0xFF653307);
        }
        if (states.contains(WidgetState.hovered)) {
          return amberFaceLight;
        }
        return amberFace;
      }),
      overlayColor: WidgetStatePropertyAll(agedGold.withValues(alpha: 0.16)),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: Color(0xFF5B5144));
        }
        return const BorderSide(color: agedGold, width: 1.35);
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return 0;
        }
        if (states.contains(WidgetState.pressed)) {
          return 1;
        }
        return 5;
      }),
      shadowColor: const WidgetStatePropertyAll(Color(0xAA000000)),
    );
  }

  static ButtonStyle _outlinedButtonStyle(
    ColorScheme colors,
    TextStyle textStyle,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(textStyle),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurfaceVariant.withValues(alpha: 0.55);
        }
        return agedGold;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return const Color(0xFF2A1B0D);
        }
        return const Color(0xCC1B1209);
      }),
      overlayColor: WidgetStatePropertyAll(agedGold.withValues(alpha: 0.12)),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: Color(0xFF453B31));
        }
        if (states.contains(WidgetState.hovered)) {
          return const BorderSide(color: agedGold, width: 1.5);
        }
        return const BorderSide(color: goldEdge, width: 1.25);
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }

  static ButtonStyle _textButtonStyle(ColorScheme colors, TextStyle textStyle) {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(textStyle),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurfaceVariant.withValues(alpha: 0.55);
        }
        return agedGold;
      }),
      overlayColor: WidgetStatePropertyAll(agedGold.withValues(alpha: 0.12)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: const BorderSide(color: goldEdge),
        ),
      ),
    );
  }

  static ButtonStyle _iconButtonStyle(ColorScheme colors) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurfaceVariant.withValues(alpha: 0.5);
        }
        return agedGold;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledWood.withValues(alpha: 0.6);
        }
        return const Color(0xCC1B1209);
      }),
      side: const WidgetStatePropertyAll(BorderSide(color: goldEdge)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }

  static OutlineInputBorder _ornateInputBorder(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _FocusRpgPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FocusRpgPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) {
      return child;
    }

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final Animation<double> fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curvedAnimation);
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(curvedAnimation);
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      ),
    );
  }
}
