import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Remove the history created by releases before 1.2.0 without reading it.
Future<void> clearLegacyScanHistory({Directory? directory}) async {
  final root = directory ?? await getApplicationSupportDirectory();
  final file = File(
    '${root.path}${Platform.pathSeparator}scan_history_v1.json',
  );
  if (await file.exists()) await file.delete();
}
