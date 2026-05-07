import 'package:flutter/material.dart';

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      key: const Key('keyboard-aware-body-padding'),
      duration: duration,
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: child,
    );
  }
}
