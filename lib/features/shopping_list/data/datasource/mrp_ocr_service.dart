import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MrpOcrService {
  MrpOcrService();

  static final RegExp _mrpAnchor = RegExp(
    r'(?:Maximum\s*Retail\s*Price|M\s*\.?\s*R\s*\.?\s*P\s*\.?)',
    caseSensitive: false,
  );

  static final RegExp _numberRegex = RegExp(r'\d+(?:,\d{3})*(?:\.\d{1,2})?');

  static final RegExp _perUnitSlash = RegExp(
    r'^\s*/\s*(?:g|gm|gms|kg|mg|ml|l|litre|liter|oz|lb|pc|pcs|piece|serving|100\s*(?:g|ml))\b',
    caseSensitive: false,
  );
  static final RegExp _perUnitWord = RegExp(
    r'^\s*per\s+(?:g|gm|gms|kg|ml|l|oz|serving|piece|pc)\b',
    caseSensitive: false,
  );

  static final RegExp _weightUnit = RegExp(
    r'^\s*(?:gms?|kg|mg|mls?|litre|liter|l\b|oz|lb|g\b)',
    caseSensitive: false,
  );

  static final RegExp _timeColon = RegExp(r'^\s*:\s*\d');

  static final RegExp _dateAfter = RegExp(r'^\s*[/\-]\s*\d');

  static final RegExp _dateBefore = RegExp(r'[/\-]\s*$');

  static final RegExp _currencyPrefix = RegExp(
    r'(?:Rs\.?|INR|₹)\s*$',
    caseSensitive: false,
  );

  static final RegExp _fusedLetters = RegExp(r'([A-Za-z]+)$');

  static final RegExp _dateRegex = RegExp(
    r'\b\d{1,2}\s*[/\-]\s*\d{1,2}\s*[/\-]\s*\d{2,4}\b',
  );

  Future<double?> extractMrpFromImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      final rawText = recognized.text;
      debugPrint('[MrpOcr] recognized text:\n$rawText');

      final text = rawText.replaceAllMapped(
        _dateRegex,
        (m) => ' ' * (m.end - m.start),
      );

      final mrpEnds = _mrpAnchor.allMatches(text).map((m) => m.end).toList();
      debugPrint('[MrpOcr] MRP anchor ends at: $mrpEnds');

      final candidates = <_PriceCandidate>[];
      for (final m in _numberRegex.allMatches(text)) {
        final raw = m.group(0)!;
        final v = double.tryParse(raw.replaceAll(',', ''));

        if (v == null || v < 2 || v >= 100000) continue;

        final start = m.start;
        final end = m.end;
        final tail = text.substring(end, (end + 16).clamp(0, text.length));
        final head = text.substring((start - 8).clamp(0, text.length), start);

        if (_perUnitSlash.hasMatch(tail)) continue;
        if (_perUnitWord.hasMatch(tail)) continue;
        if (_weightUnit.hasMatch(tail)) continue;
        if (_timeColon.hasMatch(tail)) continue;
        if (_dateAfter.hasMatch(tail)) continue;
        if (_dateBefore.hasMatch(head)) continue;

        final fused = _fusedLetters.firstMatch(head);
        if (fused != null) {
          final letters = fused.group(1)!.toLowerCase();
          if (letters != 'rs' && letters != 'inr') continue;
        }

        final nearMrp = mrpEnds.any(
          (anchorEnd) => start >= anchorEnd && start - anchorEnd <= 150,
        );

        final currencyPrefix = _currencyPrefix.hasMatch(head);

        candidates.add(
          _PriceCandidate(
            value: v,
            position: start,
            nearMrp: nearMrp,
            currencyPrefix: currencyPrefix,
          ),
        );
      }

      debugPrint(
        '[MrpOcr] candidates:\n'
        '${candidates.map((c) => '  ${c.value}  mrp=${c.nearMrp}  cur=${c.currencyPrefix}').join("\n")}',
      );

      if (candidates.isEmpty) {
        debugPrint('[MrpOcr] no candidates survived filtering');
        return null;
      }

      int score(_PriceCandidate c) =>
          (c.nearMrp ? 2 : 0) + (c.currencyPrefix ? 1 : 0);

      candidates.sort((a, b) {
        final diff = score(b) - score(a);
        if (diff != 0) return diff;

        return b.value.compareTo(a.value);
      });

      final best = candidates.first;
      if (score(best) == 0) {
        debugPrint(
          '[MrpOcr] top candidate (${best.value}) has score=0, bailing',
        );
        return null;
      }

      debugPrint(
        '[MrpOcr] selected ${best.value} '
        '(nearMrp=${best.nearMrp}, currency=${best.currencyPrefix})',
      );
      return best.value;
    } catch (e, st) {
      debugPrint('[MrpOcr] error: $e');
      debugPrint('$st');
      return null;
    } finally {
      await recognizer.close();
    }
  }
}

class _PriceCandidate {
  _PriceCandidate({
    required this.value,
    required this.position,
    required this.nearMrp,
    required this.currencyPrefix,
  });

  final double value;
  final int position;
  final bool nearMrp;
  final bool currencyPrefix;
}
