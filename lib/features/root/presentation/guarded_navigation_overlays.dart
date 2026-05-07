import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/navigation_depth_policy.dart';

int navigationDepthForContext(
  BuildContext context, {
  int? currentDepthOverride,
}) {
  if (currentDepthOverride != null) {
    return currentDepthOverride;
  }

  String? location;
  try {
    location = GoRouterState.of(context).uri.toString();
  } catch (_) {
    location = null;
  }

  final baseDepth = location == null ? 2 : navigationDepthForPath(location);
  final route = ModalRoute.of(context);
  final overlayDepth = route is PopupRoute ? 1 : 0;
  final totalDepth = baseDepth + overlayDepth;
  return totalDepth.clamp(1, maxNavigationDepth);
}

Future<T?> showGuardedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  int? currentDepthOverride,
  bool barrierDismissible = true,
}) {
  final currentDepth = navigationDepthForContext(
    context,
    currentDepthOverride: currentDepthOverride,
  );
  if (!canOpenOverlayAtDepth(currentDepth: currentDepth)) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('더 깊게 들어갈 수 없습니다.')),
      );
    return Future.value(null);
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

Future<T?> showGuardedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  int? currentDepthOverride,
  bool isScrollControlled = false,
}) {
  final currentDepth = navigationDepthForContext(
    context,
    currentDepthOverride: currentDepthOverride,
  );
  if (!canOpenOverlayAtDepth(currentDepth: currentDepth)) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('더 깊게 들어갈 수 없습니다.')),
      );
    return Future.value(null);
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (sheetContext) => builder(sheetContext),
  );
}
