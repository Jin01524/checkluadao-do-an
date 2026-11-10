import 'dart:typed_data';

import 'package:app_checkluadao_ttnt/features/scan/image_preparation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  test('PNG is converted to JPEG for backend multipart upload', () async {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 3, height: 2)),
    );
    final prepared = await prepareImage(
      XFile.fromData(png, name: 'message.png'),
    );
    expect(prepared.bytes.take(3), [0xFF, 0xD8, 0xFF]);
    expect(prepared.toUpload(0).name, 'scan_1.jpg');
  });

  test('original images above backend 10 MB limit are rejected', () async {
    final tooLarge = Uint8List(maxImageBytes + 1);
    expect(
      () => prepareImage(XFile.fromData(tooLarge, name: 'large.png')),
      throwsA(isA<FormatException>()),
    );
  });
}
