import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  final double scanWindowSize;
  const ScannerOverlay({super.key, this.scanWindowSize = 270.0});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final scanSize = widget.scanWindowSize.clamp(200.0, screenWidth * 0.8);

        final scanRect = Rect.fromCenter(
          center: Offset(screenWidth / 2, screenHeight / 2 - 30),
          width: scanSize,
          height: scanSize,
        );

        return Stack(
          children: [
            // Lớp phủ làm tối xung quanh vùng quét
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned.fromRect(
                    rect: scanRect,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4 Góc viền nổi bật (Corner Brackets)
            Positioned.fromRect(
              rect: scanRect,
              child: CustomPaint(
                painter: _CornerPainter(
                  color: Theme.of(context).colorScheme.primary,
                  cornerLength: 32,
                  strokeWidth: 4.5,
                  borderRadius: 20,
                ),
              ),
            ),

            // Tia quét laser di chuyển lên xuống
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final topOffset = scanRect.top +
                    8 +
                    (_animController.value * (scanRect.height - 16));
                return Positioned(
                  left: scanRect.left + 10,
                  top: topOffset,
                  width: scanRect.width - 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Dòng hướng dẫn bên dưới khung quét
            Positioned(
              left: 0,
              right: 0,
              top: scanRect.bottom + 24,
              child: const Center(
                child: Text(
                  'Căn chỉnh mã QR vào trong khung quét',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  _CornerPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;

    // Góc trên bên trái
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Góc trên bên phải
    final pathTR = Path()
      ..moveTo(w - cornerLength, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Góc dưới bên trái
    final pathBL = Path()
      ..moveTo(0, h - cornerLength)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(cornerLength, h);
    canvas.drawPath(pathBL, paint);

    // Góc dưới bên phải
    final pathBR = Path()
      ..moveTo(w - cornerLength, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
