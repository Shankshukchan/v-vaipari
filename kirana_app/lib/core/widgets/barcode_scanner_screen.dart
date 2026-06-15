import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Opens the barcode scanner full-screen.
/// Returns the scanned barcode string, or null if cancelled.
Future<String?> openBarcodeScanner(BuildContext context) async {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const BarcodeScannerPage(),
    ),
  );
}

// ─── Full-screen scanner page ────────────────────────────────────────────────

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _found = false;
  bool _torchOn = false;
  bool _hasError = false;
  String? _errorMsg;
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Full-screen camera
            if (!_hasError)
              MobileScanner(
                controller: _cameraController!,
                onDetect: (barcode) {
                  if (_found) return;
                  final code = barcode.barcodes.first.rawValue;
                  if (code != null && code.isNotEmpty) {
                    _found = true;
                    Navigator.of(context).pop(code);
                  }
                },
                errorBuilder: (context, error) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_hasError) {
                      setState(() {
                        _hasError = true;
                        _errorMsg = _friendlyError(error);
                      });
                    }
                  });
                  return const SizedBox.expand(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                },
              ),

            // Error screen
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white54, size: 64),
                      const SizedBox(height: 24),
                      const Text(
                        'Camera Issue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMsg ?? 'Could not access camera.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top bar — close and torch
            if (!_hasError)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _CircleButton(
                      icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                      onTap: () async {
                        await _cameraController?.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                    ),
                  ],
                ),
              ),

            // Scan frame
            if (!_hasError)
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: CustomPaint(painter: _ScanFramePainter()),
                ),
              ),

            // Bottom hint
            if (!_hasError)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 48,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Point camera at a barcode',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _friendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Camera permission was denied.\nPlease allow camera access in your phone settings.';
    }
    if (msg.contains('not available') || msg.contains('no camera')) {
      return 'No camera found on this device.';
    }
    return 'Could not start camera.\nPlease try again or check your phone settings.';
  }
}

// ─── Circle button ───────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Scan frame painter ──────────────────────────────────────────────────────

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final c = size.width * 0.08;

    // Top-left
    canvas.drawLine(const Offset(0, 0), Offset(c, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, c), paint);
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - c, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, c), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - c, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - c), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(c, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - c), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
