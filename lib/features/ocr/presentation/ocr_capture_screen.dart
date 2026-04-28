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

class _OcrCaptureScreenState extends ConsumerState<OcrCaptureScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    if (isOcrPlatformSupported) {
      _setupCamera();
      return;
    }

    _initializing = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (backCamera.isEmpty) {
        setState(() {
          _cameraError = 'A back camera is required to capture receipts.';
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
        _cameraError = 'The camera preview could not be opened. $error';
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
      title: 'Capture Receipt',
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
                      title: 'Capture',
                      status: draft.hasImage ? 'Saved photo ready' : 'Point camera at receipt',
                      isActive:
                          draft.status == OcrFlowStatus.idle || draft.status == OcrFlowStatus.capturing,
                      isDone: draft.hasImage,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FlowStageCard(
                      step: '2',
                      title: 'Extract',
                      status: draft.hasRawText ? 'Text extracted' : 'Run OCR on capture',
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
                      title: 'Review',
                      status: canOpenReview ? 'Ready to correct' : 'Review after OCR',
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
                                              'Confidence ${draft.confidence!.toStringAsFixed(2)}',
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
                    label: Text(hasDraft ? 'Clear Draft' : 'Reset View'),
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
                          ? 'Processing...'
                          : hasDraft
                              ? 'Retake Receipt'
                              : 'Capture Receipt',
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
                label: const Text('Retry OCR From Saved Photo'),
              ),
            ],
            if (canOpenReview) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go('/ocr-review'),
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(
                  draft.errorMessage != null ? 'Open Review And Fix' : 'Continue To Review',
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
      return 'OCR needs help';
    }

    if (draft.status == OcrFlowStatus.reviewRequired) {
      return 'Capture complete';
    }

    if (draft.status == OcrFlowStatus.capturing) {
      return 'Processing receipt';
    }

    return 'Capture a clean receipt photo';
  }

  String _bannerMessage(OcrDraftState draft) {
    if (_cameraError != null) {
      return 'Camera preview is unavailable. You can still reopen an existing OCR draft if one was already captured.';
    }

    if (draft.status == OcrFlowStatus.failed) {
      return draft.errorMessage ??
          'The last OCR pass did not finish cleanly. Retake the receipt, retry OCR on the saved image, or open review to finish manually.';
    }

    if (draft.status == OcrFlowStatus.reviewRequired) {
      return 'The receipt draft is ready for review. Open the next step to confirm merchant, amount, and category before creating the transaction.';
    }

    if (draft.hasImage && !draft.hasRawText) {
      return 'A receipt photo is already saved. You can retry OCR without retaking the photo, or capture again if the frame was unclear.';
    }

    return 'Align the receipt inside the frame, keep edges visible, and avoid glare. After capture, OCR will open the review step so you can correct anything before continuing.';
  }

  String _previewMessage(OcrDraftState draft) {
    if (draft.errorMessage != null) {
      return draft.errorMessage!;
    }

    if (draft.rawText.isNotEmpty) {
      return draft.rawText;
    }

    if (draft.hasImage) {
      return 'Saved photo ready. Run OCR again or continue to review once you are satisfied with the capture.';
    }

    return 'A short OCR preview will appear here after capture.';
  }

  String _statusLabel(OcrFlowStatus status) {
    switch (status) {
      case OcrFlowStatus.idle:
        return 'Ready';
      case OcrFlowStatus.capturing:
        return 'Capturing / OCR';
      case OcrFlowStatus.extracted:
        return 'Text extracted';
      case OcrFlowStatus.parsed:
        return 'Refreshing suggestion';
      case OcrFlowStatus.reviewRequired:
        return 'Needs review';
      case OcrFlowStatus.failed:
        return 'Needs retry';
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
            'Current draft',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SnapshotChip(
                icon: Icons.image_outlined,
                label: draft.hasImage ? 'Photo saved' : 'No photo',
              ),
              _SnapshotChip(
                icon: Icons.storefront_outlined,
                label: draft.storeName?.trim().isNotEmpty ?? false
                    ? draft.storeName!
                    : 'Merchant pending',
              ),
              _SnapshotChip(
                icon: Icons.payments_outlined,
                label: draft.amount != null ? '${draft.amount} won' : 'Amount pending',
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
      title: 'Capture Receipt',
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
                    'OCR is not available on this platform',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The current app target is $platformLabel. Receipt capture and on-device OCR are only enabled on Android and iOS.',
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
                      'What you can do instead',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Run the app on Android or iOS if you need camera OCR.'),
                    const SizedBox(height: AppSpacing.xs),
                    const Text('Use quick entry on desktop or web to record the transaction manually.'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.go('/quick-entry'),
              icon: const Icon(Icons.keyboard_alt_outlined),
              label: const Text('Open Quick Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
