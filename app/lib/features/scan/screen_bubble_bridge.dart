import 'dart:async';

import 'package:flutter/services.dart';

import '../../app/app_config.dart';

import 'package:flutter/foundation.dart';

class ScreenBubbleState {
  const ScreenBubbleState({
    required this.supported,
    required this.overlayGranted,
    required this.running,
  });

  final bool supported;
  final bool overlayGranted;
  final bool running;

  factory ScreenBubbleState.fromMap(Map<Object?, Object?> value) =>
      ScreenBubbleState(
        supported: value['supported'] == true,
        overlayGranted: value['overlayGranted'] == true,
        running: value['running'] == true,
      );
}

class ScreenBubbleBridge {
  ScreenBubbleBridge._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openHome') _openHome.add(null);
      if (call.method == 'bubbleStateChanged') _bubbleStateChanged.add(null);
      if (call.method == 'overlayResultReady') _overlayResultReady.add(null);
    });
  }

  static final instance = ScreenBubbleBridge._();
  static const _channel = MethodChannel('checkluadao/screen_bubble');
  final _openHome = StreamController<void>.broadcast();
  final _bubbleStateChanged = StreamController<void>.broadcast();
  final _overlayResultReady = StreamController<void>.broadcast();

  Stream<void> get openHome => _openHome.stream;
  Stream<void> get bubbleStateChanged => _bubbleStateChanged.stream;
  Stream<void> get overlayResultReady => _overlayResultReady.stream;

  Future<ScreenBubbleState> state() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>('state');
    return ScreenBubbleState.fromMap(value ?? const {});
  }

  Future<void> requestOverlayPermission() =>
      _channel.invokeMethod<void>('requestOverlayPermission');

  Future<void> startBubble() => _channel.invokeMethod<void>('startBubble', {
    'apiBaseUrl': AppConfig.apiBaseUrl,
    'allowLiveScan': !kReleaseMode || AppConfig.backendPrivacyReady,
  });

  Future<void> stopBubble() => _channel.invokeMethod<void>('stopBubble');

  Future<String?> consumeOverlayResult() =>
      _channel.invokeMethod<String>('consumeOverlayResult');
}
