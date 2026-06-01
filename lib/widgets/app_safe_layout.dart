import 'package:flutter/material.dart';

class AppSafeLayout extends StatelessWidget {
  const AppSafeLayout({
    super.key,
    required this.child,
    this.horizontal = 16,
    this.top = 12,
    this.bottom = 18,
    this.maxWidth,
    this.center = false,
  });

  final Widget child;
  final double horizontal;
  final double top;
  final double bottom;
  final double? maxWidth;
  final bool center;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        AppSafeSpacing.top(context, top),
        horizontal,
        AppSafeSpacing.bottom(context, bottom),
      ),
      child: child,
    );

    if (maxWidth != null) {
      content = Align(
        alignment: center ? Alignment.center : Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    return SafeArea(child: content);
  }
}

class AppSafeSpacing {
  AppSafeSpacing._();

  static double top(BuildContext context, [double base = 12]) {
    final double height = MediaQuery.sizeOf(context).height;
    return base + (height * 0.012).clamp(6.0, 12.0);
  }

  static double bottom(BuildContext context, [double base = 18]) {
    final double height = MediaQuery.sizeOf(context).height;
    return base + (height * 0.014).clamp(8.0, 14.0);
  }

  static EdgeInsets screenPadding(
    BuildContext context, {
    double horizontal = 16,
    double top = 12,
    double bottom = 18,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top + (MediaQuery.sizeOf(context).height * 0.012).clamp(6.0, 12.0),
      horizontal,
      bottom + (MediaQuery.sizeOf(context).height * 0.014).clamp(8.0, 14.0),
    );
  }

  static EdgeInsets listPadding(
    BuildContext context, {
    double horizontal = 16,
    double top = 16,
    double bottom = 18,
  }) {
    return screenPadding(
      context,
      horizontal: horizontal,
      top: top,
      bottom: bottom,
    );
  }
}
