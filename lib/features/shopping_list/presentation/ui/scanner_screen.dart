import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/themes/app_colors.dart';

/// Opens the device camera, captures an image, and scans it with ML Kit.
/// Pops with the decoded string as soon as a supported code is detected.
/// Pops with `null` if the user backs out of the camera flow.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  bool _isScanning = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scanBarcode();
      }
    });
  }

  @override
  void dispose() {
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _message = null;
    });

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (!mounted) return;
      if (photo == null) {
        Navigator.of(context).pop();
        return;
      }

      final inputImage = InputImage.fromFilePath(photo.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (!mounted) return;

      for (final barcode in barcodes) {
        final code = barcode.rawValue?.trim();
        if (code == null || code.isEmpty) continue;
        debugPrint(
          '[Scanner] detected -> rawValue="$code", format=${barcode.format.name}',
        );
        Navigator.of(context).pop(code);
        return;
      }

      setState(() {
        _message =
            'No barcode detected. Try again with the code centered and well-lit.';
      });
    } catch (e, st) {
      debugPrint('[Scanner] error: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _message =
            'Camera scan failed. Please try again and allow camera access.';
      });
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan a code',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(height: 28),
              if (_isScanning) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
              ],
              Text(
                _isScanning
                    ? 'Opening the camera and scanning your barcode...'
                    : (_message ?? 'Take a clear photo of the barcode or QR code'),
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              if (!_isScanning)
                FilledButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text('Try again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
