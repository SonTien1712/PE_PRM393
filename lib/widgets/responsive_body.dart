import 'package:flutter/material.dart';

class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}
