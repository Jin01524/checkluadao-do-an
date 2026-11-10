import 'package:flutter/material.dart';

import 'dart:async';

import '../core/api/api_client.dart';
import '../features/scan/scan_page.dart';
import '../features/scan/scan_repository.dart';
import '../features/scan/screen_bubble_bridge.dart';
import '../features/templates/template_page.dart';
import '../features/templates/template_repository.dart';
import 'support_page.dart';

class CheckLuaDaoApp extends StatefulWidget {
  const CheckLuaDaoApp({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<CheckLuaDaoApp> createState() => _CheckLuaDaoAppState();
}

class _CheckLuaDaoAppState extends State<CheckLuaDaoApp> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  int _tab = 0;
  StreamSubscription<void>? _openHomeSubscription;
  StreamSubscription<void>? _overlayResultSubscription;

  @override
  void initState() {
    super.initState();
    _openHomeSubscription = ScreenBubbleBridge.instance.openHome.listen((_) {
      if (mounted) setState(() => _tab = 0);
    });
    _overlayResultSubscription = ScreenBubbleBridge.instance.overlayResultReady
        .listen((_) {
          if (mounted) setState(() => _tab = 0);
        });
  }

  @override
  void dispose() {
    _openHomeSubscription?.cancel();
    _overlayResultSubscription?.cancel();
    if (widget.apiClient == null) _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckLuaDao',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: Scaffold(
        appBar: AppBar(
          leadingWidth: 52,
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Image.asset('assets/images/logo_checkluadao.png'),
          ),
          titleSpacing: 0,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CheckLuaDao',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0037B0),
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D4ED8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'QUÉT KHI BẠN YÊU CẦU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF52627A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Giới thiệu',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'CheckLuaDao',
                applicationVersion: '1.2.0',
                children: const [
                  Text(
                    'Kết quả phân tích AI chỉ hỗ trợ nhận diện dấu hiệu rủi ro. Hãy xác minh với tổ chức qua kênh chính thức trước khi làm theo tin nhắn.',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            ScanPage(repository: ScanRepository(_api)),
            TemplatePage(repository: TemplateRepository(_api)),
            const SupportPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner),
              label: 'Quét AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'Kho mẫu',
            ),
            NavigationDestination(
              icon: Icon(Icons.support_agent_outlined),
              selectedIcon: Icon(Icons.support_agent),
              label: 'Hỗ trợ',
            ),
          ],
        ),
      ),
    );
  }
}

ThemeData _theme() {
  const primary = Color(0xFF0037B0);
  final colors = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    surface: const Color(0xFFF8F9FF),
    error: const Color(0xFFBA1A1A),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: const Color(0xFFF6F8FC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF6F8FC),
      foregroundColor: Color(0xFF0B1C30),
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDCE9FF),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? primary
              : const Color(0xFF52627A),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(color: Color(0xFFBFD1F4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: Color(0xFFD6DFEF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: Color(0xFFD6DFEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Color(0xFFE1E8F3)),
      ),
    ),
  );
}
