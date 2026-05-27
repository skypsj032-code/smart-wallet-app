import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/accounts/application/accounts_provider.dart';
import 'package:smart_wallet_app/features/accounts/presentation/accounts_screen.dart';

void main() {
  test('net worth semantics label includes total and account count', () {
    final label = accountNetWorthSemanticLabel(
      totalNetWorth: 1250000,
      accountCount: 2,
    );

    expect(
      label,
      'Net worth summary. Total net worth ₩1,250,000 across 2 accounts.',
    );
  });

  test('account item semantics label includes type and balance', () {
    final label = accountItemSemanticLabel(
      AccountBalance(
        account: Account(
          localId: 'bank_main',
          name: '주거래 통장',
          type: 'bank',
          includeInNetWorth: true,
          isActive: true,
          createdAt: DateTime(2026, 5, 1),
          lastModifiedAt: DateTime(2026, 5, 1),
        ),
        balance: 840000,
      ),
    );

    expect(
      label,
      'Account item. 주거래 통장. Type bank account. Balance ₩840,000.',
    );
  });

  testWidgets('accounts screen exposes net worth and account semantics',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(
              [
                AccountBalance(
                  account: Account(
                  localId: 'bank_main',
                  name: '주거래 통장',
                  type: 'bank',
                  includeInNetWorth: true,
                  isActive: true,
                  createdAt: DateTime(2026, 5, 1),
                  lastModifiedAt: DateTime(2026, 5, 1),
                ),
                  balance: 840000,
                ),
                AccountBalance(
                  account: Account(
                  localId: 'wallet_cash',
                  name: '생활비 현금',
                  type: 'cash',
                  includeInNetWorth: true,
                  isActive: true,
                  createdAt: DateTime(2026, 5, 1),
                  lastModifiedAt: DateTime(2026, 5, 1),
                ),
                  balance: 410000,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AccountsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Net worth summary. Total net worth ₩1,250,000 across 2 accounts.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Account item. 주거래 통장. Type bank account. Balance ₩840,000.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
