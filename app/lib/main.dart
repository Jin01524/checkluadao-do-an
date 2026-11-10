import 'package:flutter/material.dart';

import 'app/checkluadao_app.dart';
import 'core/legacy_scan_cleanup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clearLegacyScanHistory();
  runApp(const CheckLuaDaoApp());
}
