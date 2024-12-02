import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _torchState = false;
  String? _lastScannedCode;
  bool _isPaused = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleCodeScanned(String code) async {
    if (!_isPaused) {
      setState(() {
        _lastScannedCode = code;
        _isPaused = true;
      });
      await cameraController.stop();
    }
  }

  void _resetScanner() async {
    setState(() {
      _lastScannedCode = null;
      _isPaused = false;
    });
    await cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            color: _torchState ? Colors.yellow : Colors.white,
            icon: Icon(_torchState ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _torchState = !_torchState;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isPaused)
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String code = barcodes.first.rawValue ?? '';
                  _handleCodeScanned(code);
                }
              },
            ),
          if (_lastScannedCode != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scanned Barcode:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastScannedCode!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, _lastScannedCode);
                              },
                              child: const Text('Use This Code'),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: _resetScanner,
                              child: const Text('Scan Again'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_isPaused)
            CustomPaint(
              size: Size.infinite,
              painter: ScannerOverlayPainter(),
            ),
          if (!_isPaused)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Align barcode within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    final scanAreaRight = scanAreaLeft + scanAreaSize;
    final scanAreaBottom = scanAreaTop + scanAreaSize;

    // Draw semi-transparent overlay
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanAreaPath = Path()
      ..addRect(Rect.fromLTRB(
          scanAreaLeft, scanAreaTop, scanAreaRight, scanAreaBottom));
    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanAreaPath,
    );
    canvas.drawPath(path, paint);

    // Draw scan area border
    final borderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(
      Rect.fromLTRB(scanAreaLeft, scanAreaTop, scanAreaRight, scanAreaBottom),
      borderPaint,
    );

    // Draw corner markers
    final markerPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final markerLength = scanAreaSize * 0.1;

    // Top left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + markerLength, scanAreaTop),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft, scanAreaTop + markerLength),
      markerPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(scanAreaRight - markerLength, scanAreaTop),
      Offset(scanAreaRight, scanAreaTop),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRight, scanAreaTop),
      Offset(scanAreaRight, scanAreaTop + markerLength),
      markerPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaBottom - markerLength),
      Offset(scanAreaLeft, scanAreaBottom),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaBottom),
      Offset(scanAreaLeft + markerLength, scanAreaBottom),
      markerPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(scanAreaRight - markerLength, scanAreaBottom),
      Offset(scanAreaRight, scanAreaBottom),
      markerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRight, scanAreaBottom - markerLength),
      Offset(scanAreaRight, scanAreaBottom),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
