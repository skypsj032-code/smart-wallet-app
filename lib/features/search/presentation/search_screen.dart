import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_opacity.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';

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
      type: identical(type, _sentinel) ? this.type : type as String? ,
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
    if (filter.type != null && tx.type != filter.type) {
      return false;
    }

    if (filter.keyword.isNotEmpty) {
      final keyword = filter.keyword.toLowerCase();
      final memo = (tx.memo ?? '').toLowerCase();
      final merchant = (tx.merchantName ?? '').toLowerCase();
      if (!memo.contains(keyword) && !merchant.contains(keyword)) {
        return false;
      }
    }

    if (filter.categoryId != null && tx.categoryId != filter.categoryId) {
      return false;
    }

    if (filter.accountId != null) {
      final matches = tx.accountId == filter.accountId ||
          tx.fromAccountId == filter.accountId ||
          tx.toAccountId == filter.accountId;
      if (!matches) {
        return false;
      }
    }

  return true;
  }).toList();
});

String searchSummarySemanticLabel(
  SearchFilter filter,
  int resultsCount, {
  required bool isLoading,
}) {
  final details = <String>[];

  if (filter.keyword.isNotEmpty) {
    details.add('keyword ${filter.keyword}');
  }
  if (filter.type != null) {
    details.add('type ${filter.type}');
  }
  if (filter.categoryId != null) {
    details.add('category selected');
  }
  if (filter.accountId != null) {
    details.add('account selected');
  }

  final filterDescription =
      details.isEmpty ? 'all transactions' : details.join(', ');
  final resultDescription =
      isLoading ? 'Results are loading.' : 'Results: $resultsCount.';

  return 'Search results summary. Current filter: $filterDescription. $resultDescription';
}

String searchResultSemanticLabel(Transaction transaction) {
  final details = <String>[
    'Search result item.',
    'type ${transaction.type}.',
    '${_semanticCurrency(transaction.amount)} won.',
  ];

  final merchant = transaction.merchantName?.trim();
  if (merchant != null && merchant.isNotEmpty) {
    details.add('merchant $merchant.');
  }

  final memo = transaction.memo?.trim();
  if (memo != null && memo.isNotEmpty) {
    details.add('memo $memo.');
  }

  details.add(
    'Occurred on ${transaction.occurredAt.year}-${transaction.occurredAt.month.toString().padLeft(2, '0')}-${transaction.occurredAt.day.toString().padLeft(2, '0')}.',
  );
  return details.join(' ');
}

