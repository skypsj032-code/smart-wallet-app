import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/platform/ocr_platform_support.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/ocr_capture_provider.dart';

class OcrCaptureScreen extends ConsumerStatefulWidget {
  const OcrCaptureScreen({super.key});

  @override
  ConsumerState<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends ConsumerState<OcrCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (isOcrPlatformSupported) {
      _setupCamera();
      return;
    }

    _initializing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      controller.resumePreview();
    }
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (backCamera.isEmpty) {
        setState(() {
          _cameraError = '후면 카메라가 필요합니다.';
          _initializing = false;
        });
        return;
      }

      final controller = CameraController(
        backCamera.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (error) {
      setState(() {
        _cameraError = '카메라를 열 수 없습니다. $error';
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isOcrPlatformSupported) {
      return const _UnsupportedOcrCaptureScreen();
    }

    final draft = ref.watch(ocrCaptureProvider);
    final isBusy = draft.status == OcrFlowStatus.capturing;
    final hasDraft = draft.hasImage || draft.hasRawText || draft.hasParsedAmount;
    final canOpenReview = !isBusy &&
        (draft.status == OcrFlowStatus.reviewRequired ||
            draft.status == OcrFlowStatus.failed ||
            draft.hasRawText ||
            draft.hasParsedStoreName ||
            draft.hasParsedAmount);
    final canRetrySavedCapture = !isBusy && draft.hasImage;

    return AppScaffold(
      title: '영수증 스캔',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CaptureBanner(
              title: _bannerTitle(draft),
              message: _bannerMessage(draft),
              tone: draft.errorMessage != null || draft.status == OcrFlowStatus.failed
                  ? _CaptureBannerTone.warning
                  : _CaptureBannerTone.normal,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 92,
              child: Row(
                children: [
                  Expanded(
                    child: _FlowStageCard(
                      step: '1',
                      title: '촬영',
                      status: draft.hasImage ? '사진 저장됨' : '영수증에 카메라를 맞춰주세요',
                      isActive:
                          draft.status == OcrFlowStatus.idle || draft.status == OcrFlowStatus.capturing,
                      isDone: draft.hasImage,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FlowStageCard(
                      step: '2',
                      title: '추출',
                      status: draft.hasRawText ? '텍스트 추출 완료' : 'OCR 대기 중',
                      isActive: draft.status == OcrFlowStatus.capturing ||
                          draft.status == OcrFlowStatus.extracted ||
                          draft.status == OcrFlowStatus.parsed,
                      isDone: draft.hasRawText,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FlowStageCard(
                      step: '3',
                      title: '검토',
                      status: canOpenReview ? '검토 준비됨' : 'OCR 후 검토',
                      isActive: draft.status == OcrFlowStatus.reviewRequired ||
                          draft.status == OcrFlowStatus.failed,
                      isDone: draft.canContinueToQuickEntry,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ColoredBox(
                  color: Colors.black,
                  child: _initializing
                      ? const Center(child: CircularProgressIndicator())
                      : _cameraError != null
                          ? _CameraMessage(
                              icon: Icons.videocam_off_outlined,
                              message: _cameraError!,
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_controller!),
                                Positioned(
                                  top: AppSpacing.md,
                                  left: AppSpacing.md,
                                  right: AppSpacing.md,
                                  child: Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      _StatusPill(label: _statusLabel(draft.status)),
                                      if (draft.confidence != null)
                                        _StatusPill(
                                          label:
                                              '인식률 ${draft.confidence!.toStringAsFixed(2)}',
                                        ),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 260,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white70, width: 2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: AppSpacing.md,
                                  right: AppSpacing.md,
                                  bottom: AppSpacing.md,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _previewMessage(draft),
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (isBusy)
                                  const ColoredBox(
                                    color: Color(0x66000000),
                                    child: Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                ),
              ),
            ),
            if (hasDraft) ...[
              const SizedBox(height: AppSpacing.md),
              _DraftSnapshotCard(draft: draft),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () {
                            ref.read(ocrCaptureProvider.notifier).reset();
                          },
                    icon: Icon(hasDraft ? Icons.delete_outline : Icons.refresh_outlined),
                    label: Text(hasDraft ? '초안 삭제' : '초기화'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _initializing || _cameraError != null || isBusy
                        ? null
                        : () async {
                            final router = GoRouter.of(context);
                            final controller = ref.read(ocrCaptureProvider.notifier);
                            await controller.runCaptureFlow();
                            if (!mounted) {
                              return;
                            }
                            final latestDraft = ref.read(ocrCaptureProvider);
                            if (latestDraft.status == OcrFlowStatus.reviewRequired ||
                                latestDraft.hasRawText ||
                                latestDraft.hasParsedStoreName ||
                                latestDraft.hasParsedAmount) {
                              router.go('/ocr-review');
                            }
                          },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      isBusy
                          ? '처리 중...'
                          : hasDraft
                              ? '다시 촬영'
                              : '영수증 촬영',
                    ),
                  ),
                ),
              ],
            ),
            if (canRetrySavedCapture) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  await ref.read(ocrCaptureProvider.notifier).retryFromCapturedImage();
                  if (!mounted) {
                    return;
                  }
                  final latestDraft = ref.read(ocrCaptureProvider);
                  if (latestDraft.status == OcrFlowStatus.reviewRequired ||
                      latestDraft.hasRawText ||
                      latestDraft.hasParsedAmount) {
                    router.go('/ocr-review');
                  }
                },
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('저장된 사진으로 OCR 재시도'),
              ),
            ],
            if (canOpenReview) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go('/ocr-review'),
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(
                  draft.errorMessage != null ? '검토 화면 열기' : '검토하기',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _bannerTitle(OcrDraftState draft) {
    if (draft.status == OcrFlowStatus.failed) {
      return 'OCR 실패';
    }

    if (draft.status == OcrFlowStatus.reviewRequired) {
      return '촬영 완료';
    }

    if (draft.status == OcrFlowStatus.capturing) {
      return '영수증 처리 중';
    }

    return '영수증을 촬영하세요';
  }

  String _bannerMessage(OcrDraftState draft) {
    if (_cameraError != null) {
      return '카메라 미리보기를 사용할 수 없습니다. 이미 촬영된 초안이 있다면 열 수 있어요.';
    }

    if (draft.status == OcrFlowStatus.failed) {
      return draft.errorMessage ?? 'OCR이 완료되지 않았습니다. 다시 촬영하거나 검토 화면에서 직접 입력해 주세요.';
    }

    if (draft.status == OcrFlowStatus.reviewRequired) {
      return '영수증 초안이 준비되었습니다. 검토 화면에서 상점명, 금액, 카테고리를 확인해 주세요.';
    }

    if (draft.hasImage && !draft.hasRawText) {
      return '저장된 사진이 있습니다. OCR을 재시도하거나 다시 촬영할 수 있어요.';
    }

    return '테두리 안에 영수증을 맞추고 촬영하세요.';
  }

  String _previewMessage(OcrDraftState draft) {
    if (draft.errorMessage != null) {
      return draft.errorMessage!;
    }

    if (draft.rawText.isNotEmpty) {
      return draft.rawText;
    }

    if (draft.hasImage) {
      return '사진이 저장되었습니다. OCR을 재시도하거나 검토 화면으로 이동할 수 있어요.';
    }

    return '촬영 후 OCR 결과가 여기에 표시됩니다.';
  }

  String _statusLabel(OcrFlowStatus status) {
    switch (status) {
      case OcrFlowStatus.idle:
        return '대기';
      case OcrFlowStatus.capturing:
        return '촬영 / OCR 처리 중';
      case OcrFlowStatus.extracted:
        return '텍스트 추출 완료';
      case OcrFlowStatus.parsed:
        return '추천 갱신 중';
      case OcrFlowStatus.reviewRequired:
        return '검토 필요';
      case OcrFlowStatus.failed:
        return '재시도 필요';
    }
  }
}

enum _CaptureBannerTone {
  normal,
  warning,
}

class _CaptureBanner extends StatelessWidget {
  const _CaptureBanner({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _CaptureBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == _CaptureBannerTone.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.orange.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.error_outline : Icons.camera_alt_outlined,
            color: isWarning ? Colors.orange.shade800 : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStageCard extends StatelessWidget {
  const _FlowStageCard({
    required this.step,
    required this.title,
    required this.status,
    required this.isActive,
    required this.isDone,
  });

  final String step;
  final String title;
  final String status;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final background = isDone
        ? Colors.green.withValues(alpha: 0.10)
        : isActive
            ? Colors.black.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? Colors.green.withValues(alpha: 0.24)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isDone
                    ? Colors.green.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.08),
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _DraftSnapshotCard extends StatelessWidget {
  const _DraftSnapshotCard({required this.draft});

  final OcrDraftState draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 초안',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SnapshotChip(
                icon: Icons.image_outlined,
                label: draft.hasImage ? '사진 저장됨' : '사진 없음',
              ),
              _SnapshotChip(
                icon: Icons.storefront_outlined,
                label: draft.storeName?.trim().isNotEmpty ?? false
                    ? draft.storeName!
                    : '상점명 미확인',
              ),
              _SnapshotChip(
                icon: Icons.payments_outlined,
                label: draft.amount != null ? '${draft.amount}원' : '금액 미확인',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  const _SnapshotChip({
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
        color: Colors.white,
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

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedOcrCaptureScreen extends StatelessWidget {
  const _UnsupportedOcrCaptureScreen();

  @override
  Widget build(BuildContext context) {
    final platformLabel = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.fuchsia => 'Fuchsia',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
    };

    return AppScaffold(
      title: '영수증 스캔',
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
                  const Icon(Icons.devices_outlined, size: 32),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '이 기기에서는 OCR을 사용할 수 없어요',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '현재 실행 중인 환경은 $platformLabel입니다. 영수증 촬영과 OCR은 Android, iOS에서만 지원됩니다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '대신 할 수 있는 것',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('카메라 OCR이 필요하다면 Android 또는 iOS에서 실행하세요.'),
                    const SizedBox(height: AppSpacing.xs),
                    const Text('데스크탑에서는 빠른 입력으로 거래를 직접 기록할 수 있어요.'),
                  ],
                ),
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
}
