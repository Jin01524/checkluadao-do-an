import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';

const maxScanImages = 5;
const maxImageBytes = 10 * 1024 * 1024;

class PreparedScanImage {
  const PreparedScanImage({required this.bytes, required this.originalName});
  final Uint8List bytes;
  final String originalName;

  ScanImage toUpload(int index) =>
      ScanImage(bytes: bytes, name: 'scan_${index + 1}.jpg');
}

Future<PreparedScanImage> prepareImage(XFile file) async {
  final length = await file.length();
  if (length > maxImageBytes) {
    throw FormatException(
      'Ảnh ${file.name} vượt quá 10 MB. Hãy chọn ảnh nhỏ hơn.',
    );
  }
  final original = await file.readAsBytes();
  final output = await compute(_encodeJpeg, original);
  if (output == null) {
    throw FormatException(
      'Không đọc được ${file.name}. Hãy chọn ảnh JPEG/PNG/WebP hoặc chụp lại ảnh.',
    );
  }
  if (output.length > maxImageBytes) {
    throw FormatException('Ảnh ${file.name} vẫn vượt quá 10 MB sau khi xử lý.');
  }
  return PreparedScanImage(bytes: output, originalName: file.name);
}

Uint8List? _encodeJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var normalized = img.bakeOrientation(decoded);
  if (normalized.width > 1920) {
    normalized = img.copyResize(
      normalized,
      width: 1920,
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(normalized, quality: 88));
}
