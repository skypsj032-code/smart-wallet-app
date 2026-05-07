import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/root/application/navigation_depth_policy.dart';

void main() {
  test('root routes are level 1', () {
    expect(navigationDepthForPath('/'), 1);
    expect(navigationDepthForPath('/timeline'), 1);
    expect(navigationDepthForPath('/tools'), 1);
    expect(navigationDepthForPath('/settings'), 1);
  });

  test('detail routes are level 2', () {
    expect(navigationDepthForPath('/calendar'), 2);
    expect(navigationDepthForPath('/statistics'), 2);
    expect(navigationDepthForPath('/recurring-expenses'), 2);
  });

  test('level 4 is rejected', () {
    expect(canEnterAdditionalLevel(currentDepth: 3), isFalse);
    expect(canEnterAdditionalLevel(currentDepth: 2), isTrue);
  });

  test('overlay depth is capped at level 3', () {
    expect(canOpenOverlayAtDepth(currentDepth: 2), isTrue);
    expect(canOpenOverlayAtDepth(currentDepth: 3), isFalse);
  });
}
