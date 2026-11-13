import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef QuickEntryExitHandler = Future<bool> Function();

/// Lets shell navigation ask the active editor before replacing its draft.
class QuickEntryExitCoordinator {
  final Map<Object, QuickEntryExitHandler> _handlers = {};
  bool _asking = false;

  void attach(Object owner, QuickEntryExitHandler handler) {
    _handlers.remove(owner);
    _handlers[owner] = handler;
  }

  void detach(Object owner) => _handlers.remove(owner);

  Future<bool> confirmExit() async {
    if (_asking || _handlers.isEmpty) return false;
    _asking = true;
    try {
      return await _handlers.values.last();
    } finally {
      _asking = false;
    }
  }
}

final quickEntryExitCoordinatorProvider =
    Provider<QuickEntryExitCoordinator>((ref) => QuickEntryExitCoordinator());
