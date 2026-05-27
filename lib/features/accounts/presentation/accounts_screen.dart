import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_ledger_axis_intro.dart';
import '../../../shared/widgets/app_ledger_axis_navigation.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section.dart';
import 'package:go_router/go_router.dart';
import '../application/accounts_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(accountBalancesProvider);

    return AppScaffold(
      title: '자산',
      body: balancesAsync.when(
        data: (balances) {
          final totalNetWorth = balances
              .where((balance) => balance.account.includeInNetWorth)
              .fold<int>(0, (sum, balance) => sum + balance.balance);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppLedgerAxisNavigation(
                currentAxis: LedgerAxis.accounts,
                onOpenCalendar: () => context.push('/calendar'),
                onOpenStatistics: () => context.push('/statistics'),
                onOpenAccounts: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              const AppLedgerAxisIntro(
                label: '자산',
                headline: '계좌 상태를 봐요',
                body: '순자산과 잔액을 바로 확인해요.',
              ),
              const SizedBox(height: AppSpacing.md),
              _NetWorthCard(
                totalNetWorth: totalNetWorth,
                accountCount: balances.length,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSection(
                title: '계좌',
                action: FilledButton.icon(
                  onPressed: () => _showAccountDialog(context, ref, null),
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
                child: balances.isEmpty
                    ? _EmptyStateCard(
                        onAddPressed: () => _showAccountDialog(context, ref, null),
                      )
                    : _AccountsCard(
                        balances: balances,
                        onEdit: (account) => _showAccountDialog(context, ref, account),
                        onDelete: (account) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('계좌 삭제'),
                              content: Text(
                                '\'${account.name}\' 계좌를 삭제할까요?\n연결된 거래 내역은 유지됩니다.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true || !context.mounted) {
                            return;
                          }

                          await ref
                              .read(accountsNotifierProvider.notifier)
                              .deleteAccount(account.localId);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('계좌 정보를 불러오지 못했습니다.\n$error'),
          ),
        ),
      ),
    );
  }

  void _showAccountDialog(BuildContext context, WidgetRef ref, Account? account) {
    final nameController = TextEditingController(text: account?.name ?? '');
    String selectedType = account?.type ?? 'cash';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(account == null ? '계좌 추가' : '계좌 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '계좌 이름',
                      hintText: '예: 생활비 통장, 주거래 카드',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: '종류'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('현금')),
                      DropdownMenuItem(value: 'bank', child: Text('은행 계좌')),
                      DropdownMenuItem(value: 'card', child: Text('카드')),
                      DropdownMenuItem(value: 'savings', child: Text('저축')),
                      DropdownMenuItem(value: 'investment', child: Text('투자')),
                      DropdownMenuItem(value: 'wallet', child: Text('전자지갑')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => selectedType = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    final notifier = ref.read(accountsNotifierProvider.notifier);

                    if (account == null) {
                      await notifier.createAccount(name: name, type: selectedType);
                    } else {
                      await notifier.updateAccount(
                        localId: account.localId,
                        name: name,
                        type: selectedType,
                      );
                    }
                  },
                  child: Text(account == null ? '추가' : '저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.totalNetWorth,
    required this.accountCount,
  });

  final int totalNetWorth;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const amountColor = AppColors.primary;
    final caption = accountCount == 0
        ? '계좌를 추가해 보세요.'
        : '$accountCount개 계좌가 연결돼 있어요.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '총 순자산',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatCurrency(totalNetWorth),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) => formatCurrency(amount);
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아직 등록한 계좌가 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '현금, 은행 계좌, 카드처럼 자주 쓰는 자산부터 추가해 보세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('계좌 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsCard extends StatelessWidget {
  const _AccountsCard({
    required this.balances,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AccountBalance> balances;
  final ValueChanged<Account> onEdit;
  final ValueChanged<Account> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < balances.length; index++) ...[
            _AccountListTile(
              balance: balances[index],
              onEdit: () => onEdit(balances[index].account),
              onDelete: () => onDelete(balances[index].account),
            ),
            if (index != balances.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _AccountListTile extends StatelessWidget {
  const _AccountListTile({
    required this.balance,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountBalance balance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const typeColor = AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: typeColor.withValues(alpha: 0.12),
        child: Icon(
          _typeIcon(balance.account.type),
          color: typeColor,
        ),
      ),
      title: Text(
        balance.account.name,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(_typeLabel(balance.account.type)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatCurrency(balance.balance),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Text('수정'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


IconData _typeIcon(String type) {
  switch (type) {
    case 'bank':
      return Icons.account_balance;
    case 'card':
      return Icons.credit_card;
    case 'savings':
      return Icons.savings;
    case 'investment':
      return Icons.trending_up;
    case 'wallet':
      return Icons.account_balance_wallet;
    default:
      return Icons.payments;
  }
}


String _typeLabel(String type) {
  switch (type) {
    case 'bank':
      return '은행 계좌';
    case 'card':
      return '카드';
    case 'savings':
      return '저축';
    case 'investment':
      return '투자';
    case 'wallet':
      return '전자지갑';
    default:
      return '현금';
  }
}
