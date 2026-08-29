import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mitracare_app/core/theme/design_system.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Patient QR Code"),
        backgroundColor: Colors.white,
        foregroundColor: DesignSystem.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            color: DesignSystem.primaryGreen,
            onPressed: () => _controller.toggleTorch(),
            tooltip: "Toggle flashlight",
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  _hasScanned = true;
                  // Stop scanning immediately and return scanned string
                  Navigator.pop(context, value);
                  break;
                }
              }
            },
          ),
          // Semitransparent overlay with clear scanning window
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Green border frame for visual guidance
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: DesignSystem.primaryGreen, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "Align the Patient's QR code in the frame above",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    const windowSize = 250.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - windowSize / 2;
    final top = cy - windowSize / 2;

    // Draw 4 rectangles around the clear window
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), paint);
    canvas.drawRect(Rect.fromLTRB(0, top + windowSize, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTRB(0, top, left, top + windowSize), paint);
    canvas.drawRect(Rect.fromLTRB(left + windowSize, top, size.width, top + windowSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
