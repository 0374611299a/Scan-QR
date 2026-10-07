import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/qr_history_service.dart';
import '../../../../domain/models/qr_item.dart';
import '../../scanner/widgets/scan_result_sheet.dart';

class HistoryScreen extends StatefulWidget {
  final QrHistoryService historyService;

  const HistoryScreen({
    super.key,
    required this.historyService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Tất cả, 1: Đã quét, 2: Đã tạo

  List<QrItem> _getFilteredItems() {
    switch (_selectedFilterIndex) {
      case 1:
        return widget.historyService.scannedItems;
      case 2:
        return widget.historyService.generatedItems;
      default:
        return widget.historyService.items;
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử?'),
        content: const Text('Hành động này không thể hoàn tác. Bạn có chắc chắn muốn xóa không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.historyService.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử mã QR'),
        actions: [
          ListenableBuilder(
            listenable: widget.historyService,
            builder: (context, _) {
              if (widget.historyService.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Xóa tất cả',
                onPressed: _confirmClearAll,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Tất cả')),
                ButtonSegment(value: 1, label: Text('Đã quét')),
                ButtonSegment(value: 2, label: Text('Đã tạo')),
              ],
              selected: {_selectedFilterIndex},
              onSelectionChanged: (val) {
                setState(() {
                  _selectedFilterIndex = val.first;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Danh sách các mục
          Expanded(
            child: ListenableBuilder(
              listenable: widget.historyService,
              builder: (context, _) {
                final items = _getFilteredItems();

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 72,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có dữ liệu lịch sử nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        widget.historyService.removeItem(item.id);
                      },
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.isScanned
                                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                  : Colors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.isScanned ? Icons.qr_code_scanner : Icons.qr_code_2,
                              color: item.isScanned ? theme.colorScheme.primary : Colors.teal,
                              size: 24,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                item.type.label,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isScanned
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isScanned ? 'Quét' : 'Tạo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.isScanned ? Colors.blue : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(item.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            tooltip: 'Sao chép',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép vào bộ nhớ tạm'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            ScanResultSheet.show(context, item);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
