import 'package:flutter/material.dart';

import '../../transactions/data/transaction_export_service.dart';

class CsvExportOptionsDialog extends StatelessWidget {
  const CsvExportOptionsDialog({super.key});

  static Future<TransactionCsvExportOptions?> show(
    BuildContext context,
  ) {
    return showDialog<TransactionCsvExportOptions>(
      context: context,
      builder: (dialogContext) => const CsvExportOptionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CSV 범위 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionTile(
            icon: Icons.all_inbox_outlined,
            title: '전체 내역',
            subtitle: '삭제되지 않은 모든 거래를 CSV로 저장합니다.',
            onTap: () => _select(
              context,
              const TransactionCsvExportOptions(label: '전체 거래'),
            ),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.calendar_month_outlined,
            title: '이번 달',
            subtitle: '이번 달 1일부터 오늘까지 내보냅니다.',
            onTap: () => _select(context, _thisMonth()),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.history_outlined,
            title: '최근 30일',
            subtitle: '오늘 포함 최근 30일 거래만 내보냅니다.',
            onTap: () => _select(context, _last30Days()),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.date_range_outlined,
            title: '직접 선택',
            subtitle: '시작일과 종료일을 골라 원하는 범위만 저장합니다.',
            onTap: () => _pickCustomRange(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }

  void _select(
    BuildContext context,
    TransactionCsvExportOptions options,
  ) {
    Navigator.of(context).pop(options);
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 29)),
        end: now,
      ),
      helpText: 'CSV 날짜 범위',
      cancelText: '취소',
      confirmText: '선택',
      saveText: '선택',
      fieldStartHintText: '시작일',
      fieldEndHintText: '종료일',
    );

    if (range == null || !context.mounted) {
      return;
    }

    _select(
      context,
      TransactionCsvExportOptions(
        startDate: range.start,
        endDate: range.end,
        label:
            '${_format(range.start)} - ${_format(range.end)}',
      ),
    );
  }

  TransactionCsvExportOptions _thisMonth() {
    final now = DateTime.now();
    return TransactionCsvExportOptions(
      startDate: DateTime(now.year, now.month),
      endDate: now,
      label: '${now.month}월 거래',
    );
  }

  TransactionCsvExportOptions _last30Days() {
    final now = DateTime.now();
    return TransactionCsvExportOptions(
      startDate: now.subtract(const Duration(days: 29)),
      endDate: now,
      label: '최근 30일',
    );
  }

  String _format(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
