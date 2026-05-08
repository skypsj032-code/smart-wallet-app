import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/search/presentation/search_screen.dart';
import 'package:smart_wallet_app/features/settings/presentation/settings_screen.dart';
import 'package:smart_wallet_app/features/tools/presentation/tools_screen.dart';

void main() {
  test('search summary semantics label includes active filter and result count',
      () {
    final label = searchSummarySemanticLabel(
      const SearchFilter(keyword: 'coffee', type: 'expense'),
      3,
      isLoading: false,
    );

    expect(label, contains('Search results summary.'));
    expect(label, contains('keyword coffee'));
    expect(label, contains('type expense'));
    expect(label, contains('Results: 3.'));
  });

  test('settings action semantics label includes title and subtitle', () {
    final label = settingsActionSemanticLabel(
      title: 'JSON backup export',
      subtitle: 'Save the current wallet data to a backup file.',
    );

    expect(
      label,
      'Open JSON backup export. Save the current wallet data to a backup file.',
    );
  });

  test('app lock semantics label reflects the disabled state', () {
    final label = appLockSemanticLabel(
      enabled: false,
      sessionUnlocked: true,
    );

    expect(label, contains('App lock settings.'));
    expect(label, contains('Lock is off.'));
    expect(label, contains('configure a 4-digit PIN lock'));
  });

  test('search result semantics label includes transaction summary', () {
    final transaction = Transaction(
      localId: 'tx-1',
      type: 'expense',
      amount: 12800,
      occurredAt: DateTime(2026, 5, 8, 9, 30),
      createdAt: DateTime(2026, 5, 8, 9, 31),
      lastModifiedAt: DateTime(2026, 5, 8, 9, 31),
      merchantName: 'Star Coffee',
      memo: 'Latte',
    );

    final label = searchResultSemanticLabel(transaction);

    expect(label, contains('Search result item.'));
    expect(label, contains('expense'));
    expect(label, contains('12,800 won'));
    expect(label, contains('merchant Star Coffee'));
    expect(label, contains('memo Latte'));
  });

  test('tools action semantics label includes title and subtitle', () {
    final label = toolsActionSemanticLabel(
      title: 'Calendar',
      subtitle: 'Review spending flow by day, month, and year.',
    );

    expect(
      label,
      'Open Calendar. Review spending flow by day, month, and year.',
    );
  });

  test('restore action semantics label describes destructive restore flow', () {
    final label = restoreActionSemanticLabel();

    expect(label, contains('Restore from backup.'));
    expect(label, contains('replace the current wallet data'));
    expect(label, contains('safety backup'));
  });

  test('theme mode semantics label reflects the selected mode', () {
    final label = themeModeSemanticLabel('system');

    expect(label, contains('Theme mode settings.'));
    expect(label, contains('Current mode: system.'));
    expect(label, contains('follow the device setting'));
  });
}
