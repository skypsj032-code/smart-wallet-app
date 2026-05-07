const maxNavigationDepth = 3;

int navigationDepthForPath(String location) {
  if (_isRootLocation(location)) {
    return 1;
  }

  if (_isDetailLocation(location)) {
    return 2;
  }

  return 2;
}

bool canEnterAdditionalLevel({required int currentDepth}) {
  return currentDepth < maxNavigationDepth;
}

bool canOpenOverlayAtDepth({required int currentDepth}) {
  return currentDepth < maxNavigationDepth;
}

bool _isRootLocation(String location) {
  return location == '/' ||
      location.startsWith('/?') ||
      location.startsWith('/timeline') ||
      location.startsWith('/tools') ||
      location.startsWith('/settings');
}

bool _isDetailLocation(String location) {
  return location.startsWith('/calendar') ||
      location.startsWith('/statistics') ||
      location.startsWith('/search') ||
      location.startsWith('/accounts') ||
      location.startsWith('/budgets') ||
      location.startsWith('/ocr') ||
      location.startsWith('/recurring-expenses') ||
      location.startsWith('/quick-entry');
}
