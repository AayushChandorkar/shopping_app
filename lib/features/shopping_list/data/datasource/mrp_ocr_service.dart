import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Runs on-device OCR over a captured image of a product package and
/// extracts the printed MRP (Maximum Retail Price).
///
/// Strategy: prefer a number that follows the literal "M.R.P." / "MRP" /
/// "Maximum Retail Price" prefix, since that's the legal format on Indian
/// packaging and is almost always printed cleanly. Fall back to any
/// rupee-prefixed number on the package, picking the largest as the best
/// MRP candidate. Weights like "500 g" are skipped because the fallback
/// regex requires a currency marker (₹ / Rs / INR).
class MrpOcrService {
  MrpOcrService();

  // Primary pattern: MRP / M.R.P. / Maximum Retail Price with an optional
  // currency marker directly after it. The currency marker is optional
  // because OCR sometimes eats the ₹ glyph — if we can anchor on "MRP"
  // and see a number next to it, that's trustworthy enough.
  static final RegExp _mrpRegex = RegExp(
    r'(?:Maximum\s*Retail\s*Price|M\s*\.?\s*R\s*\.?\s*P\s*\.?)'
    r'[:.\s]*'
    r'(?:Rs\.?|INR|₹)?'
    r'\s*'
    r'(\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Fallback: any number preceded by a currency marker.
  static final RegExp _rupeeRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*(\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  /// Returns the best-guess MRP as a double, or `null` if nothing
  /// recognizable was found.
  Future<double?> extractMrpFromImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      final text = recognized.text;
      debugPrint('[MrpOcr] recognized text:\n$text');

      // 1. Prefer an MRP-prefixed match.
      final mrpMatch = _mrpRegex.firstMatch(text);
      if (mrpMatch != null) {
        final value = double.tryParse(mrpMatch.group(1)!);
        debugPrint('[MrpOcr] matched MRP-prefixed -> $value');
        if (value != null) return value;
      }

      // 2. Fallback: pick the largest rupee-prefixed figure, which is
      //    usually the MRP when multiple numbers are present.
      final rupeeMatches = _rupeeRegex.allMatches(text).toList();
      if (rupeeMatches.isEmpty) {
        debugPrint('[MrpOcr] no MRP or rupee match found');
        return null;
      }
      double? best;
      for (final m in rupeeMatches) {
        final v = double.tryParse(m.group(1)!);
        if (v == null) continue;
        if (best == null || v > best) best = v;
      }
      debugPrint('[MrpOcr] fallback largest rupee value -> $best');
      return best;
    } catch (e, st) {
      debugPrint('[MrpOcr] error: $e');
      debugPrint('$st');
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
