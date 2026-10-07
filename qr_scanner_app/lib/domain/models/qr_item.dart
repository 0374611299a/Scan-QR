enum QrItemType {
  url,
  wifi,
  email,
  phone,
  sms,
  text;

  String get label {
    switch (this) {
      case QrItemType.url:
        return 'Liên kết Web';
      case QrItemType.wifi:
        return 'Mạng Wi-Fi';
      case QrItemType.email:
        return 'Email';
      case QrItemType.phone:
        return 'Số điện thoại';
      case QrItemType.sms:
        return 'Tin nhắn SMS';
      case QrItemType.text:
        return 'Văn bản thuần';
    }
  }
}

class QrItem {
  final String id;
  final String content;
  final QrItemType type;
  final DateTime createdAt;
  final bool isScanned; // true nếu là quét từ camera/ảnh, false nếu là tự tạo

  QrItem({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isScanned = true,
  });

  /// Tự động phát hiện kiểu nội dung từ chuỗi quét được
  static QrItemType detectType(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return QrItemType.url;
    } else if (lower.startsWith('wifi:')) {
      return QrItemType.wifi;
    } else if (lower.startsWith('mailto:') || RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(raw.trim())) {
      return QrItemType.email;
    } else if (lower.startsWith('tel:') || RegExp(r'^\+?[0-9\s-]{8,15}$').hasMatch(raw.trim())) {
      return QrItemType.phone;
    } else if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      return QrItemType.sms;
    }
    return QrItemType.text;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isScanned': isScanned,
    };
  }

  factory QrItem.fromJson(Map<String, dynamic> json) {
    return QrItem(
      id: json['id'] as String,
      content: json['content'] as String,
      type: QrItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QrItemType.text,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isScanned: json['isScanned'] as bool? ?? true,
    );
  }
}
