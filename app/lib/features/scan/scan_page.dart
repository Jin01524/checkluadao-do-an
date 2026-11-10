import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../app/app_config.dart';
import '../../core/models/scan_result.dart';
import '../../core/models/system_stats.dart';
import 'image_preparation.dart';
import 'scan_repository.dart';
import 'scan_result_card.dart';
import 'context_follow_up_card.dart';
import 'screen_bubble_bridge.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.repository});
  final ScanRepository repository;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  static const _bankExample =
      'Mẫu giả lập: Tài khoản ngân hàng của bạn sắp bị khóa. Hãy cung cấp mã OTP để xác minh ngay.';
  static const _jobExample =
      'Mẫu giả lập: Tuyển cộng tác viên xử lý đơn hàng tại nhà. Chuyển trước 200.000 đồng để kích hoạt nhiệm vụ và nhận hoa hồng.';
  static const _policeExample =
      'Mẫu giả lập: Thông báo từ Viện Kiểm Sát về lệnh tạm giam và phong tỏa tài sản. Yêu cầu chuyển tiền vào tài khoản tạm giữ 102938475 để giám định.';
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();
  final _errorKey = GlobalKey();
  final _capturePreviewKey = GlobalKey();
  final _picker = ImagePicker();
  final List<PreparedScanImage> _images = [];
  ScanResult? _result;
  String? _error;
  bool _submitting = false;
  bool _preparingImages = false;
  int _waitSeconds = 0;
  int _mode = 0;
  Timer? _timer;
  StreamSubscription<void>? _bubbleStateSubscription;
  StreamSubscription<void>? _overlayResultSubscription;
  ScreenBubbleState? _bubbleState;
  bool _bubbleBusy = false;
  String? _captureNotice;
  SystemStats? _stats;
  bool _statsLoading = true;
  String? _statsError;
  int _statsRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bubbleStateSubscription = ScreenBubbleBridge.instance.bubbleStateChanged
        .listen((_) => _refreshBubbleState());
    _overlayResultSubscription = ScreenBubbleBridge.instance.overlayResultReady
        .listen((_) => _consumeOverlayResult());
    _recoverLostImages();
    _loadStats();
    _consumeOverlayResult();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        [
          'insufficient_context',
          'invalid_input',
        ].contains(_result?.assessmentStatus)) {
      setState(() => _result = null);
    }
    if (state == AppLifecycleState.resumed) {
      _refreshBubbleState();
      _loadStats();
      _consumeOverlayResult();
    }
  }

  @override
  void dispose() {
    _statsRequest++;
    WidgetsBinding.instance.removeObserver(this);
    _bubbleStateSubscription?.cancel();
    _overlayResultSubscription?.cancel();
    _timer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshBubbleState() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final state = await ScreenBubbleBridge.instance.state();
      if (mounted) setState(() => _bubbleState = state);
    } catch (_) {
      if (mounted) setState(() => _bubbleState = null);
    }
  }

  Future<void> _loadStats() async {
    final request = ++_statsRequest;
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });
    try {
      final stats = await widget.repository.stats();
      if (!mounted || request != _statsRequest) return;
      setState(() {
        _stats = stats;
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted || request != _statsRequest) return;
      setState(() {
        _statsLoading = false;
        _statsError = 'Không cập nhật được thống kê.';
      });
    }
  }

  Future<void> _consumeOverlayResult() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final json = await ScreenBubbleBridge.instance.consumeOverlayResult();
      if (json == null || !mounted) return;
      final data = jsonDecode(json);
      if (data is! Map) throw const FormatException('Invalid overlay result');
      final parsed = ScanResult.fromJson(Map<String, dynamic>.from(data));
      setState(() {
        _result = parsed;
        _error = null;
      });
      if (!mounted) return;
      _loadStats();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _resultKey.currentContext;
        if (mounted && context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.08,
            duration: const Duration(milliseconds: 350),
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể mở báo cáo quét màn hình. Hãy thử lại.',
        );
      }
    }
  }

  Future<void> _toggleBubble() async {
    if (_bubbleBusy) return;
    setState(() {
      _bubbleBusy = true;
      _error = null;
    });
    try {
      final bridge = ScreenBubbleBridge.instance;
      final state = await bridge.state();
      if (state.running) {
        await bridge.stopBubble();
      } else if (!state.overlayGranted) {
        await bridge.requestOverlayPermission();
      } else {
        await bridge.startBubble();
      }
      await _refreshBubbleState();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message ?? 'Không thể bật bong bóng quét.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể bật bong bóng quét. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _bubbleBusy = false);
    }
  }

  Future<void> _recoverLostImages() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      if (response.files != null) await _addImages(response.files!);
    } catch (_) {
      // The user can pick images again if Android cannot restore the picker result.
    }
  }

  Future<void> _pickImages({required bool camera}) async {
    if (_submitting || _preparingImages) return;
    if (_images.length >= maxScanImages) {
      setState(() => _error = 'Chỉ chọn tối đa 5 ảnh cho mỗi lượt kiểm tra.');
      return;
    }
    try {
      if (camera) {
        final file = await _picker.pickImage(source: ImageSource.camera);
        if (file != null) await _addImages([file]);
      } else {
        final files = await _picker.pickMultiImage(
          limit: maxScanImages - _images.length,
        );
        await _addImages(files);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không mở được camera/thư viện ảnh. Hãy kiểm tra quyền truy cập và thử lại.',
        );
      }
    }
  }

  Future<void> _addImages(List<XFile> files) async {
    if (files.isEmpty || !mounted) return;
    setState(() {
      _preparingImages = true;
      _error = null;
    });
    try {
      for (final file in files.take(maxScanImages - _images.length)) {
        final prepared = await prepareImage(file);
        if (!mounted) return;
        setState(() => _images.add(prepared));
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể xử lý ảnh đã chọn. Vui lòng thử ảnh khác.',
        );
      }
    } finally {
      if (mounted) setState(() => _preparingImages = false);
    }
  }

  Future<void> _scan() async {
    if (kReleaseMode && !AppConfig.backendPrivacyReady) {
      setState(
        () => _error = 'Chức năng quét chưa mở trong bản phát hành vì backend cần hoàn tất kiểm tra quyền riêng tư.',
      );
      return;
    }
    final text = _textController.text.trim();
    if (text.isEmpty && _images.isEmpty) {
      setState(() => _error = 'Hãy nhập nội dung hoặc chọn ít nhất một ảnh.');
      _scrollToError();
      return;
    }
    if (_submitting || _preparingImages) return;
    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
      _waitSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _waitSeconds++);
    });
    try {
      final result = await widget.repository.scan(
        text: text,
        images: [
          for (var i = 0; i < _images.length; i++) _images[i].toUpload(i),
        ],
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _images.clear();
        _textController.clear();
      });
      if (!mounted) return;
      _loadStats();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _resultKey.currentContext;
        if (!mounted || context == null) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.08,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
        _scrollToError();
      }
    } finally {
      _timer?.cancel();
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startNewScan() {
    setState(() {
      _result = null;
      _error = null;
      _captureNotice = null;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _errorKey.currentContext;
      if (mounted && context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.3,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('scan_page'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF2FF), Color(0xFFF5F8FF)],
              ),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.zero,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHỦ ĐỘNG KIỂM TRA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'CheckLuaDao • AI hỗ trợ nhận diện rủi ro',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _statsPanel(),
          const SizedBox(height: 20),
          Text(
            'Kiểm tra tin nhắn nghi vấn',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0B1C30),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tải ảnh chụp hoặc dán nội dung để AI nhận diện dấu hiệu đáng ngờ.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _modeTab(0, Icons.camera_alt_outlined, 'Ảnh chụp'),
                        _modeTab(
                          1,
                          Icons.content_paste_outlined,
                          'Dán văn bản',
                        ),
                        _modeTab(
                          2,
                          Icons.phone_android_outlined,
                          'Quét màn hình',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_mode == 2) _screenBubblePanel(theme),
                  if (_mode == 1) ...[
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'DỮ LIỆU PHÂN TÍCH',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0037B0),
                            letterSpacing: 1,
                          ),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _textController,
                          builder: (_, value, _) => Text(
                            '${value.text.length} ký tự',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('scan_text_input'),
                      controller: _textController,
                      maxLines: 5,
                      minLines: 5,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        hintText: 'Dán tin nhắn, đường link hoặc nội dung bạn muốn kiểm tra...',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () async {
                                  final data = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (data?.text == null || !mounted) return;
                                  setState(
                                    () => _textController.text = data!.text!,
                                  );
                                },
                          icon: const Icon(
                            Icons.content_paste_outlined,
                            size: 18,
                          ),
                          label: const Text('Dán'),
                        ),
                        TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(_textController.clear),
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'THỬ VỚI TIN NHẮN GIẢ LẬP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF0037B0),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.account_balance_outlined,
                              size: 17,
                            ),
                            label: const Text('Giả mạo ngân hàng'),
                            onPressed: _submitting
                                ? null
                                : () => _textController.text = _bankExample,
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.work_outline, size: 17),
                            label: const Text('Việc làm online'),
                            onPressed: _submitting
                                ? null
                                : () => _textController.text = _jobExample,
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.gavel_outlined, size: 17),
                            label: const Text('Trát lệnh bắt giam'),
                            onPressed: _submitting
                                ? null
                                : () => _textController.text = _policeExample,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_mode == 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: const Color(0xFFBFD1F4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: Color(0xFF0037B0),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chạm để chụp hoặc tải ảnh',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hỗ trợ JPG, PNG, WebP • tối đa 5 ảnh',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _submitting || _preparingImages
                                ? null
                                : () => _pickImages(camera: false),
                            icon: const Icon(Icons.folder_open_outlined),
                            label: const Text('Chọn từ thiết bị'),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: TextButton.icon(
                        onPressed: _submitting || _preparingImages
                            ? null
                            : () => _pickImages(camera: true),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Hoặc chụp ảnh bằng camera'),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, _) => value.text.trim().isEmpty
                          ? const SizedBox.shrink()
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              color: const Color(0xFFEFF4FF),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    size: 19,
                                    color: Color(0xFF0037B0),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      'Sẽ phân tích cả ${value.text.length} ký tự văn bản đã nhập.',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => _mode = 1),
                                    child: const Text('Xem'),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                  if (_mode != 2) ...[
                    if (_preparingImages)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        key: _capturePreviewKey,
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: Image.memory(
                                  _images[index].bytes,
                                  width: 90,
                                  height: 108,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: IconButton.filledTonal(
                                  tooltip: 'Xóa ảnh ${index + 1}',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _submitting
                                      ? null
                                      : () => setState(
                                          () => _images.removeAt(index),
                                        ),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('scan_submit'),
                      onPressed: _submitting || _preparingImages ? null : _scan,
                      icon: Icon(
                        _submitting
                            ? Icons.hourglass_top
                            : Icons.shield_outlined,
                      ),
                      label: Text(
                        _submitting
                            ? 'Đang phân tích ($_waitSeconds giây)'
                            : 'BẮT ĐẦU PHÂN TÍCH VỚI AI',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      color: const Color(0xFFDC2626),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vừa chuyển tiền cho kẻ lừa đảo?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Liên hệ ngay ngân hàng qua số trong ứng dụng hoặc trên thẻ chính thức để yêu cầu hỗ trợ giao dịch.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F1D1D),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () => _showEmergencyDialog(context),
                  icon: const Icon(Icons.support_agent_outlined, size: 16),
                  label: const Text('XEM CÁC BƯỚC CẦN LÀM'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bản demo: nội dung bạn chọn được gửi đến máy chủ để phân tích. Mẫu đủ ba phân tích AI sẽ được lưu; mẫu rủi ro chưa kiểm duyệt có thể hiển thị công khai. Chỉ dùng dữ liệu giả lập, không nhập mật khẩu, OTP hoặc thông tin tài chính nhạy cảm.',
            style: theme.textTheme.bodySmall,
          ),
          if (_captureNotice != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Card(
                color: const Color(0xFFE6F4EF),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_captureNotice!),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              key: _errorKey,
              padding: const EdgeInsets.only(top: 14),
              child: Semantics(
                label: 'Lỗi quét: $_error',
                liveRegion: true,
                excludeSemantics: true,
                child: Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child:
                  [
                    'insufficient_context',
                    'invalid_input',
                  ].contains(_result!.assessmentStatus)
                  ? KeyedSubtree(
                      key: _resultKey,
                      child: ContextFollowUpCard(
                        key: ValueKey(_result),
                        result: _result!,
                        busy: _submitting,
                        onNewScan: _startNewScan,
                      ),
                    )
                  : ScanResultCard(result: _result!, headerKey: _resultKey),
            ),
        ],
      ),
    );
  }

  Widget _modeTab(int index, IconData icon, String label) {
    final active = _mode == index;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: index == 2 ? 0 : 3),
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          child: InkWell(
            onTap: () {
              setState(() => _mode = index);
              if (index == 2) _refreshBubbleState();
            },
            child: Container(
              key: Key('scan_mode_$index'),
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFF8F9FF),
                border: Border.all(color: const Color(0xFFDCE9FF)),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: active ? Colors.white : const Color(0xFF52627A),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? Colors.white : const Color(0xFF52627A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _screenBubblePanel(ThemeData theme) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    final state = _bubbleState;
    final running = state?.running == true;
    return Container(
      padding: const EdgeInsets.all(18),
      color: const Color(0xFFEFF4FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Khung mô phỏng radar quét màn hình nổi (Stitch Screen 3)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Các vòng tròn sóng radar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF93C5FD).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                // Bong bóng trung tâm mô phỏng
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0037B0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x330037B0),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 26,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFF316BF3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'CheckLuaDao Overlay AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0037B0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    color: Colors.white.withValues(alpha: 0.85),
                    child: const Text(
                      'Zalo / SMS / Telegram',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF434655),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    color: Colors.white.withValues(alpha: 0.85),
                    child: const Text(
                      'Bảo vệ thời gian thực',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0037B0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 10),
          Text(
            'Bong bóng quét màn hình',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bật bong bóng, mở tin nhắn cần kiểm tra rồi chọn Quét màn hình. Sau khi bạn đồng ý trong hộp thoại Android, ảnh được gửi tới máy chủ để phân tích tự động. Kết quả hiện trên lớp phủ; chạm Xem chi tiết để mở báo cáo trong app.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!android)
            const Text(
              'Tính năng bong bóng chỉ hỗ trợ Android.',
              textAlign: TextAlign.center,
            )
          else ...[
            FilledButton.icon(
              key: const Key('screen_bubble_toggle'),
              onPressed: _bubbleBusy ? null : _toggleBubble,
              icon: Icon(running ? Icons.close : Icons.open_in_new),
              label: Text(
                _bubbleBusy
                    ? 'Đang xử lý...'
                    : running
                    ? 'TẮT BONG BÓNG'
                    : state?.overlayGranted == false
                    ? 'CẤP QUYỀN HIỂN THỊ'
                    : 'BẬT BONG BÓNG QUÉT',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              running
                  ? 'Bong bóng đang hiển thị. Chạm một lần để mở menu, chạm lần nữa để thu lại; kéo để đổi vị trí.'
                  : 'Ảnh chỉ được chụp và gửi phân tích khi bạn chọn Quét màn hình rồi đồng ý trong hộp thoại Android.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'CÁCH THỨC HOẠT ĐỘNG',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF0037B0),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _bubbleStep(
              '1',
              'Cấp quyền hiển thị',
              state?.overlayGranted == true
                  ? 'Đã cấp quyền cho bong bóng nổi.'
                  : 'Android sẽ mở cài đặt để bạn cấp quyền.',
            ),
            _bubbleStep(
              '2',
              'Mở cuộc trò chuyện',
              'Chuyển sang ứng dụng có nội dung bạn muốn kiểm tra.',
            ),
            _bubbleStep(
              '3',
              'Chọn Quét màn hình',
              'Đồng ý trong hộp thoại Android. Lớp phủ sẽ hiện tiến trình, kết quả và nút Xem chi tiết.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _bubbleStep(String number, String title, String detail) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          color: const Color(0xFF0037B0),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(detail, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Row(
          children: [
            Icon(Icons.support_agent_outlined, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nếu vừa chuyển tiền',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Dừng trao đổi với người gửi tin nhắn. Không cung cấp thêm OTP hoặc mật khẩu.',
            ),
            SizedBox(height: 10),
            Text(
              '2. Liên hệ ngân hàng bằng số trong ứng dụng, trên thẻ hoặc website chính thức để yêu cầu hỗ trợ.',
            ),
            SizedBox(height: 10),
            Text(
              '3. Lưu chứng từ, tin nhắn và trình báo cơ quan chức năng tại địa phương. Đổi mật khẩu nếu đã đăng nhập qua liên kết lạ.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ĐÃ HIỂU'),
          ),
        ],
      ),
    );
  }

  Widget _statsPanel() {
    final stats = _stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'THỐNG KÊ LƯỢT QUÉT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0037B0),
                  letterSpacing: 0.7,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cập nhật thống kê',
              onPressed: _statsLoading ? null : _loadStats,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        if (stats == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _statsLoading
                  ? 'Đang tải thống kê...'
                  : 'Chưa tải được thống kê. Nhấn cập nhật để thử lại.',
              style: const TextStyle(color: Color(0xFF52627A)),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final tile1 = _telemetryTile(
                icon: Icons.chat_outlined,
                badge: 'ĐÃ QUÉT',
                value: _formatCount(stats.totalScans),
                label: 'Tổng lượt kiểm tra tin nhắn, ảnh',
                accent: const Color(0xFF1D4ED8),
              );
              final tile2 = _telemetryTile(
                icon: Icons.warning_amber_rounded,
                badge: 'CẢNH BÁO',
                value: stats.totalScans == 0
                    ? '—'
                    : _formatPercent(stats.warningPercent),
                label: stats.totalScans == 0
                    ? 'Chưa có lượt quét để tính tỷ lệ'
                    : '${_formatCount(stats.warnedScans)}/${_formatCount(stats.totalScans)} lượt có cảnh báo rủi ro',
                accent: const Color(0xFFB45309),
              );
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [tile1, const SizedBox(height: 8), tile2],
                );
              }
              return Row(
                children: [
                  Expanded(child: tile1),
                  const SizedBox(width: 10),
                  Expanded(child: tile2),
                ],
              );
            },
          ),
        if (_statsError != null && stats != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: const Text(
              'Không cập nhật được; đang hiển thị số liệu lần tải trước.',
              style: TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'Tỷ lệ cảnh báo = lượt có rủi ro / tổng lượt quét × 100%. Mỗi lần phân tích thành công được tính là một lượt.',
          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  String _formatCount(int count) => count.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );

  String _formatPercent(double percent) {
    final fixed = percent.toStringAsFixed(1).replaceAll('.', ',');
    return '${fixed.endsWith(',0') ? fixed.substring(0, fixed.length - 2) : fixed}%';
  }

  Widget _telemetryTile({
    required IconData icon,
    required String badge,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9E4F5)),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: [
              Icon(icon, size: 20, color: accent),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF52627A)),
          ),
        ],
      ),
    );
  }
}
