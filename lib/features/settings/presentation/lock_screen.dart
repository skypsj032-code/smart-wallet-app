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

  // 보안 랜덤 키패드: 0~9를 무작위 배치
  List<int> _shuffledDigits = [];

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
    _shuffledDigits = List<int>.generate(10, (i) => i)..shuffle();
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

    final newInput = _input + digit;
    final digits = List<int>.generate(10, (i) => i)..shuffle();
    setState(() {
      _input = newInput;
      _shuffledDigits = digits;
      _message = null;
      _messageIsError = false;
    });

    if (newInput.length == 4) {
      _verify();
    }
  }

  void _onDelete() {
    if (_input.isEmpty || _isCoolingDown) {
      return;
    }

    final digits = List<int>.generate(10, (i) => i)..shuffle();
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _shuffledDigits = digits;
      _message = null;
      _messageIsError = false;
    });
  }

  void _clearInput() {
    if (_input.isEmpty || _isCoolingDown) {
      return;
    }

    final digits = List<int>.generate(10, (i) => i)..shuffle();
    setState(() {
      _input = '';
      _shuffledDigits = digits;
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
          _message = '다시 입력하세요.';
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

    final digits = List<int>.generate(10, (i) => i)..shuffle();
    setState(() {
      _failedAttempts = failedAttempts;
      _input = '';
      _shuffledDigits = digits;
      _message = cooldownDuration == null ? 'PIN이 맞지 않습니다.' : '잠시 후 다시 시도하세요.';
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
    final theme = Theme.of(context);
    final mood = Theme.of(context).extension<AppMood>()!;
    final helperText = _isCoolingDown
        ? '$_cooldownSecondsRemaining초 후 다시 시도하세요.'
        : (_message ?? 'PIN 4자리를 입력해 주세요.');
    final helperStyle = theme.textTheme.bodySmall?.copyWith(
      color: _messageIsError
          ? AppColors.expense
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
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

              final screenSize = MediaQuery.sizeOf(context);
              final isCompactHeight = screenSize.height < 700;

              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: isCompactHeight ? AppSpacing.xs : AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppStatusChip(
                          label: 'SAFE WALLET',
                          dotColor: mood.lockedAccent,
                        ),
                        SizedBox(height: isCompactHeight ? AppSpacing.xs : AppSpacing.sm),
                        Container(
                          width: isCompactHeight ? 56 : 72,
                          height: isCompactHeight ? 56 : 72,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border:
                                Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Center(
                            child: AppBrandMark(
                              size: isCompactHeight ? 34 : 44,
                              withBadge: true,
                            ),
                          ),
                        ),
                        SizedBox(height: isCompactHeight ? AppSpacing.xs : AppSpacing.sm),
                        Text(
                          '지갑 열기',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'PIN으로 잠금을 해제해 주세요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isCompactHeight ? AppSpacing.sm : AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < _input.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isFilled
                                    ? mood.lockedAccent
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _messageIsError
                                      ? AppColors.expense
                                      : mood.lockedAccent,
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          height: 28,
                          child: Center(
                            child: Text(
                              helperText,
                              style: helperStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (_failedAttempts > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text(
                              '이번 세션의 실패 횟수: $_failedAttempts회',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        SizedBox(height: isCompactHeight ? AppSpacing.xs : AppSpacing.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // 키패드 너비: 가용 너비 기준으로 최대 260px로 제한
                            final keypadWidth = math.min(
                              constraints.maxWidth,
                              260.0,
                            );
                            const gap = 10.0;
                            const cols = 3;
                            final btnWidth = (keypadWidth - gap * (cols - 1)) / cols;
                            final btnHeight = btnWidth * 0.75;

                            return SizedBox(
                              width: keypadWidth,
                              child: GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: cols,
                                mainAxisSpacing: gap,
                                crossAxisSpacing: gap,
                                childAspectRatio: btnWidth / btnHeight,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  // 0~8번 슬롯: 셔플된 10개 숫자 중 앞 9개
                                  for (var i = 0; i < 9; i++)
                                    _LockKey(
                                      label: _shuffledDigits[i].toString(),
                                      enabled: !_isCoolingDown,
                                      onTap: () => _onDigit(
                                        _shuffledDigits[i].toString(),
                                      ),
                                    ),
                                  // 빈 슬롯 (왼쪽 하단)
                                  const SizedBox.shrink(),
                                  // 9번 슬롯: 셔플된 마지막 숫자
                                  _LockKey(
                                    label: _shuffledDigits[9].toString(),
                                    enabled: !_isCoolingDown,
                                    onTap: () => _onDigit(
                                      _shuffledDigits[9].toString(),
                                    ),
                                  ),
                                  // 백스페이스 (오른쪽 하단 고정)
                                  InkWell(
                                    onTap: _isCoolingDown ? null : _onDelete,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    child: Center(
                                      child: Icon(
                                        Icons.backspace_outlined,
                                        size: 22,
                                        color: _isCoolingDown
                                            ? theme.disabledColor
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: _isCoolingDown ? null : _clearInput,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text('모두 지우기'),
                        ),
                      ],
                    ),
                  ),
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
