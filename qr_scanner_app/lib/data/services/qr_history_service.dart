import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/qr_item.dart';

class QrHistoryService extends ChangeNotifier {
  static const String _storageKey = 'qr_history_items';
  final List<QrItem> _items = [];

  List<QrItem> get items => List.unmodifiable(_items);
  List<QrItem> get scannedItems => _items.where((i) => i.isScanned).toList();
  List<QrItem> get generatedItems => _items.where((i) => !i.isScanned).toList();

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _items.clear();
        _items.addAll(decoded.map((e) => QrItem.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch sử QR: $e');
    }
  }

  Future<void> addItem(QrItem item) async {
    // Thêm vào đầu danh sách (mới nhất lên trên)
    _items.insert(0, item);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Lỗi lưu lịch sử QR: $e');
    }
  }
}
