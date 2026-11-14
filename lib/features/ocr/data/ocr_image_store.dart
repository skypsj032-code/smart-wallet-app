import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns only randomly named copies in this app's dedicated receipt cache.
class OcrImageStore {
  OcrImageStore({Future<Directory> Function()? cacheDirectory})
      : _cacheDirectory = cacheDirectory ?? getTemporaryDirectory;

  final Future<Directory> Function() _cacheDirectory;
  static const _directoryName = 'ocr_receipts';
  static final _receiptName = RegExp(r'^receipt_[0-9a-f]{32}\.jpg$');
  static final _androidCameraName = RegExp(r'^CAP[0-9]+\.jpg$');
  static final _iosCameraName = RegExp(
    r'^CAP_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(?:jpg|heif)$',
    caseSensitive: false,
  );

  Future<String> _ownedRoot() async {
    final base = await _cacheDirectory();
    await base.create(recursive: true);
    final root = Directory(p.join(base.path, _directoryName));
    var type = await FileSystemEntity.type(root.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await root.create();
      type = await FileSystemEntity.type(root.path, followLinks: false);
    }
    if (type != FileSystemEntityType.directory) {
      throw const FileSystemException('Invalid OCR cache directory');
    }
    final canonicalBase = p.normalize(await base.resolveSymbolicLinks());
    final canonicalRoot = p.normalize(await root.resolveSymbolicLinks());
    if (!p.equals(canonicalRoot, p.join(canonicalBase, _directoryName))) {
      throw const FileSystemException('OCR cache directory leaves app cache');
    }
    return canonicalRoot;
  }

  Future<String> importCapturedImage(
    String sourcePath, {
    bool fromCameraCapture = false,
  }) async {
    final root = await _ownedRoot();
    final random = Random.secure();
    final token = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    final target = File(p.join(root, 'receipt_$token.jpg'));
    await target.create(exclusive: true);
    try {
      await File(sourcePath).copy(target.path);
      if (fromCameraCapture) await _deleteCameraOriginal(sourcePath);
      return target.path;
    } catch (_) {
      await deleteOwnedImage(target.path);
      rethrow;
    }
  }

  /// Only the immediate camera result is eligible, never a restored path.
  Future<void> _deleteCameraOriginal(String sourcePath) async {
    try {
      if (!p.isAbsolute(sourcePath) || p.split(sourcePath).contains('..')) return;
      final base = await _cacheDirectory();
      final basePath = p.normalize(p.absolute(base.path));
      final source = p.normalize(sourcePath);
      final name = p.basename(source);
      final parent = p.dirname(source);
      final iosParent = p.join(basePath, 'camera', 'pictures');
      final isAndroidCapture = p.equals(parent, basePath) && _androidCameraName.hasMatch(name);
      final isIosCapture = p.equals(parent, iosParent) && _iosCameraName.hasMatch(name);
      if (!isAndroidCapture && !isIosCapture) return;

      if (isIosCapture) {
        for (final directory in [p.join(basePath, 'camera'), iosParent]) {
          if (await FileSystemEntity.type(directory, followLinks: false) !=
              FileSystemEntityType.directory) return;
        }
      }
      if (await FileSystemEntity.type(source, followLinks: false) != FileSystemEntityType.file) {
        return;
      }
      final canonicalBase = p.normalize(await base.resolveSymbolicLinks());
      final canonicalSource = p.normalize(await File(source).resolveSymbolicLinks());
      final expected = isAndroidCapture
          ? p.join(canonicalBase, name)
          : p.join(canonicalBase, 'camera', 'pictures', name);
      if (!p.equals(canonicalSource, expected)) return;
      await File(source).delete();
    } catch (error, stackTrace) {
      // An unavailable or unverifiable original must never prevent OCR.
      debugPrint('Could not remove OCR camera original: $error\n$stackTrace');
    }
  }

  /// Values loaded from a backup are untrusted, even if they look like paths.
  Future<String?> validateOwnedPath(String? imagePath) async {
    if (imagePath == null || !p.isAbsolute(imagePath)) return null;
    final root = await _ownedRoot();
    final candidate = p.normalize(imagePath);
    if (!p.equals(p.dirname(candidate), root) ||
        !_receiptName.hasMatch(p.basename(candidate))) return null;
    if (await FileSystemEntity.type(candidate, followLinks: false) != FileSystemEntityType.file) {
      return null;
    }
    try {
      final resolved = p.normalize(await File(candidate).resolveSymbolicLinks());
      return p.equals(resolved, candidate) && p.equals(p.dirname(resolved), root)
          ? resolved
          : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> deleteOwnedImage(String? imagePath) async {
    try {
      final ownedPath = await validateOwnedPath(imagePath);
      if (ownedPath != null) await File(ownedPath).delete();
    } catch (error, stackTrace) {
      debugPrint('Failed to delete OCR cache image: $error\n$stackTrace');
    }
  }
}

final ocrImageStoreProvider = Provider<OcrImageStore>((ref) => OcrImageStore());
