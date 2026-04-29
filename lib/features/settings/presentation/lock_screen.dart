import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_mood.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_brand_mark.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../application/settings_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _input = '';
  int _failedAttempts = 0;
  String? _message;
  bool _messageIsError = false;
  DateTime? _cooldownUntil;
  Timer? _cooldownTimer;
  bool _unlockScheduled = false;
  late final FocusNode _keyboardFocusNode;

  bool get _isCoolingDown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  int get _cooldownSecondsRemaining {
    final cooldownUntil = _cooldownUntil;
    if (cooldownUntil == null) {
      return 0;
    }

    return math.max(
      0,
      (cooldownUntil.difference(DateTime.now()).inMilliseconds / 1000).ceil(),
    );
  }

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode(debugLabel: 'lock_screen_keyboard');
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_input.length >= 4 || _isCoolingDown) {
      return;
    }

    setState(() {
      _input += digit;
      _message = null;
      _messageIsError = false;
    });

    if (_input.length == 4) {
      _verify();
    }
  }

  void _onDelete() {
    if (_input.isEmpty || _isCoolingDown) {
      return;
    }

    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _message = null;
      _messageIsError = false;
    });
  }

  void _clearInput() {
    if (_input.isEmpty || _isCoolingDown) {
      return;
    }

    setState(() {
      _input = '';
      _message = null;
      _messageIsError = false;
    });
  }

  void _scheduleUnlock() {
    if (_unlockScheduled) {
      return;
    }

    _unlockScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(sessionUnlockedProvider.notifier).state = true;
    });
  }

  void _startCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    final until = DateTime.now().add(duration);

    setState(() {
      _cooldownUntil = until;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_isCoolingDown) {
        timer.cancel();
        setState(() {
          _cooldownUntil = null;
          _message = '다시 입력할 수 있어요.';
          _messageIsError = false;
        });
        return;
      }

      setState(() {});
    });
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  void _verify() {
    final settings = ref.read(appSettingsProvider).asData?.value;
    final pinCode = settings?.pinCode;

    if (pinCode == null) {
      _scheduleUnlock();
      return;
    }

    if (pinCode == _hashPin(_input)) {
      _cooldownTimer?.cancel();
      ref.read(sessionUnlockedProvider.notifier).state = true;
      return;
    }

    final failedAttempts = _failedAttempts + 1;
    Duration? cooldownDuration;

    if (failedAttempts >= 5) {
      cooldownDuration = const Duration(seconds: 30);
    } else if (failedAttempts >= 3) {
      cooldownDuration = const Duration(seconds: 10);
    }

    setState(() {
      _failedAttempts = failedAttempts;
      _input = '';
      _message = cooldownDuration == null
          ? 'PIN이 올바르지 않습니다. 다시 시도해 주세요.'
          : '시도 횟수가 너무 많아요. 잠시 후 다시 시도해 주세요.';
      _messageIsError = true;
    });

    if (cooldownDuration != null) {
      _startCooldown(cooldownDuration);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _isCoolingDown) {
      return;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _onDelete();
      return;
    }

    if (key == LogicalKeyboardKey.escape) {
      _clearInput();
      return;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_input.length == 4) {
        _verify();
      }
      return;
    }

    final character = event.character;
    if (character != null && character.length == 1) {
      final digit = int.tryParse(character);
      if (digit != null) {
        _onDigit(digit.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final mood = Theme.of(context).extension<AppMood>()!;
    final helperText = _isCoolingDown
        ? '시도 제한 중입니다. $_cooldownSecondsRemaining초 후 다시 입력할 수 있어요.'
        : (_message ?? '앱을 다시 열려면 PIN 4자리를 입력해 주세요.');
    final helperStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _messageIsError ? AppColors.expense : Theme.of(context).colorScheme.onSurfaceVariant,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_keyboardFocusNode.hasFocus) {
        _keyboardFocusNode.requestFocus();
      }
    });

    return Scaffold(
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
        child: appSettingsAsync.when(
          data: (settings) {
            if (!settings.appLockEnabled || settings.pinCode == null) {
              _scheduleUnlock();

              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text('잠금 설정이 없어 홈으로 이동하고 있습니다.'),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  AppStatusChip(
                    label: 'LOCKED SESSION',
                    dotColor: mood.lockedAccent,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: const Center(
                      child: AppBrandMark(size: 76, withBadge: true),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '지갑을 다시 여는 중입니다',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '오늘의 기록과 잔액 흐름을 보호하기 위해 짧은 확인이 필요해요.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _input.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isFilled ? mood.lockedAccent : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _messageIsError ? AppColors.expense : mood.lockedAccent,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        helperText,
                        style: helperStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (_failedAttempts > 0)
                    Text(
                      '이번 세션의 실패 횟수: $_failedAttempts회',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 280,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _LockKey(
                            label: i.toString(),
                            enabled: !_isCoolingDown,
                            onTap: () => _onDigit(i.toString()),
                          ),
                        const SizedBox.shrink(),
                        _LockKey(
                          label: '0',
                          enabled: !_isCoolingDown,
                          onTap: () => _onDigit('0'),
                        ),
                        InkWell(
                          onTap: _isCoolingDown ? null : _onDelete,
                          borderRadius: BorderRadius.circular(40),
                          child: Center(
                            child: Icon(
                              Icons.backspace_outlined,
                              size: 28,
                              color: _isCoolingDown
                                  ? Theme.of(context).disabledColor
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _isCoolingDown ? null : _clearInput,
                    child: const Text('모두 지우기'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '잠금 설정을 불러오지 못했습니다.\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => ref.invalidate(appSettingsProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _LockKey extends StatelessWidget {
  const _LockKey({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
