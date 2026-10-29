import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/platform_utils.dart';

/// Constrains the entire Navigator, including dialogs, to a mobile viewport.
/// The subtree stays in the same position when resizing across the breakpoint.
class MobileAppFrame extends StatelessWidget {
  const MobileAppFrame({super.key, required this.child});

  final Widget child;
  static const viewportKey = ValueKey('mobile-app-viewport');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final framed =
          isDesktop &&
          constraints.maxWidth >= 600 &&
          constraints.maxHeight >= 440;
      final size = Size(
        framed ? 446 : constraints.maxWidth,
        framed
            ? math.min(916, constraints.maxHeight - 32)
            : constraints.maxHeight,
      );
      return ColoredBox(
        color: const Color(0xFFE6EEEA),
        child: Center(
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: const Color(0xFF173B37),
              borderRadius: BorderRadius.circular(framed ? 38 : 0),
              boxShadow: framed
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .13),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ]
                  : const [],
            ),
            padding: EdgeInsets.all(framed ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(framed ? 30 : 0),
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final media = MediaQuery.of(context);
                  return MediaQuery(
                    key: viewportKey,
                    data: media.copyWith(
                      size: viewport.biggest,
                      padding: framed ? EdgeInsets.zero : media.padding,
                      viewPadding: framed ? EdgeInsets.zero : media.viewPadding,
                    ),
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
