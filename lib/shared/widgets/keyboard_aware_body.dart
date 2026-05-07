import 'package:flutter/material.dart';

/// Wraps [child] in animated bottom padding that tracks the software keyboard.
///
/// Place this inside a [Scaffold] body so that text fields scroll above
/// the keyboard rather than being covered by it.
class KeyboardAwareBody extends StatelessWidget {
  const KeyboardAwareBody({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: duration,
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: insets),
      child: child,
    );
  }
}
