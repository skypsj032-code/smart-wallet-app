import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:smart_wallet_app/features/ocr/data/ocr_image_store.dart';

void main() {
  late Directory temp;
  late OcrImageStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ocr_owned_images');
    store = OcrImageStore(cacheDirectory: () async => temp);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('촬영 이미지는 전용 캐시에 복사하고 그 복사본만 삭제한다', () async {
    final source = File(p.join(temp.path, 'camera-original.jpg'));
    await source.writeAsString('receipt');

    final ownedPath = await store.importCapturedImage(source.path);
    expect(ownedPath, isNot(source.path));
    expect(await store.validateOwnedPath(ownedPath), ownedPath);
    await store.deleteOwnedImage(ownedPath);

    expect(await File(ownedPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test('앱 캐시에서 카메라가 방금 만든 원본은 복사 성공 후 정리한다', () async {
    final source = File(p.join(temp.path, 'CAP1234567890.jpg'));
    await source.writeAsString('camera receipt');

    final ownedPath = await store.importCapturedImage(
      source.path,
      fromCameraCapture: true,
    );

    expect(await File(ownedPath).readAsString(), 'camera receipt');
    expect(await source.exists(), isFalse);
  });

  test('앱 캐시의 iOS 카메라 사진 폴더에 있는 원본도 정리한다', () async {
    final pictures = Directory(p.join(temp.path, 'camera', 'pictures'));
    await pictures.create(recursive: true);
    final source = File(p.join(pictures.path, 'CAP_12345678-1234-1234-1234-123456789abc.jpg'));
    await source.writeAsString('camera receipt');

    final ownedPath = await store.importCapturedImage(source.path, fromCameraCapture: true);

    expect(await File(ownedPath).readAsString(), 'camera receipt');
    expect(await source.exists(), isFalse);
  });

  test('캐시 안에 있어도 카메라 출처가 확인되지 않으면 원본을 보존한다', () async {
    final source = File(p.join(temp.path, 'CAP1234567890.jpg'));
    await source.writeAsString('unverified');

    await store.importCapturedImage(source.path);

    expect(await source.readAsString(), 'unverified');
  });

  test('외부 파일은 카메라 이름을 사용해도 원본을 삭제하지 않는다', () async {
    final outside = await Directory.systemTemp.createTemp('ocr_external_source');
    addTearDown(() => outside.delete(recursive: true));
    final source = File(p.join(outside.path, 'CAP1234567890.jpg'));
    await source.writeAsString('external');

    final ownedPath = await store.importCapturedImage(source.path, fromCameraCapture: true);

    expect(await File(ownedPath).readAsString(), 'external');
    expect(await source.readAsString(), 'external');
  });

  test('원본 복사에 실패하면 원본 정리를 수행하지 않는다', () async {
    final source = File(p.join(temp.path, 'CAP1234567890.jpg'));
    await expectLater(
      store.importCapturedImage(source.path, fromCameraCapture: true),
      throwsA(isA<FileSystemException>()),
    );
    final ownedDir = Directory(p.join(temp.path, 'ocr_receipts'));
    expect(await ownedDir.list().toList(), isEmpty);
  });

  test('캐시의 카메라 이름이 외부 파일 링크면 링크와 외부 파일을 보존한다', () async {
    final outside = await Directory.systemTemp.createTemp('ocr_external_link');
    addTearDown(() => outside.delete(recursive: true));
    final external = File(p.join(outside.path, 'important.jpg'));
    await external.writeAsString('important');
    final link = Link(p.join(temp.path, 'CAP1234567890.jpg'));
    await link.create(external.path);

    await store.importCapturedImage(link.path, fromCameraCapture: true);

    expect(await external.readAsString(), 'important');
    expect(await link.exists(), isTrue);
  }, skip: Platform.isWindows ? 'Windows 심볼릭 링크 생성 권한이 필요함' : false);

  test('카메라 사진 폴더가 외부 링크면 원본을 정리하지 않는다', () async {
    final outside = await Directory.systemTemp.createTemp('ocr_external_camera_dir');
    addTearDown(() => outside.delete(recursive: true));
    final name = 'CAP_12345678-1234-1234-1234-123456789abc.jpg';
    final external = File(p.join(outside.path, name));
    await external.writeAsString('important');
    final camera = Directory(p.join(temp.path, 'camera'));
    await camera.create();
    await Link(p.join(camera.path, 'pictures')).create(outside.path);
    final forged = p.join(camera.path, 'pictures', name);

    await store.importCapturedImage(forged, fromCameraCapture: true);

    expect(await external.readAsString(), 'important');
  }, skip: Platform.isWindows ? 'Windows 심볼릭 링크 생성 권한이 필요함' : false);

  test('백업에 외부 경로 또는 상위 디렉터리 경로가 있어도 삭제하지 않는다', () async {
    final external = File(p.join(temp.path, 'smart_wallet.sqlite'));
    await external.writeAsString('important');
    final traversal = p.join(temp.path, 'ocr_receipts', '..', 'smart_wallet.sqlite');

    expect(await store.validateOwnedPath(external.path), isNull);
    expect(await store.validateOwnedPath(traversal), isNull);
    await store.deleteOwnedImage(external.path);
    await store.deleteOwnedImage(traversal);
    expect(await external.readAsString(), 'important');
  });

  test('영수증 경로에서 외부를 가리키는 심볼릭 링크를 거부한다', () async {
    final external = File(p.join(temp.path, 'smart_wallet.sqlite'));
    await external.writeAsString('important');
    final ownedDir = Directory(p.join(temp.path, 'ocr_receipts'));
    await ownedDir.create();
    final link = Link(p.join(ownedDir.path, 'receipt_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.jpg'));
    await link.create(external.path);

    expect(await store.validateOwnedPath(link.path), isNull);
    await store.deleteOwnedImage(link.path);
    expect(await external.readAsString(), 'important');
    expect(await Link(link.path).exists(), isTrue);
  }, skip: Platform.isWindows ? 'Windows 심볼릭 링크 생성 권한이 필요함' : false);

  test('전용 캐시 폴더 자체가 외부 폴더의 링크면 파일을 삭제하지 않는다', () async {
    final externalDir = Directory(p.join(temp.path, 'external'));
    await externalDir.create();
    final external = File(p.join(externalDir.path, 'receipt_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.jpg'));
    await external.writeAsString('important');
    await Link(p.join(temp.path, 'ocr_receipts')).create(externalDir.path);
    final forged = p.join(temp.path, 'ocr_receipts', p.basename(external.path));

    await expectLater(store.validateOwnedPath(forged), throwsA(isA<FileSystemException>()));
    await store.deleteOwnedImage(forged);
    expect(await external.readAsString(), 'important');
  }, skip: Platform.isWindows ? 'Windows 심볼릭 링크 생성 권한이 필요함' : false);
}
