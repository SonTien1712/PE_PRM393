import 'package:flutter/material.dart';

import '../core/app_spacing.dart';
import '../core/app_theme.dart';

/// Static placeholders also work with reduced motion and an indeterminate load.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang tải tổng quan',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.balance),
              side: const BorderSide(color: AppTheme.line),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Placeholder(fraction: .3, height: 16),
                  SizedBox(height: AppSpacing.md),
                  _Placeholder(fraction: .7, height: 36),
                  SizedBox(height: AppSpacing.md),
                  _Placeholder(fraction: .8, height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _Placeholder(fraction: .7, height: 14),
                          SizedBox(height: AppSpacing.md),
                          _Placeholder(fraction: 1, height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.line,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadii.control),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Placeholder(fraction: .65, height: 14),
                            SizedBox(height: AppSpacing.sm),
                            _Placeholder(fraction: .85, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.fraction, required this.height});
  final double fraction;
  final double height;
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: fraction,
    alignment: Alignment.centerLeft,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.line,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
    ),
  );
}
