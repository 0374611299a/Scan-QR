import 'package:flutter/material.dart';
import '../../data/services/qr_history_service.dart';
import '../features/generator/views/generator_screen.dart';
import '../features/history/views/history_screen.dart';
import '../features/scanner/views/scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final QrHistoryService historyService;

  const HomeScreen({
    super.key,
    required this.historyService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ScannerScreen(historyService: widget.historyService),
          GeneratorScreen(historyService: widget.historyService),
          HistoryScreen(historyService: widget.historyService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Quét QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'Tạo QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Lịch sử',
          ),
        ],
      ),
    );
  }
}
