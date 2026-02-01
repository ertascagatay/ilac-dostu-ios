import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        Navigator.of(context).pop(barcode.rawValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Top Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => cameraController.toggleTorch(),
                    icon: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white.withOpacity(0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Barkodu Tarayın',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlaç kutusundaki barkodu kare içine yerleştirin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutSize = size.width * 0.7;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2;

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
          const Radius.circular(20),
        ),
      );

    final overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
        const Radius.circular(20),
      ),
      borderPaint,
    );

    // Draw corner accents
    final accentPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + 20),
      Offset(cutoutLeft, cutoutTop),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop),
      Offset(cutoutLeft + cornerLength, cutoutTop),
      accentPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize - cornerLength, cutoutTop),
      Offset(cutoutLeft + cutoutSize, cutoutTop),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize, cutoutTop),
      Offset(cutoutLeft + cutoutSize, cutoutTop + 20),
      accentPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutSize - 20),
      Offset(cutoutLeft, cutoutTop + cutoutSize),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutSize),
      Offset(cutoutLeft + cornerLength, cutoutTop + cutoutSize),
      accentPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize - cornerLength, cutoutTop + cutoutSize),
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize - 20),
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
