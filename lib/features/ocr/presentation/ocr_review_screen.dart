import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/platform/ocr_platform_support.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/ocr_capture_provider.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({super.key});

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late final TextEditingController _rawTextController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;

  bool _hasUnsavedChanges = false;
  String? _lastHydratedKey;

  @override
  void initState() {
    super.initState();
    _rawTextController = TextEditingController();
    _storeNameController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _rawTextController.dispose();
    _storeNameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isOcrPlatformSupported) {
      return AppScaffold(
        title: '영수증 검토',
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 32),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '이 기기에서는 영수증 검토를 사용할 수 없어요',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      '영수증 스캔은 Android, iOS에서만 지원됩니다. 데스크탑에서는 빠른 입력으로 직접 기록할 수 있어요.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/quick-entry'),
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('빠른 입력 열기'),
              ),
            ],
          ),
        ),
      );
    }

    final draft = ref.watch(ocrCaptureProvider);
    final isBusy =
        draft.status == OcrFlowStatus.capturing || draft.status == OcrFlowStatus.parsed;

    _syncControllersIfNeeded(draft);

    final parsedAmount = _sanitizeAmount(_amountController.text);
    final hasMerchantOrText =
        _storeNameController.text.trim().isNotEmpty || _rawTextController.text.trim().isNotEmpty;
    final hasVisibleDraft = draft.hasImage ||
        draft.hasRawText ||
        draft.hasParsedStoreName ||
        draft.hasParsedAmount ||
        _rawTextController.text.trim().isNotEmpty ||
        _storeNameController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty;

    if (!hasVisibleDraft && draft.status == OcrFlowStatus.idle) {
      return AppScaffold(
        title: '영수증 검토',
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _EmptyReviewState(),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/ocr-capture'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('영수증 촬영하기'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  final quickEntry = ref.read(quickEntryFormProvider.notifier);
                  quickEntry.reset();
                  quickEntry.setType(TransactionEntryType.expense);
                  context.go('/quick-entry');
                },
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('직접 입력하기'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: '영수증 검토',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ReviewBanner(
            statusLabel: _statusLabel(draft.status),
            body: _bannerMessage(draft, amountReady: parsedAmount != null),
            isError: draft.errorMessage != null || draft.status == OcrFlowStatus.failed,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaChip(
                icon: Icons.document_scanner_outlined,
                label: draft.hasRawText ? 'OCR 텍스트 있음' : 'OCR 텍스트 없음',
              ),
              _MetaChip(
                icon: Icons.storefront_outlined,
                label: draft.hasParsedStoreName ? '상호 인식됨' : '상호 확인 필요',
              ),
              _MetaChip(
                icon: Icons.payments_outlined,
                label: parsedAmount != null ? '금액 확인됨' : '금액 입력 필요',
              ),
              _MetaChip(
                icon: Icons.verified_outlined,
                label: draft.confidence == null
                    ? '신뢰도 없음'
                    : '신뢰도 ${draft.confidence!.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: '검토 체크',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _ChecklistRow(
                      icon: parsedAmount != null ? Icons.check_circle : Icons.radio_button_unchecked,
                      label: parsedAmount != null
                          ? '빠른 입력에 쓸 금액이 준비되었습니다'
                          : '계속하려면 최종 금액을 입력해 주세요',
                      tone: parsedAmount != null ? _ChecklistTone.success : _ChecklistTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ChecklistRow(
                      icon:
                          hasMerchantOrText ? Icons.check_circle : Icons.radio_button_unchecked,
                      label: hasMerchantOrText
                          ? '상호명 또는 OCR 텍스트가 있습니다'
                          : '상호명을 적거나 참고용 OCR 텍스트를 남겨 주세요',
                      tone: hasMerchantOrText
                          ? _ChecklistTone.success
                          : _ChecklistTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ChecklistRow(
                      icon: draft.hasImage ? Icons.check_circle : Icons.info_outline,
                      label: draft.hasImage
                          ? '촬영한 이미지가 남아 있어 OCR을 다시 돌릴 수 있습니다'
                          : '저장된 이미지가 없어 다시 촬영해야 합니다',
                      tone: draft.hasImage ? _ChecklistTone.normal : _ChecklistTone.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: '수정한 초안',
            action: _hasUnsavedChanges
                ? Text(
                    '저장되지 않은 수정',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.expense,
                        ),
                  )
                : null,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    TextField(
                      controller: _storeNameController,
                      enabled: !isBusy,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '상호명',
                        hintText: '매장 이름 또는 상호명',
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      enabled: !isBusy,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '금액',
                        hintText: '예: 12800',
                        helperText: parsedAmount == null
                            ? '빠른 입력으로 넘기려면 올바른 금액이 필요합니다.'
                            : '빠른 입력에 $parsedAmount원을 사용합니다.',
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _categoryController,
                      enabled: !isBusy,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '예상 카테고리',
                        hintText: '선택 사항',
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    if (_hasUnsavedChanges) ...[
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: isBusy
                              ? null
                              : () => setState(() {
                                    _hydrateFromDraft(ref.read(ocrCaptureProvider));
                                  }),
                          icon: const Icon(Icons.undo_outlined),
                          label: const Text('화면 수정 내용 되돌리기'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: 'OCR 텍스트',
            action: TextButton.icon(
              onPressed: isBusy
                  ? null
                  : () async {
                      await ref
                          .read(ocrCaptureProvider.notifier)
                          .refreshSuggestionsFromRawText(_rawTextController.text);
                      _hydrateFromDraft(ref.read(ocrCaptureProvider));
                    },
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: const Text('추천 다시 만들기'),
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _rawTextController,
                  enabled: !isBusy,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    hintText: '추출한 OCR 텍스트가 여기에 표시됩니다. 내용을 고친 뒤 추천을 다시 만들 수 있습니다.',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _markDirty(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: '다른 작업',
            child: Card(
              child: Column(
                children: [
                  _SecondaryActionTile(
                    icon: Icons.document_scanner_outlined,
                    title: 'OCR 다시 실행',
                    subtitle: '저장한 사진으로 초안을 다시 만듭니다.',
                    enabled: draft.hasImage && !isBusy,
                    onTap: () async {
                      if (!await _confirmDiscardChanges(
                        title: '저장된 사진으로 OCR을 다시 실행할까요?',
                        body:
                            '다시 실행하면 이 화면에서 수정한 내용이 새 초안으로 덮어써질 수 있습니다.',
                      )) {
                        return;
                      }

                      await ref.read(ocrCaptureProvider.notifier).retryFromCapturedImage();
                      _hydrateFromDraft(ref.read(ocrCaptureProvider));
                    },
                  ),
                  const Divider(height: 1),
                  _SecondaryActionTile(
                    icon: Icons.keyboard_alt_outlined,
                    title: '직접 입력으로 전환',
                    subtitle: '현재 금액과 상호명을 가져가서 수동 입력 화면으로 이동합니다.',
                    enabled: !isBusy,
                    onTap: () {
                      final quickEntry = ref.read(quickEntryFormProvider.notifier);
                      quickEntry.setType(TransactionEntryType.expense);
                      quickEntry.setAmount(_sanitizeAmount(_amountController.text) ?? '');
                      quickEntry.setMemo(
                        _storeNameController.text.trim().isEmpty
                            ? '수동 영수증 입력'
                            : _storeNameController.text.trim(),
                      );
                      context.go('/quick-entry');
                    },
                  ),
                  const Divider(height: 1),
                  _SecondaryActionTile(
                    icon: Icons.camera_alt_outlined,
                    title: '촬영 화면으로 돌아가기',
                    subtitle: '영수증을 다시 찍거나 다른 영수증을 선택합니다.',
                    enabled: !isBusy,
                    onTap: () async {
                      if (!await _confirmDiscardChanges(
                        title: '촬영 화면으로 돌아갈까요?',
                        body:
                            '이 화면에서 수정한 내용은 아직 저장되지 않았습니다. 그대로 돌아가면 변경 사항을 잃을 수 있습니다.',
                      )) {
                        return;
                      }

                      if (!context.mounted) {
                        return;
                      }
                      context.go('/ocr-capture');
                    },
                  ),
                ],
              ),
            ),
          ),
          if (draft.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _InlineError(message: draft.errorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: isBusy
                ? null
                : () async {
                    final saved =
                        await ref.read(ocrCaptureProvider.notifier).saveReviewEdits(
                              rawText: _rawTextController.text,
                              storeName: _storeNameController.text,
                              amountText: _amountController.text,
                              categoryGuess: _categoryController.text,
                            );
                    _hydrateFromDraft(ref.read(ocrCaptureProvider));
                    if (!saved || !context.mounted) {
                      return;
                    }

                    final latestDraft = ref.read(ocrCaptureProvider);
                    final quickEntry = ref.read(quickEntryFormProvider.notifier);
                    quickEntry.setType(TransactionEntryType.expense);
                    quickEntry.setAmount(latestDraft.amount?.toString() ?? '');
                    quickEntry.setMemo(latestDraft.storeName ?? 'OCR 초안');
                    // OCR이 추측한 카테고리 ID를 빠른 입력에 사전 선택
                    final guessedId = latestDraft.categoryGuess;
                    if (guessedId != null && guessedId.isNotEmpty) {
                      quickEntry.setCategory(guessedId);
                    }
                    context.go('/quick-entry');
                  },
            icon: const Icon(Icons.arrow_forward_outlined),
            label: Text(
              _primaryActionLabel(
                hasAmount: parsedAmount != null,
                hasUnsavedChanges: _hasUnsavedChanges,
              ),
            ),
          ),
          if (parsedAmount == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '빠른 입력으로 바로 넘기려면 먼저 금액을 채워 주세요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  void _syncControllersIfNeeded(OcrDraftState draft) {
    final draftKey = [
      draft.localId ?? '',
      draft.status.name,
      draft.rawText,
      draft.storeName ?? '',
      draft.amount?.toString() ?? '',
      draft.categoryGuess ?? '',
      draft.errorMessage ?? '',
    ].join('|');

    if (_hasUnsavedChanges && _lastHydratedKey != null) {
      return;
    }

    if (_lastHydratedKey == draftKey) {
      return;
    }

    _hydrateFromDraft(draft);
  }

  void _hydrateFromDraft(OcrDraftState draft) {
    _replaceControllerText(_rawTextController, draft.rawText);
    _replaceControllerText(_storeNameController, draft.storeName ?? '');
    _replaceControllerText(_amountController, draft.amount?.toString() ?? '');
    // 카테고리 ID를 한국어 레이블로 변환해서 표시
    final categoryLabel = _categoryIdToLabel(draft.categoryGuess);
    _replaceControllerText(_categoryController, categoryLabel);
    _lastHydratedKey = [
      draft.localId ?? '',
      draft.status.name,
      draft.rawText,
      draft.storeName ?? '',
      draft.amount?.toString() ?? '',
      draft.categoryGuess ?? '',
      draft.errorMessage ?? '',
    ].join('|');
    _hasUnsavedChanges = false;
  }

  void _replaceControllerText(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _markDirty() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  String _primaryActionLabel({
    required bool hasAmount,
    required bool hasUnsavedChanges,
  }) {
    if (!hasAmount) {
      return '검토 내용 저장';
    }

    if (hasUnsavedChanges) {
      return '저장 후 빠른 입력으로 이동';
    }

    return '빠른 입력으로 이동';
  }

  Future<bool> _confirmDiscardChanges({
    required String title,
    required String body,
  }) async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('계속 수정하기'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('변경 내용 버리기'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  /// 카테고리 ID(예: 'expense-food')를 한국어 표시 이름으로 변환한다.
  String _categoryIdToLabel(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return '';
    const labels = <String, String>{
      'expense-food': '식비',
      'expense-cafe-snack': '카페/간식',
      'expense-groceries': '장보기',
      'expense-transport': '교통',
      'expense-housing-utilities': '주거/통신',
      'expense-shopping': '쇼핑/패션',
      'expense-household': '생활용품',
      'expense-health': '의료/건강',
      'expense-leisure': '취미/여가',
      'expense-subscriptions': '구독/디지털',
      'expense-gifts': '경조사/선물',
      'expense-other': '기타 지출',
      'income-salary': '급여',
      'income-allowance': '용돈/지원',
      'income-side-income': '부수입',
      'income-resale': '중고판매',
      'income-refund': '환급/캐시백',
      'income-interest-dividend': '이자/배당',
      'income-other': '기타 수입',
    };
    return labels[categoryId] ?? categoryId;
  }

  String _statusLabel(OcrFlowStatus status) {
    switch (status) {
      case OcrFlowStatus.idle:
        return '초안이 아직 없습니다';
      case OcrFlowStatus.capturing:
        return '촬영 또는 OCR 진행 중';
      case OcrFlowStatus.extracted:
        return '텍스트 추출 완료';
      case OcrFlowStatus.parsed:
        return '추천 초안 다시 만드는 중';
      case OcrFlowStatus.reviewRequired:
        return '검토가 필요합니다';
      case OcrFlowStatus.failed:
        return 'OCR 처리 실패';
    }
  }

  String _bannerMessage(OcrDraftState draft, {required bool amountReady}) {
    if (draft.status == OcrFlowStatus.idle) {
      return '아직 촬영한 영수증이 없습니다. 먼저 영수증을 찍거나, OCR 없이 바로 직접 입력할 수 있습니다.';
    }

    if (draft.status == OcrFlowStatus.failed && !draft.hasRawText) {
      return '추출된 텍스트가 없어 초안을 만들지 못했습니다. 다시 촬영하거나 직접 입력으로 전환해 주세요.';
    }

    if (draft.errorMessage != null) {
      return '초안이 일부만 만들어졌습니다. 아래 항목을 직접 고치거나 OCR 텍스트를 수정한 뒤 추천을 다시 만들어 주세요.';
    }

    if (!amountReady) {
      return '금액을 꼭 다시 확인해 주세요. 금액이 비어 있으면 빠른 입력으로 넘어갈 수 없습니다.';
    }

    return '상호명, 금액, 카테고리, OCR 원문을 확인한 뒤 계속 진행하세요.';
  }

  String? _sanitizeAmount(String rawValue) {
    final digitsOnly = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return digitsOnly;
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: Colors.black.withValues(alpha: 0.60),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '검토할 OCR 초안이 없습니다',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '먼저 영수증을 촬영해 초안을 만든 뒤 다시 오거나, 바로 수동 입력으로 넘어갈 수 있습니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _ChecklistTone {
  normal,
  success,
  warning,
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final _ChecklistTone tone;

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (tone) {
      _ChecklistTone.success => Colors.green.shade700,
      _ChecklistTone.warning => Colors.orange.shade800,
      _ChecklistTone.normal => Colors.black.withValues(alpha: 0.70),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({
    required this.statusLabel,
    required this.body,
    required this.isError,
  });

  final String statusLabel;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background = isError
        ? AppColors.expense.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.08);
    final iconColor = isError ? AppColors.expense : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.fact_check_outlined,
            color: iconColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _SecondaryActionTile extends StatelessWidget {
  const _SecondaryActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.expense),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