String _semanticCurrency(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _keywordController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _keywordController.text = ref.read(searchFilterProvider).keyword;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _keywordController.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref
          .read(searchFilterProvider.notifier)
          .update((state) => state.copyWith(keyword: value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final results = ref.watch(searchResultsProvider);
    final allTransactions = ref.watch(_allTransactionsProvider);
    final isLoading = allTransactions.isLoading;
    final hasActiveFilter = _hasActiveFilter(filter);

    return AppScaffold(
      title: '거래 검색',
      body: Column(
        children: [
          _SearchControlCard(
            controller: _keywordController,
            filter: filter,
            hasActiveFilter: hasActiveFilter,
            isLoading: isLoading,
            resultsCount: results.length,
            summaryText: _buildFilterSummary(filter),
            onKeywordChanged: _onKeywordChanged,
            onClearKeyword: () {
              _keywordController.clear();
              ref
                  .read(searchFilterProvider.notifier)
                  .update((state) => state.copyWith(keyword: ''));
            },
            onReset: _resetFilters,
            onSelectType: (type) => ref
                .read(searchFilterProvider.notifier)
                .update((state) => state.copyWith(type: type)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: switch ((isLoading, results.isEmpty)) {
              (true, _) => const Center(child: CircularProgressIndicator()),
              (false, true) => _EmptySearchState(
                  hasActiveFilter: hasActiveFilter,
                  onReset: hasActiveFilter ? _resetFilters : null,
                ),
              (false, false) => ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final transaction = results[index];
                    return _SearchResultTile(transaction: transaction);
                  },
                ),
            },
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

  String _buildFilterSummary(SearchFilter filter) {
    final parts = <String>[];

    if (filter.keyword.isNotEmpty) {
      parts.add('"${filter.keyword}"');
    }
    if (filter.type != null) {
      parts.add(_typeLabel(filter.type!));
    }
    if (filter.categoryId != null) {
      parts.add('카테고리 지정');
    }
    if (filter.accountId != null) {
      parts.add('계좌 지정');
    }

    if (parts.isEmpty) {
      return '전체';
    }

    return parts.join(' · ');
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
}

class _SearchControlCard extends StatelessWidget {
  const _SearchControlCard({
    required this.controller,
    required this.filter,
    required this.hasActiveFilter,
    required this.isLoading,
    required this.resultsCount,
    required this.summaryText,
    required this.onKeywordChanged,
    required this.onClearKeyword,
    required this.onReset,
    required this.onSelectType,
  });

  final TextEditingController controller;
  final SearchFilter filter;
  final bool hasActiveFilter;
  final bool isLoading;
  final int resultsCount;
  final String summaryText;
  final ValueChanged<String> onKeywordChanged;
  final VoidCallback onClearKeyword;
  final VoidCallback onReset;
  final ValueChanged<String?> onSelectType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultLabel = isLoading
        ? '검색 조건을 적용하는 중'
        : '검색 결과 ${resultsCount.toString()}건';

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            textField: true,
            label: 'Search transactions by merchant or memo',
            hint: 'Type a keyword to filter transactions.',
            child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '예: 배달의민족, 월세, 이체',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: filter.keyword.isNotEmpty
                  ? IconButton(
                      onPressed: onClearKeyword,
                      tooltip: '검색어 지우기',
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
              onChanged: onKeywordChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
                        onTap: () => onSelectType(null),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: '지출',
                        selected: filter.type == 'expense',
                        onTap: () => onSelectType('expense'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: '수입',
                        selected: filter.type == 'income',
                        onTap: () => onSelectType('income'),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: '이체',
                        selected: filter.type == 'transfer',
                        onTap: () => onSelectType('transfer'),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasActiveFilter) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onReset,
                  child: const Text('초기화'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            container: true,
            label: searchSummarySemanticLabel(
              filter,
              resultsCount,
              isLoading: isLoading,
            ),
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.26),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summaryText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: AppOpacity.textSoft),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resultLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
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
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.86),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.white.withValues(alpha: AppOpacity.chipSelected),
      selectedColor: Colors.white.withValues(alpha: 0.24),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _title(transaction);
    final subtitle = _subtitle(transaction);
    final iconColor = _iconColor(transaction.type);
    final trailingTop = _amountText(transaction);
    final trailingBottom = _formatDateTime(transaction.occurredAt);

    return Semantics(
      container: true,
      label: searchResultSemanticLabel(transaction),
      child: GlassCard(
        blur: 12,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: AppOpacity.overlayHighlightDark),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                _icon(transaction.type),
                color: iconColor,
                size: 20,
              ),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: AppOpacity.iconInactive),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailingTop,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trailingBottom,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _title(Transaction transaction) {
    final merchant = transaction.merchantName?.trim();
    final memo = transaction.memo?.trim();

    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }
    if (memo != null && memo.isNotEmpty) {
      return memo;
    }
    return _typeLabel(transaction.type);
  }

  String _subtitle(Transaction transaction) {
    final memo = transaction.memo?.trim();
    final merchant = transaction.merchantName?.trim();
    final parts = <String>[];

    if (merchant != null && merchant.isNotEmpty) {
      parts.add(merchant);
    }
    if (memo != null && memo.isNotEmpty && memo != merchant) {
      parts.add(memo);
    }
    parts.add(_typeLabel(transaction.type));
    return parts.join(' · ');
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

  String _amountText(Transaction transaction) {
    final prefix = switch (transaction.type) {
      'expense' => '-',
      'income' => '+',
      _ => '',
    };
    return '$prefix${_formatCurrency(transaction.amount)}';
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'expense':
        return AppColors.expense;
      case 'income':
        return AppColors.income;
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'income':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  String _formatCurrency(int amount) {
    final raw = amount.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return '$buffer원';
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month.$day';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${_formatDate(dateTime)} · $hour:$minute';
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.hasActiveFilter,
    this.onReset,
  });

  final bool hasActiveFilter;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = hasActiveFilter
        ? '조건에 맞는 거래가 없어요'
        : '아직 검색한 거래가 없어요';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0EA),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 34,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _HintChip(label: '배달의민족'),
                _HintChip(label: '월세'),
                _HintChip(label: '카페'),
                _HintChip(label: '이체'),
              ],
            ),
            if (onReset != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('필터 초기화'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EE),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: const Color(0xFFE9E1D4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
