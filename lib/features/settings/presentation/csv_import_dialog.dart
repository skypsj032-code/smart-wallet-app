import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../transactions/data/csv_import_service.dart';

enum _ImportPreset { smartWallet, threeColumn, custom }

class CsvImportDialog extends ConsumerStatefulWidget {
  const CsvImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CsvImportDialog(),
    );
  }

  @override
  ConsumerState<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends ConsumerState<CsvImportDialog> {
  _ImportPreset _preset = _ImportPreset.smartWallet;
  bool _isLoading = false;
  String? _csvText;
  List<String> _headers = [];
  String? _fileName;
  CsvImportResult? _result;
  String? _errorMsg;

  // Custom 매핑용
  int _typeCol = 1;
  int _amountCol = 2;
  int _occurredAtCol = 3;
  int _memoCol = -1;
  bool _hasHeader = true;

  CsvColumnMapping get _mapping {
    switch (_preset) {
      case _ImportPreset.smartWallet:
        return CsvColumnMapping.smartWalletExport;
      case _ImportPreset.threeColumn:
        return CsvColumnMapping.simpleThreeColumn;
      case _ImportPreset.custom:
        return CsvColumnMapping(
          typeCol: _typeCol,
          amountCol: _amountCol,
          occurredAtCol: _occurredAtCol,
          memoCol: _memoCol < 0 ? null : _memoCol,
          hasHeader: _hasHeader,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('CSV 가져오기'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파일 선택 버튼
              if (_csvText == null) ...[
                Text(
                  '다른 앱이나 엑셀에서 내보낸 CSV 파일을 불러옵니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('CSV 파일 선택'),
                ),
              ] else ...[
                // 파일 선택 완료 표시
                _FileSelectedBanner(
                  fileName: _fileName ?? 'unknown.csv',
                  rowCount: _headers.isNotEmpty
                      ? '${_headers.length}개 열 감지됨'
                      : null,
                  onClear: () => setState(() {
                    _csvText = null;
                    _headers = [];
                    _fileName = null;
                    _result = null;
                    _errorMsg = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),

                // 열 매핑 프리셋 선택
                Text(
                  '가져오기 형식',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _PresetTile(
                  title: '스마트 월렛 내보내기',
                  subtitle: '이 앱에서 내보낸 CSV 그대로 복원',
                  selected: _preset == _ImportPreset.smartWallet,
                  onTap: () => setState(() => _preset = _ImportPreset.smartWallet),
                ),
                const SizedBox(height: AppSpacing.xs),
                _PresetTile(
                  title: '단순 3열 (날짜, 금액, 메모)',
                  subtitle: '날짜·금액·메모만 있는 간단한 CSV',
                  selected: _preset == _ImportPreset.threeColumn,
                  onTap: () => setState(() => _preset = _ImportPreset.threeColumn),
                ),
                const SizedBox(height: AppSpacing.xs),
                _PresetTile(
                  title: '직접 설정',
                  subtitle: '열 번호를 수동으로 지정',
                  selected: _preset == _ImportPreset.custom,
                  onTap: () => setState(() => _preset = _ImportPreset.custom),
                ),

                // 커스텀 설정 패널
                if (_preset == _ImportPreset.custom) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xs),
                  _ColPicker(
                    label: '날짜 열 번호 (0부터)',
                    value: _occurredAtCol,
                    onChanged: (v) => setState(() => _occurredAtCol = v),
                  ),
                  _ColPicker(
                    label: '금액 열 번호',
                    value: _amountCol,
                    onChanged: (v) => setState(() => _amountCol = v),
                  ),
                  _ColPicker(
                    label: '타입 열 번호 (-1이면 전부 지출)',
                    value: _typeCol,
                    onChanged: (v) => setState(() => _typeCol = v),
                    min: -1,
                  ),
                  _ColPicker(
                    label: '메모 열 번호 (-1이면 무시)',
                    value: _memoCol,
                    onChanged: (v) => setState(() => _memoCol = v),
                    min: -1,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('첫 행을 헤더로 처리'),
                    value: _hasHeader,
                    onChanged: (v) => setState(() => _hasHeader = v),
                  ),
                ],

                // 결과 표시
                if (_result != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xs),
                  _ResultBanner(result: _result!),
                ],

                if (_errorMsg != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMsg!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(_result != null ? '닫기' : '취소'),
        ),
        if (_csvText != null && _result == null)
          FilledButton(
            onPressed: _isLoading ? null : _doImport,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('가져오기'),
          ),
      ],
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final service = ref.read(csvImportServiceProvider);
      final text = await service.pickCsvFile();
      if (text == null) return;

      final headers = service.parseHeaders(text);
      setState(() {
        _csvText = text;
        _headers = headers;
        _fileName = 'import.csv';
      });
    } catch (e) {
      setState(() => _errorMsg = '파일을 읽지 못했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _doImport() async {
    final csv = _csvText;
    if (csv == null) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _result = null;
    });

    try {
      final result = await ref
          .read(csvImportServiceProvider)
          .importCsv(csv, _mapping);

      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMsg = '가져오기 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// ── 보조 위젯 ─────────────────────────────────────────────────────────────────

class _FileSelectedBanner extends StatelessWidget {
  const _FileSelectedBanner({
    required this.fileName,
    required this.onClear,
    this.rowCount,
  });

  final String fileName;
  final String? rowCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rowCount != null)
                  Text(rowCount!, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ColPicker extends StatelessWidget {
  const _ColPicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => onChanged(value + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final CsvImportResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        result.success ? theme.colorScheme.primary : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.success
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              result.success
                  ? '${result.imported}건 가져오기 완료'
                  : '가져오기 실패',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        if (result.skipped > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${result.skipped}행은 건너뜀 (빈 행 또는 필수값 없음)',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (result.hasErrors) ...[
          const SizedBox(height: 6),
          ...result.errors.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                e,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
