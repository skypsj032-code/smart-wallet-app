import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';

// ── 검색 필터 상태 ─────────────────────────────────────────────────────────────
class SearchFilter {
  const SearchFilter({
    this.keyword = '',
    this.type,
    this.categoryId,
    this.accountId,
  });

  final String keyword;
  final String? type;
  final String? categoryId;
  final String? accountId;

  SearchFilter copyWith({
    String? keyword,
    Object? type = _sentinel,
    Object? categoryId = _sentinel,
    Object? accountId = _sentinel,
  }) {
    return SearchFilter(
      keyword: keyword ?? this.keyword,
      type: identical(type, _sentinel) ? this.type : type as String?,
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      accountId: identical(accountId, _sentinel)
          ? this.accountId
          : accountId as String?,
    );
  }
}

const _sentinel = Object();

final searchFilterProvider =
    StateProvider<SearchFilter>((ref) => const SearchFilter());

// ── 검색 결과 (in-memory filter) ──────────────────────────────────────────────
final _allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.transactions)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
      .watch();
});

final searchResultsProvider = Provider.autoDispose<List<Transaction>>((ref) {
  final all = ref.watch(_allTransactionsProvider).asData?.value ?? [];
  final filter = ref.watch(searchFilterProvider);

  return all.where((tx) {
    if (filter.type != null && tx.type != filter.type) return false;

    if (filter.keyword.isNotEmpty) {
      final kw = filter.keyword.toLowerCase();
      final memo = (tx.memo ?? '').toLowerCase();
      final merchant = (tx.merchantName ?? '').toLowerCase();
      if (!memo.contains(kw) && !merchant.contains(kw)) return false;
    }

    if (filter.categoryId != null && tx.categoryId != filter.categoryId) {
      return false;
    }

    if (filter.accountId != null) {
      final match = tx.accountId == filter.accountId ||
          tx.fromAccountId == filter.accountId ||
          tx.toAccountId == filter.accountId;
      if (!match) return false;
    }
    return true;
  }).toList();
});

// ── 검색 화면 ──────────────────────────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keywordController.text = ref.read(searchFilterProvider).keyword;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final results = ref.watch(searchResultsProvider);
    final isLoadingAll = ref.watch(_allTransactionsProvider).isLoading;
    final theme = Theme.of(context);
    final hasActiveFilter = _hasActiveFilter(filter);

    return AppScaffold(
      title: '거래 검색',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '거래 찾기',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '메모나 상호명으로 검색하고, 거래 유형으로 빠르게 좁혀보세요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _keywordController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '메모, 상호명, 기록한 내용을 입력하세요',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: filter.keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: '검색어 지우기',
                              onPressed: () {
                                _keywordController.clear();
                                ref
                                    .read(searchFilterProvider.notifier)
                                    .update((s) => s.copyWith(keyword: ''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF6F7F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) => ref
                        .read(searchFilterProvider.notifier)
                        .update((s) => s.copyWith(keyword: value.trim())),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _TypeChip(
                                label: '전체',
                                selected: filter.type == null,
                                onTap: () => ref
                                    .read(searchFilterProvider.notifier)
                                    .update((s) => s.copyWith(type: null)),
                              ),
                              _gap,
                              _TypeChip(
                                label: '지출',
                                selected: filter.type == 'expense',
                                onTap: () => ref
                                    .read(searchFilterProvider.notifier)
                                    .update((s) => s.copyWith(type: 'expense')),
                              ),
                              _gap,
                              _TypeChip(
                                label: '수입',
                                selected: filter.type == 'income',
                                onTap: () => ref
                                    .read(searchFilterProvider.notifier)
                                    .update((s) => s.copyWith(type: 'income')),
                              ),
                              _gap,
                              _TypeChip(
                                label: '이체',
                                selected: filter.type == 'transfer',
                                onTap: () => ref
                                    .read(searchFilterProvider.notifier)
                                    .update((s) => s.copyWith(type: 'transfer')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasActiveFilter) ...[
                        const SizedBox(width: AppSpacing.sm),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('초기화'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  isLoadingAll ? '검색 중...' : '결과 ${results.length}건',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!isLoadingAll)
                  Text(
                    _filterSummary(filter),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isLoadingAll
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? _EmptySearchState(hasActiveFilter: hasActiveFilter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final tx = results[index];
                          return _SearchResultTile(
                            transaction: tx,
                            typeLabel: _typeLabel(tx.type),
                            amountText: _amountText(tx),
                            amountColor: _amountColor(tx.type),
                            icon: _typeIcon(tx.type),
                            iconColor: _typeColor(tx.type),
                            iconBackgroundColor:
                                _typeColor(tx.type).withValues(alpha: 0.12),
                            dateText: _formatDate(tx.occurredAt),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    _keywordController.clear();
    ref.read(searchFilterProvider.notifier).state = const SearchFilter();
  }

  bool _hasActiveFilter(SearchFilter filter) {
    return filter.keyword.isNotEmpty ||
        filter.type != null ||
        filter.categoryId != null ||
        filter.accountId != null;
  }

  String _filterSummary(SearchFilter filter) {
    if (filter.type == null) return '전체 거래';
    return '${_typeLabel(filter.type!)}만 보기';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'expense':
        return '지출';
      case 'income':
        return '수입';
      case 'transfer':
        return '이체';
      default:
        return type;
    }
  }

  String _amountText(Transaction tx) {
    final prefix = switch (tx.type) {
      'expense' => '-',
      'income' => '+',
      _ => '',
    };
    return '$prefix${_fmt(tx.amount)}';
  }

  Color _amountColor(String type) {
    switch (type) {
      case 'expense':
        return AppColors.expense;
      case 'income':
        return AppColors.income;
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'expense':
        return AppColors.expense;
      case 'income':
        return AppColors.income;
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'income':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  String _fmt(int amount) {
    final value = amount.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;
      buffer.write(value[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer}원';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  static const _gap = SizedBox(width: 8);
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      selectedColor: theme.colorScheme.primary,
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.transaction,
    required this.typeLabel,
    required this.amountText,
    required this.amountColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.dateText,
  });

  final Transaction transaction;
  final String typeLabel;
  final String amountText;
  final Color amountColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = transaction.memo?.trim().isNotEmpty == true
        ? transaction.memo!.trim()
        : transaction.merchantName?.trim().isNotEmpty == true
            ? transaction.merchantName!.trim()
            : typeLabel;

    final detail = transaction.memo?.trim().isNotEmpty == true &&
            transaction.merchantName?.trim().isNotEmpty == true
        ? transaction.merchantName!.trim()
        : typeLabel;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$detail · $dateText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              amountText,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.hasActiveFilter});

  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasActiveFilter ? '조건에 맞는 거래가 없습니다.' : '아직 검색 결과가 없습니다.',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasActiveFilter
                  ? '검색어를 바꾸거나 거래 유형 필터를 해제해 보세요.'
                  : '메모나 상호명을 입력하면 거래를 바로 찾을 수 있습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
