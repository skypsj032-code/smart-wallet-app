import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomSheet,
    this.hideGlobalQuickPanel = false,
    this.hideAppBar = false,
    this.actions,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomSheet;
  final bool hideGlobalQuickPanel;
  final bool hideAppBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppScaffoldScope(
      hideGlobalQuickPanel: hideGlobalQuickPanel,
      child: Scaffold(
        appBar: hideAppBar
            ? null
            : AppBar(
                title: Text(title),
                actions: actions,
              ),
        floatingActionButton: floatingActionButton,
        bottomSheet: bottomSheet,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class AppScaffoldScope extends InheritedWidget {
  const AppScaffoldScope({
    super.key,
    required this.hideGlobalQuickPanel,
    required super.child,
  });

  final bool hideGlobalQuickPanel;

  static AppScaffoldScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScaffoldScope>();
  }

  @override
  bool updateShouldNotify(AppScaffoldScope oldWidget) {
    return hideGlobalQuickPanel != oldWidget.hideGlobalQuickPanel;
  }
}

