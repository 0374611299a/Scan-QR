import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../data/services/qr_history_service.dart';
import '../../../../domain/models/qr_item.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/scanner_overlay.dart';

class ScannerScreen extends StatefulWidget {
  final QrHistoryService historyService;

  const ScannerScreen({
    super.key,
    required this.historyService,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final firstCode = barcodes.first;
    final String? rawValue = firstCode.rawValue;
    if (rawValue != null && rawValue.trim().isNotEmpty) {
      _handleFoundCode(rawValue.trim());
    }
  }

  Future<void> _handleFoundCode(String code) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    await _controller.stop();

    final item = QrItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: code,
      type: QrItem.detectType(code),
      createdAt: DateTime.now(),
      isScanned: true,
    );

    await widget.historyService.addItem(item);

    if (mounted) {
      await ScanResultSheet.show(context, item);
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller.start();
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (file == null) return;

      setState(() => _isProcessing = true);

      final BarcodeCapture? capture = await _controller.analyzeImage(file.path);
      final barcode = capture?.barcodes.firstOrNull;

      if (barcode != null && barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        if (mounted) {
          _handleFoundCode(barcode.rawValue!.trim());
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy mã QR trong bức ảnh đã chọn'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi quét ảnh: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể truy cập máy ảnh: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _controller.start(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Lớp phủ khung quét + hiệu ứng laser
          const ScannerOverlay(),

          // Thanh công cụ phía trên (Flash & Đổi Camera)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Quét QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildCircleIconButton(
                        icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        isActive: _isTorchOn,
                        onTap: _toggleTorch,
                      ),
                      const SizedBox(width: 12),
                      _buildCircleIconButton(
                        icon: Icons.flip_camera_ios_rounded,
                        isActive: false,
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Nút quét từ thư viện ảnh ở góc dưới
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isProcessing ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library_rounded, size: 22, color: Color(0xFF4F46E5)),
                label: const Text(
                  'Quét từ thư viện ảnh',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
