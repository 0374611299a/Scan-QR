import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/services/qr_history_service.dart';
import '../../../../domain/models/qr_item.dart';

class GeneratorScreen extends StatefulWidget {
  final QrHistoryService historyService;

  const GeneratorScreen({
    super.key,
    required this.historyService,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final GlobalKey _qrRepaintKey = GlobalKey();

  QrItemType _selectedType = QrItemType.url;
  final TextEditingController _primaryController = TextEditingController();

  // Dành riêng cho Wi-Fi
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  String _wifiSecurity = 'WPA';

  String _generatedContent = 'https://flutter.dev';
  bool _isGenerated = false;

  @override
  void initState() {
    super.initState();
    _primaryController.text = 'https://flutter.dev';
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _generateQr() {
    String content = '';
    switch (_selectedType) {
      case QrItemType.url:
        final raw = _primaryController.text.trim();
        if (raw.isEmpty) return;
        content = (raw.startsWith('http://') || raw.startsWith('https://')) ? raw : 'https://$raw';
        break;
      case QrItemType.text:
        content = _primaryController.text.trim();
        break;
      case QrItemType.phone:
        final phone = _primaryController.text.trim();
        if (phone.isEmpty) return;
        content = 'tel:$phone';
        break;
      case QrItemType.email:
        final email = _primaryController.text.trim();
        if (email.isEmpty) return;
        content = 'mailto:$email';
        break;
      case QrItemType.wifi:
        final ssid = _wifiSsidController.text.trim();
        final pass = _wifiPasswordController.text.trim();
        if (ssid.isEmpty) return;
        content = 'WIFI:S:$ssid;T:$_wifiSecurity;P:$pass;;';
        break;
      case QrItemType.sms:
        final phone = _primaryController.text.trim();
        if (phone.isEmpty) return;
        content = 'sms:$phone';
        break;
    }

    if (content.isEmpty) return;

    setState(() {
      _generatedContent = content;
      _isGenerated = true;
    });

    // Lưu vào lịch sử các mã đã tạo
    widget.historyService.addItem(
      QrItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _generatedContent,
        type: _selectedType,
        createdAt: DateTime.now(),
        isScanned: false,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tạo mã QR thành công!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _shareQrImage() async {
    try {
      final boundary = _qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Mã QR: $_generatedContent');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ mã QR: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: _generatedContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nội dung mã QR!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo mã QR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh chọn loại QR Code (Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChoiceChip(QrItemType.url, 'Website', Icons.link_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChoiceChip(QrItemType.text, 'Văn bản', Icons.text_snippet_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChoiceChip(QrItemType.wifi, 'Wi-Fi', Icons.wifi_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChoiceChip(QrItemType.phone, 'Số điện thoại', Icons.phone_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChoiceChip(QrItemType.email, 'Email', Icons.email_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Các ô nhập liệu tương ứng
            _buildInputFields(),
            const SizedBox(height: 16),

            // Nút Tạo QR
            ElevatedButton.icon(
              onPressed: _generateQr,
              icon: const Icon(Icons.qr_code_2_rounded, size: 22),
              label: const Text('Tạo mã QR'),
            ),
            const SizedBox(height: 28),

            // Khung hiển thị mã QR đã tạo
            Center(
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _qrRepaintKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: _generatedContent,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedType.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _generatedContent,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _copyContent,
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Sao chép'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _shareQrImage,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Chia sẻ ảnh'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChoiceChip(QrItemType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : theme.colorScheme.primary,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.transparent,
      selectedColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _primaryController.clear();
          });
        }
      },
    );
  }

  Widget _buildInputFields() {
    if (_selectedType == QrItemType.wifi) {
      return Column(
        children: [
          TextField(
            controller: _wifiSsidController,
            decoration: InputDecoration(
              labelText: 'Tên mạng Wi-Fi (SSID)',
              prefixIcon: const Icon(Icons.wifi_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wifiPasswordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu Wi-Fi',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _wifiSecurity,
            decoration: InputDecoration(
              labelText: 'Loại bảo mật',
              prefixIcon: const Icon(Icons.security_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2 / WPA3')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('Không có mật khẩu')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _wifiSecurity = val);
            },
          ),
        ],
      );
    }

    String hintText = '';
    String labelText = '';
    IconData icon = Icons.edit_rounded;
    TextInputType keyboardType = TextInputType.text;
    int maxLines = 1;

    switch (_selectedType) {
      case QrItemType.url:
        labelText = 'Địa chỉ Website (URL)';
        hintText = 'https://example.com';
        icon = Icons.link_rounded;
        keyboardType = TextInputType.url;
        break;
      case QrItemType.text:
        labelText = 'Nội dung văn bản';
        hintText = 'Nhập bất kỳ đoạn văn bản nào...';
        icon = Icons.text_snippet_rounded;
        keyboardType = TextInputType.multiline;
        maxLines = 3;
        break;
      case QrItemType.phone:
        labelText = 'Số điện thoại';
        hintText = '0901234567';
        icon = Icons.phone_rounded;
        keyboardType = TextInputType.phone;
        break;
      case QrItemType.email:
        labelText = 'Địa chỉ Email';
        hintText = 'contact@example.com';
        icon = Icons.email_rounded;
        keyboardType = TextInputType.emailAddress;
        break;
      case QrItemType.sms:
        labelText = 'Số điện thoại nhận tin nhắn';
        hintText = '0901234567';
        icon = Icons.sms_rounded;
        keyboardType = TextInputType.phone;
        break;
      case QrItemType.wifi:
        break;
    }

    return TextField(
      controller: _primaryController,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
