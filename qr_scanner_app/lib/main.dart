import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/services/qr_history_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đặt thanh trạng thái trong suốt mượt mà
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final historyService = QrHistoryService();
  await historyService.loadHistory();

  runApp(QrMasterApp(historyService: historyService));
}

class QrMasterApp extends StatelessWidget {
  final QrHistoryService historyService;

  const QrMasterApp({
    super.key,
    required this.historyService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(historyService: historyService),
    );
  }
}
