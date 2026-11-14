import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../application/pin_security.dart';

class LockSetupDialog extends ConsumerStatefulWidget {
  const LockSetupDialog({
    super.key,
    this.isChangingPin = false,
    this.isRecoveringPin = false,
    this.isRecoveryAuthorized,
  }) : assert(!isRecoveringPin || isRecoveryAuthorized != null);

  final bool isChangingPin;
  final bool isRecoveringPin;
  final bool Function()? isRecoveryAuthorized;

  static Future<bool?> show(
    BuildContext context, {
    bool isChangingPin = false,
    bool isRecoveringPin = false,
    bool Function()? isRecoveryAuthorized,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: LockSetupDialog(
            isChangingPin: isChangingPin,
            isRecoveringPin: isRecoveringPin,
            isRecoveryAuthorized: isRecoveryAuthorized,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LockSetupDialog> createState() => _LockSetupDialogState();
}

class _LockSetupDialogState extends ConsumerState<LockSetupDialog>
    with WidgetsBindingObserver {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocusNode = FocusNode();

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRecoveringPin) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.isRecoveringPin &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      final route = ModalRoute.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route != null && route.isActive) {
          route.navigator?.removeRoute(route);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _confirmController.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    if (_isSaving) {
      return;
    }
    if (widget.isRecoveringPin && widget.isRecoveryAuthorized?.call() != true) {
      setState(() => _error = '복구 인증이 만료되었습니다. 다시 인증해 주세요.');
      return;
    }

    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'PIN은 숫자 4자리여야 합니다.');
      return;
    }

    if (pin != confirm) {
      setState(() => _error = '두 PIN이 서로 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final db = ref.read(appDatabaseProvider);

    try {
      final settings = await db.select(db.appSettings).getSingleOrNull();
      final now = DateTime.now();

      if (widget.isRecoveringPin) {
        if (settings == null ||
            !settings.appLockEnabled ||
            settings.pinCode != null) {
          throw StateError('Lock settings changed during PIN recovery');
        }

        final hashedPin = hashPin(pin);
        if (!mounted || widget.isRecoveryAuthorized?.call() != true) {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _error = '복구 인증이 만료되었습니다. 다시 인증해 주세요.';
            });
          }
          return;
        }

        await db.transaction(() async {
          if (!mounted || widget.isRecoveryAuthorized?.call() != true) {
            throw StateError('PIN recovery authorization expired');
          }

          // Preserve all other settings and never replace a PIN set while the
          // authentication or this transaction was in progress.
          final updated = await (db.update(db.appSettings)
                ..where((table) =>
                    table.id.equals(settings.id) &
                    table.appLockEnabled.equals(true) &
                    table.pinCode.isNull()))
              .write(AppSettingsCompanion(
            pinCode: drift.Value(hashedPin),
            lastModifiedAt: drift.Value(now),
          ));
          if (updated != 1) {
            throw StateError('Lock settings changed during PIN recovery');
          }
          if (!mounted || widget.isRecoveryAuthorized?.call() != true) {
            throw StateError('PIN recovery authorization expired');
          }
        });
      } else if (settings == null) {
        await db.into(db.appSettings).insert(
              AppSettingsCompanion.insert(
                appLockEnabled: const drift.Value(true),
                pinCode: drift.Value(hashPin(pin)),
                createdAt: now,
                lastModifiedAt: now,
              ),
            );
      } else {
        await db.update(db.appSettings).replace(
              settings.copyWith(
                appLockEnabled: true,
                pinCode: drift.Value(hashPin(pin)),
                lastModifiedAt: now,
              ),
            );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _error = 'PIN을 저장하지 못했습니다. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(widget.isRecoveringPin
            ? '앱 PIN 복구'
            : widget.isChangingPin
                ? 'PIN 변경'
                : 'PIN 잠금 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isChangingPin
                  ? '새로운 4자리 PIN을 입력해 주세요.'
                  : '앱을 보호할 4자리 PIN을 설정해 주세요.',
            ),
            const SizedBox(height: 8),
            const Text(
              'PIN은 이 기기에만 저장되며 외부로 전송되지 않습니다.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              autofocus: true,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: '새 PIN',
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onSubmitted: (_) => _confirmFocusNode.requestFocus(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              focusNode: _confirmFocusNode,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'PIN 확인',
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onSubmitted: (_) => _savePin(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _savePin,
            child: Text(_isSaving ? '저장 중...' : '저장'),
          ),
        ],
      ),
    );
  }
}
