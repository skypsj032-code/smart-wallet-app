import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_mood.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/widgets/app_brand_mark.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../application/device_auth.dart';
import '../application/pin_security.dart';
import '../application/settings_provider.dart';
import 'lock_setup_dialog.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  String _input = '';
  int _failedAttempts = 0;
  String? _message;
  bool _messageIsError = false;
  DateTime? _cooldownUntil;
  Timer? _cooldownTimer;
  bool _unlockScheduled = false;
  bool _recovering = false;
  bool _recoverySetupActive = false;
  int _recoveryGeneration = 0;
  String? _recoveryMessage;
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
    WidgetsBinding.instance.addObserver(this);
    _keyboardFocusNode = FocusNode(debugLabel: 'lock_screen_keyboard');
    _shuffledDigits = List<int>.generate(10, (i) => i)..shuffle();
  }

  @override
  void dispose() {
    _recoveryGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    if (_recovering && !_recoverySetupActive) {
      unawaited(const DeviceAuth().cancel());
    }
    _cooldownTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    final settings = ref.read(appSettingsProvider).asData?.value;
    if (_input.length >= 4 ||
        _isCoolingDown ||
        _recovering ||
        settings == null ||
        !settings.appLockEnabled ||
        settings.pinCode == null) {
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

      final settings = ref.read(appSettingsProvider).asData?.value;
      if (settings == null || settings.appLockEnabled) {
        _unlockScheduled = false;
        return;
      }
      ref.read(sessionUnlockedProvider.notifier).state = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The system credential UI can suspend the app, so an auth request is
    // owned by Android until its result arrives. Once PIN setup begins, loss
    // of foreground focus expires the one-use recovery approval.
    if (_recoverySetupActive &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      _recoveryGeneration++;
      _recoverySetupActive = false;
    }
  }

  bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  Future<void> _recoverPin() async {
    final initialSettings = ref.read(appSettingsProvider).asData?.value;
    if (_recovering ||
        initialSettings == null ||
        !initialSettings.appLockEnabled ||
        initialSettings.pinCode != null ||
        !_isForeground) {
      return;
    }

    final generation = ++_recoveryGeneration;
    setState(() {
      _recovering = true;
      _recoveryMessage = null;
    });

    try {
      final outcome = await const DeviceAuth().authenticate();
      if (!mounted || generation != _recoveryGeneration) return;

      if (outcome != DeviceAuthResult.success) {
        setState(() {
          _recoveryMessage = switch (outcome) {
            DeviceAuthResult.notConfigured =>
              '휴대폰에 화면 잠금을 설정한 뒤 다시 시도해 주세요.',
            DeviceAuthResult.unsupported =>
              '이 기기에서는 PIN 복구를 지원하지 않습니다.',
            DeviceAuthResult.cancelled => '인증이 취소되었습니다. 다시 시도할 수 있습니다.',
            _ => '휴대폰 잠금을 확인하지 못했습니다. 다시 시도해 주세요.',
          };
        });
        return;
      }

      // Native Android delivers success only after this activity is resumed
      // and focused. If Flutter is not foregrounded too, fail closed.
      if (!_isForeground) return;
      _recoverySetupActive = true;

      final db = ref.read(appDatabaseProvider);
      final current = await db.select(db.appSettings).getSingleOrNull();
      if (!mounted ||
          generation != _recoveryGeneration ||
          !_isForeground ||
          current == null ||
          !current.appLockEnabled ||
          current.pinCode != null) {
        return;
      }

      final configured = await LockSetupDialog.show(
        context,
        isRecoveringPin: true,
        isRecoveryAuthorized: () =>
            mounted &&
            _recoverySetupActive &&
            generation == _recoveryGeneration &&
            _isForeground,
      );
      if (mounted && configured == true && generation == _recoveryGeneration) {
        setState(() {
          _message = '새로 설정한 PIN을 입력해 주세요.';
          _messageIsError = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _recoveryGeneration) {
        setState(() {
          _recoveryMessage = 'PIN을 복구하지 못했습니다. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _recoverySetupActive = false;
          _recovering = false;
        });
      }
    }
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

  Future<void> _verify() async {
    final settings = ref.read(appSettingsProvider).asData?.value;
    if (settings == null) {
      if (_input.isNotEmpty) {
        setState(() => _input = '');
      }
      return;
    }
    final pinCode = settings.pinCode;

    if (pinCode == null) {
      if (_input.isNotEmpty) {
        setState(() => _input = '');
      }
      return;
    }

    final verification = verifyStoredPin(_input, pinCode);
    if (verification.isValid) {
      _cooldownTimer?.cancel();
      ref.read(sessionUnlockedProvider.notifier).state = true;
      if (verification.needsUpgrade) {
        await migrateLegacyPinHash(
          database: ref.read(appDatabaseProvider),
          pin: _input,
          previousHash: pinCode,
        );
      }
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
      if (mounted &&
          !_recovering &&
          ref.read(appSettingsProvider).asData?.value.pinCode != null &&
          !_keyboardFocusNode.hasFocus) {
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
              if (!settings.appLockEnabled) {
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

              if (settings.pinCode == null) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '앱 PIN을 복구해 주세요.',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            '앱 잠금이 켜져 있지만 PIN을 찾을 수 없습니다. '
                            '휴대폰의 PIN, 패턴 또는 비밀번호를 확인한 뒤 '
                            '새 앱 PIN을 설정할 수 있습니다. 기록은 그대로 유지됩니다.',
                            textAlign: TextAlign.center,
                          ),
                          if (_recoveryMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(_recoveryMessage!, textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: _recovering ? null : _recoverPin,
                            child: const Text('휴대폰 잠금으로 PIN 복구'),
                          ),
                        ],
                      ),
                    ),
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
                        SizedBox(
                            height: isCompactHeight
                                ? AppSpacing.xs
                                : AppSpacing.sm),
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
                        SizedBox(
                            height: isCompactHeight
                                ? AppSpacing.xs
                                : AppSpacing.sm),
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
                        SizedBox(
                            height: isCompactHeight
                                ? AppSpacing.sm
                                : AppSpacing.md),
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
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text(
                              '이번 세션의 실패 횟수: $_failedAttempts회',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        SizedBox(
                            height: isCompactHeight
                                ? AppSpacing.xs
                                : AppSpacing.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // 키패드 너비: 가용 너비 기준으로 최대 260px로 제한
                            final keypadWidth = math.min(
                              constraints.maxWidth,
                              260.0,
                            );
                            const gap = 10.0;
                            const cols = 3;
                            final btnWidth =
                                (keypadWidth - gap * (cols - 1)) / cols;
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
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    child: Center(
                                      child: Icon(
                                        Icons.backspace_outlined,
                                        size: 22,
                                        color: _isCoolingDown
                                            ? theme.disabledColor
                                            : theme
                                                .colorScheme.onSurfaceVariant,
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
