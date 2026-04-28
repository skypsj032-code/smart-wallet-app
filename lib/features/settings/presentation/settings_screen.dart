import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/backup_service.dart';
import '../application/settings_provider.dart';
import '../../transactions/data/transaction_export_service.dart';
import 'lock_setup_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final sessionUnlocked = ref.watch(sessionUnlockedProvider);

    return AppScaffold(
      title: '전체',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            '자주 쓰는 화면 이동, 백업과 내보내기, 앱 잠금 설정을 여기서 한 번에 관리할 수 있습니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('빠른 이동'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsGroup(
            children: [
              _SettingsListTile(
                icon: Icons.search_rounded,
                color: AppColors.primary,
                title: '거래 검색',
                subtitle: null,
                onTap: () => context.go('/search'),
              ),
              _SettingsListTile(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                title: '자산 관리',
                subtitle: null,
                onTap: () => context.go('/accounts'),
              ),
              _SettingsListTile(
                icon: Icons.savings_outlined,
                color: AppColors.primary,
                title: '예산 관리',
                subtitle: null,
                onTap: () => context.go('/budgets'),
              ),
              _SettingsListTile(
                icon: Icons.document_scanner_outlined,
                color: AppColors.primary,
                title: '영수증 스캔',
                subtitle: null,
                onTap: () => context.go('/ocr-capture'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('데이터 관리'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsGroup(
            children: [
              _SettingsListTile(
                icon: Icons.file_upload_outlined,
                color: AppColors.primary,
                title: 'JSON 백업 만들기',
                subtitle: null,
                onTap: () => _exportBackup(context, ref),
              ),
              _SettingsListTile(
                icon: Icons.file_download_outlined,
                color: AppColors.primary,
                title: '백업 복원',
                subtitle: null,
                onTap: () => _restoreBackup(context, ref),
              ),
              _SettingsListTile(
                icon: Icons.table_view_outlined,
                color: AppColors.primary,
                title: 'CSV 내보내기',
                subtitle: null,
                onTap: () => _exportCsv(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('보안'),
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
                child: Text('잠금 설정을 불러오지 못했습니다: $error'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('앱 설정'),
          const SizedBox(height: AppSpacing.sm),
          appSettingsAsync.when(
            data: (settings) => _SettingsGroup(
              children: [
                _ThemeModeTile(
                  currentMode: settings.themeMode,
                  onChanged: (mode) => _updateThemeMode(context, ref, settings, mode),
                ),
              ],
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
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
          title: const Text('앱 잠금 끄기'),
          content: const Text(
            'PIN 잠금을 끄면 다음부터는 추가 인증 없이 앱이 열립니다. 계속할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('끄기'),
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
            '포함된 항목\n'
            '- 거래 ${payload.summary.transactionCount}건\n'
            '- 카테고리 ${payload.summary.categoryCount}개\n'
            '- 예산 ${payload.summary.budgetCount}개\n'
            '- 계좌 ${payload.summary.accountCount}개\n\n'
            '이 파일은 구글 드라이브, 카카오톡, 메일 같은 다른 앱으로 바로 보낼 수 있습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(backupServiceProvider).shareBackupFile(
                    file,
                    text: '공유 시트에서 구글 드라이브를 선택해 백업 파일을 저장하세요.',
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
      final preview = backupService.inspectJsonBackup(jsonStr);

      if (!context.mounted) {
        return;
      }

      final shouldRestore = await _confirmRestore(context, preview, fileInfo.path);
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
          title: const Text('백업을 복원할까요?'),
          content: SingleChildScrollView(
            child: Text(
              '복원을 시작하면 현재 데이터가 선택한 백업 내용으로 바뀝니다.\n'
              '그 전에 현재 상태를 안전 백업으로 한 번 더 저장합니다.\n'
              '안전 백업을 만들지 못하면 복원은 시작되지 않습니다.\n\n'
              '파일: $filePath\n'
              '백업 버전: ${preview.backupVersion}\n'
              '스키마 버전: ${preview.schemaVersion}\n'
              '앱 버전: ${preview.appVersion}\n'
              '생성 시각: ${preview.createdAt.toLocal()}\n\n'
              '포함된 항목\n'
              '- 거래 ${preview.summary.transactionCount}건\n'
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
        title: const Text('복원을 중단했습니다'),
        content: Text(
          '안전 백업을 만들지 못해서 복원을 시작하지 않았습니다.\n\n'
          '현재 데이터는 그대로 유지되었습니다.\n'
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
        title: const Text('복원이 끝났습니다'),
        content: SingleChildScrollView(
          child: Text(
            '복원 전에 현재 상태를 안전 백업으로 저장했습니다.\n\n'
            '안전 백업 위치: ${safetyBackup.file.path}\n'
            '안전 백업 파일명: ${safetyBackup.payload.fileName}\n\n'
            '복원된 항목\n'
            '- 거래 ${summary.transactionCount}건\n'
            '- 카테고리 ${summary.categoryCount}개\n'
            '- 예산 ${summary.budgetCount}개\n'
            '- 계좌 ${summary.accountCount}개\n\n'
            '안전 백업 파일을 보관해 두세요.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(backupServiceProvider).shareBackupFile(
                    safetyBackup.file,
                    text: 'Smart Wallet 복원 전에 자동으로 만든 안전 백업 파일입니다.',
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
            '복원은 끝나지 않았지만, 시작 전에 만든 안전 백업 파일은 남아 있습니다.\n\n'
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
                    text: 'Smart Wallet 복원 실패 전에 자동으로 만든 안전 백업 파일입니다.',
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
    final payload =
        await ref.read(transactionExportServiceProvider).exportTransactionsCsv();
    final file = await ref.read(transactionExportServiceProvider).saveCsvFile(payload);

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CSV 파일을 만들었습니다'),
        content: SingleChildScrollView(
          child: Text(
            '파일 이름: ${payload.fileName}\n'
            '저장 위치: ${file.path}\n\n'
            '내보낸 행 수: ${payload.rowCount}\n'
            '거래 내역을 CSV 파일로 저장했습니다.\n\n'
            '이 파일은 구글 드라이브, 카카오톡, 메일 같은 다른 앱으로 바로 보낼 수 있습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(transactionExportServiceProvider).shareCsvFile(
                    file,
                    text: '공유 시트에서 구글 드라이브를 선택해 CSV 파일을 저장하세요.',
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
              title: const Text('PIN 잠금'),
              subtitle: Text(
                enabled
                    ? '앱을 다시 열면 4자리 PIN을 입력해야 합니다.'
                    : '기기 안에서만 쓰는 로컬 PIN으로 앱을 보호합니다.',
              ),
            ),
            Text(
              enabled
                  ? sessionUnlocked
                      ? '현재 상태: 이번 세션은 잠금 해제됨'
                      : '현재 상태: 잠김, 다음 화면에서 PIN이 필요함'
                  : 'PIN 정보는 기기 안에만 저장됩니다. 아직 생체인증은 지원하지 않습니다.',
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
                '지금 켜더라도 현재 세션은 바로 잠기지 않고, 앱을 다시 열 때부터 적용됩니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  const _SettingsListTile({
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
        '화면 테마',
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
        return '항상 밝은 화면으로 표시합니다.';
      case 'dark':
        return '항상 어두운 화면으로 표시합니다.';
      default:
        return '기기 설정에 따라 자동으로 전환됩니다.';
    }
  }
}
