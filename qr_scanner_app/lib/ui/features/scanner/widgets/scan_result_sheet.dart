import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/models/qr_item.dart';

class ScanResultSheet extends StatelessWidget {
  final QrItem item;

  const ScanResultSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, QrItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScanResultSheet(item: item),
    );
  }

  Future<void> _handlePrimaryAction(BuildContext context) async {
    final raw = item.content.trim();
    switch (item.type) {
      case QrItemType.url:
        final uri = Uri.tryParse(raw);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showMessage(context, 'Không thể mở liên kết này');
        }
        break;
      case QrItemType.phone:
        final uri = Uri.parse('tel:${raw.replaceAll(RegExp(r'[^0-9+]'), '')}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        break;
      case QrItemType.email:
        final email = raw.replaceFirst('mailto:', '');
        final uri = Uri.parse('mailto:$email');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        break;
      case QrItemType.sms:
        final uri = Uri.parse('sms:${raw.replaceFirst(RegExp(r'^smsto:|^sms:'), '')}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        break;
      case QrItemType.wifi:
      case QrItemType.text:
        _copyToClipboard(context);
        break;
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: item.content));
    _showMessage(context, 'Đã sao chép vào bộ nhớ tạm!');
  }

  void _shareContent() {
    Share.share(item.content, subject: 'Chia sẻ mã QR');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getTypeIcon(QrItemType type) {
    switch (type) {
      case QrItemType.url:
        return Icons.link_rounded;
      case QrItemType.wifi:
        return Icons.wifi_rounded;
      case QrItemType.phone:
        return Icons.phone_rounded;
      case QrItemType.email:
        return Icons.email_rounded;
      case QrItemType.sms:
        return Icons.sms_rounded;
      case QrItemType.text:
        return Icons.text_snippet_rounded;
    }
  }

  Color _getTypeColor(QrItemType type) {
    switch (type) {
      case QrItemType.url:
        return Colors.blue;
      case QrItemType.wifi:
        return Colors.teal;
      case QrItemType.phone:
        return Colors.green;
      case QrItemType.email:
        return Colors.deepOrange;
      case QrItemType.sms:
        return Colors.purple;
      case QrItemType.text:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(item.type);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề & Phân loại
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getTypeIcon(item.type), color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả quét QR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.type.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nội dung mã QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: SelectableText(
                item.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Các nút hành động chính
            Row(
              children: [
                if (item.type == QrItemType.url ||
                    item.type == QrItemType.phone ||
                    item.type == QrItemType.email ||
                    item.type == QrItemType.sms)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePrimaryAction(context),
                      icon: Icon(
                        item.type == QrItemType.url
                            ? Icons.open_in_browser_rounded
                            : item.type == QrItemType.phone
                                ? Icons.phone_forwarded_rounded
                                : Icons.send_rounded,
                      ),
                      label: Text(
                        item.type == QrItemType.url
                            ? 'Mở liên kết'
                            : item.type == QrItemType.phone
                                ? 'Gọi điện'
                                : 'Gửi ngay',
                      ),
                    ),
                  ),
                if (item.type == QrItemType.url ||
                    item.type == QrItemType.phone ||
                    item.type == QrItemType.email ||
                    item.type == QrItemType.sms)
                  const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Sao chép'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _shareContent,
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Chia sẻ',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
