import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../notifications/application/notification_provider.dart';
import '../../notifications/data/notification_channel.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/widgets/app_hero_panel.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_intro.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_utility_group.dart';
import '../application/backup_service.dart';
import '../application/settings_provider.dart';
import '../../transactions/data/transaction_export_service.dart';
import 'csv_export_options_dialog.dart';
import 'csv_import_dialog.dart';
import 'lock_setup_dialog.dart';

/// 최근 30일간 감지된 알림 건수
final _recentNotificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.countRecentNotificationHistories(dayRange: 30);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final sessionUnlocked = ref.watch(sessionUnlockedProvider);

    return AppScaffold(
      title: '설정',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _SettingsHeroCard(),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionIntro(
            title: '일상 이동',
            subtitle: '자주 쓰는 화면으로 조용하게 이동합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppUtilityGroup(
            children: [
              _SettingsActionTile(
                icon: Icons.search_rounded,
                color: AppColors.primary,
                title: '거래 검색',
                subtitle: '필요한 기록을 빠르게 찾습니다.',
                onTap: () => context.go('/search'),
              ),
              _SettingsActionTile(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                title: '계좌 관리',
                subtitle: '현금, 통장, 카드의 흐름을 정리합니다.',
                onTap: () => context.go('/accounts'),
              ),
              _SettingsActionTile(
                icon: Icons.savings_outlined,
                color: AppColors.primary,
                title: '예산 관리',
                subtitle: '이번 달 계획을 차분하게 점검합니다.',
                onTap: () => context.go('/budgets'),
              ),
              _SettingsActionTile(
                icon: Icons.document_scanner_outlined,
                color: AppColors.primary,
                title: '영수증 스캔',
                subtitle: '영수증 내용을 바로 불러옵니다.',
                onTap: () => context.go('/ocr-capture'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionIntro(
            title: '데이터 안전',
            subtitle: '내보내기는 가볍게, 복원은 가장 신중하게 다룹니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppUtilityGroup(
            children: [
              _SettingsActionTile(
                icon: Icons.file_upload_outlined,
                color: AppColors.primary,
                title: 'JSON 백업 만들기',
                subtitle: '현재 데이터를 안전한 파일로 저장합니다.',
                onTap: () => _exportBackup(context, ref),
              ),
              _SettingsActionTile(
                icon: Icons.table_view_outlined,
                color: AppColors.primary,
                title: 'CSV 내보내기',
                subtitle: '거래 내역을 표 형식으로 공유합니다.',
                onTap: () => _exportCsv(context, ref),
              ),
              _SettingsActionTile(
                icon: Icons.upload_file_outlined,
                color: AppColors.primary,
                title: 'CSV 가져오기',
                subtitle: '다른 앱에서 내보낸 CSV를 불러옵니다.',
                onTap: () => _importCsv(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RestoreActionCard(
            onTap: () => _restoreBackup(context, ref),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionIntro(
            title: '보안',
            subtitle: '앱 잠금과 PIN 상태를 한 번에 관리합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          appSettingsAsync.when(
            data: (settings) => _AppLockCard(
              enabled: settings.appLockEnabled,
              sessionUnlocked: sessionUnlocked,
              onToggle: (enabled) async {
                if (enabled) {
                  await _enableAppLock(context, ref);
                } else {
                  await _disableAppLock(context, ref, settings);
                }
              },
              onChangePin: () => _enableAppLock(
                context,
                ref,
                isChangingPin: true,
              ),
              onLockNow: () => _lockNow(context, ref),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('보안 설정을 불러오지 못했습니다.\n$error'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionIntro(
            title: '알림 자동 기록',
            subtitle: '카드·은행 알림을 읽어 거래를 자동으로 제안합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _NotificationListenerCard(),
          const SizedBox(height: AppSpacing.sm),
          AppUtilityGroup(
            children: [
              _SettingsActionTile(
                icon: Icons.history_rounded,
                color: AppColors.primary,
                title: '알림 수신 이력',
                subtitle: ref.watch(_recentNotificationCountProvider).when(
                      data: (count) => '지난 30일간 감지된 알림 $count건',
                      loading: () => '감지된 알림 목록을 확인하고 거래로 연결합니다.',
                      error: (_, __) => '감지된 알림 목록을 확인하고 거래로 연결합니다.',
                    ),
                onTap: () => context.go('/notification-history'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionIntro(
            title: '화면',
            subtitle: '앱의 분위기를 현재 환경에 맞게 조정합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          appSettingsAsync.when(
            data: (settings) => AppUtilityGroup(
              children: [
                _ThemeModeTile(
                  currentMode: settings.themeMode,
                  onChanged: (mode) =>
                      _updateThemeMode(context, ref, settings, mode),
                ),
              ],
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateThemeMode(
    BuildContext context,
    WidgetRef ref,
    AppSetting settings,
    String mode,
  ) async {
    final db = ref.read(appDatabaseProvider);
    await db.update(db.appSettings).replace(
          settings.copyWith(
            themeMode: mode,
            lastModifiedAt: DateTime.now(),
          ),
        );
  }

  Future<void> _enableAppLock(
    BuildContext context,
    WidgetRef ref, {
    bool isChangingPin = false,
  }) async {
    final configured = await LockSetupDialog.show(
      context,
      isChangingPin: isChangingPin,
    );
    if (configured != true || !context.mounted) {
      return;
    }

    ref.read(sessionUnlockedProvider.notifier).state = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isChangingPin ? 'PIN을 변경했습니다.' : '앱 잠금을 설정했습니다.',
        ),
      ),
    );
  }

  void _lockNow(BuildContext context, WidgetRef ref) {
    ref.read(sessionUnlockedProvider.notifier).state = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('현재 세션을 잠갔습니다.')),
    );
  }

  Future<void> _disableAppLock(
    BuildContext context,
    WidgetRef ref,
    AppSetting settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('앱 잠금 해제'),
          content: const Text(
            'PIN 잠금을 끄면 다음부터는 추가 인증 없이 앱이 바로 열립니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('해제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    await db.update(db.appSettings).replace(
          settings.copyWith(
            appLockEnabled: false,
            pinCode: const drift.Value(null),
            lastModifiedAt: now,
          ),
        );

    ref.read(sessionUnlockedProvider.notifier).state = true;

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('앱 잠금을 해제했습니다.')),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    await CsvImportDialog.show(context);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final payload = await ref.read(backupServiceProvider).exportJsonBackup();
    final file = await ref.read(backupServiceProvider).saveBackupFile(payload);

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('백업 파일을 만들었습니다'),
        content: SingleChildScrollView(
          child: Text(
            '파일 이름: ${payload.fileName}\n'
            '저장 위치: ${file.path}\n\n'
            '포함 항목\n'
            '- 거래 ${payload.summary.transactionCount}개\n'
            '- 카테고리 ${payload.summary.categoryCount}개\n'
            '- 예산 ${payload.summary.budgetCount}개\n'
            '- 계좌 ${payload.summary.accountCount}개\n\n'
            '이 파일은 공유 시트를 통해 드라이브, 메일, 메신저로 보낼 수 있습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(backupServiceProvider).shareBackupFile(
                    file,
                    text: '공유용으로 만든 Smart Wallet 백업 파일입니다.',
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('드라이브로 보내기'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(backupServiceProvider).shareBackupFile(file);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('다른 앱으로 공유'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    RestoreSafetyBackup? safetyBackup;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final fileInfo = File(result.files.single.path!);
      final jsonStr = await fileInfo.readAsString();
      final backupService = ref.read(backupServiceProvider);
      final preview = await backupService.inspectJsonBackup(jsonStr);

      if (!context.mounted) {
        return;
      }

      final shouldRestore = await _confirmRestore(
        context,
        preview,
        fileInfo.path,
      );
      if (shouldRestore != true) {
        return;
      }

      try {
        safetyBackup = await backupService.createRestoreSafetyBackup();
      } catch (e) {
        if (!context.mounted) {
          return;
        }

        await _showRestoreStoppedDialog(context, e);
        return;
      }

      final summary = await backupService.restoreJsonBackup(jsonStr);

      if (!context.mounted) {
        return;
      }

      await _showRestoreCompleteDialog(
        context,
        ref,
        safetyBackup: safetyBackup,
        summary: summary,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      if (safetyBackup != null) {
        await _showRestoreFailedDialog(
          context,
          ref,
          safetyBackup: safetyBackup,
          error: e,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복원에 실패했습니다: $e')),
      );
    }
  }

  Future<bool?> _confirmRestore(
    BuildContext context,
    BackupPreview preview,
    String filePath,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('백업에서 복원할까요?'),
          content: SingleChildScrollView(
            child: Text(
              '복원을 시작하면 현재 데이터가 선택한 백업 내용으로 교체됩니다.\n'
              '문제가 생기면 복원 직전에 만든 안전 백업으로 되돌릴 수 있습니다.\n\n'
              '파일: $filePath\n'
              '백업 버전: ${preview.backupVersion}\n'
              '스키마 버전: ${preview.schemaVersion}\n'
              '앱 버전: ${preview.appVersion}\n'
              '생성 시각: ${preview.createdAt.toLocal()}\n\n'
              '포함 항목\n'
              '- 거래 ${preview.summary.transactionCount}개\n'
              '- 카테고리 ${preview.summary.categoryCount}개\n'
              '- 예산 ${preview.summary.budgetCount}개\n'
              '- 계좌 ${preview.summary.accountCount}개',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('안전 백업 후 복원'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRestoreStoppedDialog(BuildContext context, Object error) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('복원을 멈췄습니다'),
        content: Text(
          '안전 백업을 만들지 못해서 복원을 시작하지 않았습니다.\n\n'
          '데이터는 변경되지 않았습니다.\n'
          '오류: $error',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreCompleteDialog(
    BuildContext context,
    WidgetRef ref, {
    required RestoreSafetyBackup safetyBackup,
    required BackupSummary summary,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('복원이 완료되었습니다'),
        content: SingleChildScrollView(
          child: Text(
            '현재 데이터가 백업 내용으로 교체되었습니다.\n\n'
            '안전 백업 위치: ${safetyBackup.file.path}\n'
            '안전 백업 파일명: ${safetyBackup.payload.fileName}\n\n'
            '복원된 항목\n'
            '- 거래 ${summary.transactionCount}개\n'
            '- 카테고리 ${summary.categoryCount}개\n'
            '- 예산 ${summary.budgetCount}개\n'
            '- 계좌 ${summary.accountCount}개\n\n'
            '안전 백업 파일은 나중에 다시 공유할 수 있습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(backupServiceProvider).shareBackupFile(
                    safetyBackup.file,
                    text: '복원 직전에 만든 Smart Wallet 안전 백업 파일입니다.',
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('안전 백업 공유'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreFailedDialog(
    BuildContext context,
    WidgetRef ref, {
    required RestoreSafetyBackup safetyBackup,
    required Object error,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('복원에 실패했습니다'),
        content: SingleChildScrollView(
          child: Text(
            '복원은 끝나지 않았지만, 시작 직전에 만든 안전 백업은 남아 있습니다.\n\n'
            '안전 백업 위치: ${safetyBackup.file.path}\n'
            '안전 백업 파일명: ${safetyBackup.payload.fileName}\n\n'
            '오류: $error',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(backupServiceProvider).shareBackupFile(
                    safetyBackup.file,
                    text: 'Smart Wallet 복원 실패 시 보관한 안전 백업 파일입니다.',
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('안전 백업 공유'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final options = await CsvExportOptionsDialog.show(context);
    if (options == null) {
      return;
    }

    final exportService = ref.read(transactionExportServiceProvider);
    final payload = await exportService.exportTransactionsCsv(options: options);
    final file = await exportService.saveCsvFile(payload);

    if (!context.mounted) {
      return;
    }

    final filterLine = payload.filterDescription == null
        ? ''
        : '내보내기 범위: ${payload.filterDescription}\n';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CSV 파일을 만들었습니다'),
        content: SingleChildScrollView(
          child: Text(
            '파일 이름: ${payload.fileName}\n'
            '저장 위치: ${file.path}\n\n'
            '$filterLine'
            '내보낸 거래 수: ${payload.rowCount}개\n'
            '거래 내역을 CSV 파일로 저장했습니다.\n\n'
            '이 파일은 공유 시트를 통해 드라이브, 메일, 메신저로 보낼 수 있습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(transactionExportServiceProvider).shareCsvFile(
                    file,
                    text: '공유용으로 만든 Smart Wallet CSV 파일입니다.',
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('드라이브로 보내기'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(transactionExportServiceProvider).shareCsvFile(file);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('다른 앱으로 공유'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard();

  @override
  Widget build(BuildContext context) {
    return const AppHeroPanel(
      eyebrow: AppStatusChip(
        label: 'UTILITY HUB',
        dotColor: AppColors.primary,
      ),
      title: '조용한 지원 허브',
      body: '일상 이동, 데이터 안전, 보안, 화면 모드를 한곳에서 차분하게 관리합니다.',
    );
  }
}

class _AppLockCard extends StatelessWidget {
  const _AppLockCard({
    required this.enabled,
    required this.sessionUnlocked,
    required this.onToggle,
    required this.onChangePin,
    required this.onLockNow,
  });

  final bool enabled;
  final bool sessionUnlocked;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChangePin;
  final VoidCallback onLockNow;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onToggle,
              secondary: const Icon(Icons.lock_outline),
              title: const Text('앱 잠금'),
              subtitle: Text(
                enabled
                    ? '앱을 다시 열 때 4자리 PIN을 요청합니다.'
                    : '기기에서만 잠금을 사용하지 않는 상태입니다.',
              ),
            ),
            Text(
              enabled
                  ? sessionUnlocked
                      ? '현재 세션은 잠금이 해제된 상태입니다.'
                      : '현재 세션은 잠겨 있습니다. 다음 화면 전환부터 PIN이 필요합니다.'
                  : '앱 잠금을 다시 켜면 민감한 화면을 한 겹 더 보호할 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (enabled) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (sessionUnlocked)
                    OutlinedButton.icon(
                      onPressed: onLockNow,
                      icon: const Icon(Icons.lock),
                      label: const Text('지금 잠그기'),
                    ),
                  OutlinedButton.icon(
                    onPressed: onChangePin,
                    icon: const Icon(Icons.password_outlined),
                    label: const Text('PIN 변경'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '잠금을 켜도 현재 세션은 바로 닫히지 않습니다. 설정한 뒤에는 다음 사용부터 적용됩니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestoreActionCard extends StatelessWidget {
  const _RestoreActionCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.expense;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: const Icon(Icons.restore_rounded, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '백업에서 복원',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '선택한 JSON 백업으로 현재 데이터를 교체합니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppStatusChip(
                  label: '신중',
                  dotColor: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '복원 전에 자동으로 안전 백업을 한 번 더 남기므로, 실수했을 때 되돌릴 여지를 확보합니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.md,
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('복원 시작'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.currentMode,
    required this.onChanged,
  });

  final String currentMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Icon(
          currentMode == 'dark'
              ? Icons.dark_mode_outlined
              : currentMode == 'light'
                  ? Icons.light_mode_outlined
                  : Icons.brightness_auto_outlined,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        '화면 모드',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_modeLabel(currentMode)),
      ),
      trailing: DropdownButton<String>(
        value: currentMode,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'system', child: Text('시스템')),
          DropdownMenuItem(value: 'light', child: Text('라이트')),
          DropdownMenuItem(value: 'dark', child: Text('다크')),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'light':
        return '밝은 화면으로 표시합니다.';
      case 'dark':
        return '어두운 화면으로 표시합니다.';
      default:
        return '기기 설정에 따라 자동으로 맞춥니다.';
    }
  }
}

// ── 알림 자동 기록 카드 ──────────────────────────────────────────────

class _NotificationListenerCard extends ConsumerStatefulWidget {
  const _NotificationListenerCard();

  @override
  ConsumerState<_NotificationListenerCard> createState() =>
      _NotificationListenerCardState();
}

class _NotificationListenerCardState
    extends ConsumerState<_NotificationListenerCard> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // 앱 포그라운드 복귀 시 권한 상태 재확인
        ref.invalidate(notificationPermissionGrantedProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notificationListenerEnabledProvider);
    final permissionAsync = ref.watch(notificationPermissionGrantedProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: (value) async {
                if (value) {
                  // 권한 확인 후 활성화
                  final granted = await NotificationChannel.isPermissionGranted();
                  if (!granted && context.mounted) {
                    await _showPermissionDialog(context);
                    return;
                  }
                }
                ref.read(notificationListenerEnabledProvider.notifier).toggle(value);
              },
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('알림 자동 기록'),
              subtitle: const Text('카드·은행 결제 알림을 읽어 거래를 자동 제안합니다.'),
            ),
            permissionAsync.when(
              data: (granted) {
                if (granted) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: AppColors.income,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '알림 접근 권한이 허용되어 있습니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '알림 접근 권한이 필요해요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => NotificationChannel.openPermissionSettings(),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('권한 설정 열기'),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('알림 접근 권한 필요'),
        content: const Text(
          '카드·은행 결제 알림을 읽으려면 "알림 접근" 권한이 