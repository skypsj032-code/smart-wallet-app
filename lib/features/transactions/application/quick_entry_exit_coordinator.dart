import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef QuickEntryExitHandler = Future<bool> Function();

/// Lets shell navigation ask the active editor before replacing its draft.
class QuickEntryExitCoordinator {
  final Map<Object, QuickEntryExitHandler> _handlers = {};
  Object? _askingOwner;

  void attach(Object owner, QuickEntryExitHandler handler) {
    _handlers.remove(owner);
    _handlers[owner] = handler;
  }

  void detach(Object owner) {
    _handlers.remove(owner);
    // A lock redirect can dispose the editor while its dialog is open.
    // Do not let the abandoned dialog block a newly mounted editor.
    if (identical(_askingOwner, owner)) _askingOwner = null;
  }

  Future<bool> confirmExit() async {
    if (_askingOwner != null || _handlers.isEmpty) return false;
    final owner = _handlers.keys.last;
    final handler = _handlers[owner]!;
    _askingOwner = owner;
    try {
      return await handler();
    } finally {
      if (identical(_askingOwner, owner)) _askingOwner = null;
    }
  }
}

final quickEntryExitCoordinatorProvider =
    Provider<QuickEntryExitCoordinator>((ref) => QuickEntryExitCoordinator());
