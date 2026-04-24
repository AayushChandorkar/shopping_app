import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Runs on-device OCR over a captured image of a product package and
/// extracts the printed MRP (Maximum Retail Price).
///
/// Strategy
/// --------
/// Indian packs often print the label and the value in two columns —
/// e.g. "MRP ₹:" on the left, "320.00   Rs.0.64/g" on the right. A naive
/// "MRP followed by a number" regex fails on this layout: the colon
/// breaks the anchor, and any fallback to "largest Rs-prefixed number"
/// incorrectly picks up the per-gram unit price (`Rs.0.64`) instead of
/// the MRP itself.
///
/// Instead, this extractor:
/// 1. Collects *every* number on the pack.
/// 2. Throws out anything that's obviously a weight, a rate (per-unit),
///    a date, a time, or a batch/lot code.
/// 3. Scores what's left: numbers within ~150 chars of an "MRP" anchor
///    get +2, numbers directly preceded by a currency marker get +1,
///    tie-breaker is the larger value (MRP is usually the biggest
///    price-shaped number on the pack).
class MrpOcrService {
  MrpOcrService();

  /// Anchors: "MRP", "M.R.P.", "M R P", "Maximum Retail Price".
  static final RegExp _mrpAnchor = RegExp(
    r'(?:Maximum\s*Retail\s*Price|M\s*\.?\s*R\s*\.?\s*P\s*\.?)',
    caseSensitive: false,
  );

  /// Matches a number, optionally with Indian-style thousands separators
  /// (`1,299`) and a 1–2 digit decimal tail.
  static final RegExp _numberRegex = RegExp(
    r'\d+(?:,\d{3})*(?:\.\d{1,2})?',
  );

  /// Suffixes that mean "per unit" — these rule out a number as being
  /// the MRP. E.g. `Rs.0.64/g`, `₹5/100ml`, `Rs.20 per kg`.
  static final RegExp _perUnitSlash = RegExp(
    r'^\s*/\s*(?:g|gm|gms|kg|mg|ml|l|litre|liter|oz|lb|pc|pcs|piece|serving|100\s*(?:g|ml))\b',
    caseSensitive: false,
  );
  static final RegExp _perUnitWord = RegExp(
    r'^\s*per\s+(?:g|gm|gms|kg|ml|l|oz|serving|piece|pc)\b',
    caseSensitive: false,
  );

  /// Weight / volume units directly after the number — `500g`, `250ml`,
  /// `1.5 L`.
  static final RegExp _weightUnit = RegExp(
    r'^\s*(?:gms?|kg|mg|mls?|litre|liter|l\b|oz|lb|g\b)',
    caseSensitive: false,
  );

  /// Part of a time (`22:00`).
  static final RegExp _timeColon = RegExp(r'^\s*:\s*\d');

  /// Date continuation after (`17` in `17/07/25`).
  static final RegExp _dateAfter = RegExp(r'^\s*[/\-]\s*\d');

  /// Date continuation before (`07` in `17/07`).
  static final RegExp _dateBefore = RegExp(r'[/\-]\s*$');

  /// Currency marker directly before — `Rs`, `Rs.`, `INR`, `₹`.
  static final RegExp _currencyPrefix = RegExp(
    r'(?:Rs\.?|INR|₹)\s*$',
    caseSensitive: false,
  );

  /// A letter run directly fused to the front of the number — used to
  /// spot batch codes like `MB170725` or `B12345`. If the letters aren't
  /// a known currency marker, the number is treated as a code, not a
  /// price.
  static final RegExp _fusedLetters = RegExp(r'([A-Za-z]+)$');

  /// Matches dates like `dd/mm/yy` or `dd-mm-yyyy` so we can scrub them
  /// before counting candidates (otherwise `17` from `17/07/25` survives
  /// because my `_dateAfter` check only sees one digit of lookahead).
  static final RegExp _dateRegex = RegExp(
    r'\b\d{1,2}\s*[/\-]\s*\d{1,2}\s*[/\-]\s*\d{2,4}\b',
  );

  /// Returns the best-guess MRP as a double, or `null` if nothing
  /// recognizable was found.
  Future<double?> extractMrpFromImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      final rawText = recognized.text;
      debugPrint('[MrpOcr] recognized text:\n$rawText');

      // Scrub out dates by replacing them with spaces of the same length
      // so positions don't shift. This saves the candidate loop from
      // having to reason about "is this `17` part of a date?".
      final text = rawText.replaceAllMapped(
        _dateRegex,
        (m) => ' ' * (m.end - m.start),
      );

      // 1. Find MRP anchor positions.
      final mrpEnds = _mrpAnchor.allMatches(text).map((m) => m.end).toList();
      debugPrint('[MrpOcr] MRP anchor ends at: $mrpEnds');

      // 2. Collect candidates.
      final candidates = <_PriceCandidate>[];
      for (final m in _numberRegex.allMatches(text)) {
        final raw = m.group(0)!;
        final v = double.tryParse(raw.replaceAll(',', ''));
        // A real MRP is almost never below ₹2 and almost never at or
        // above ₹1,00,000 for packaged goods.
        if (v == null || v < 2 || v >= 100000) continue;

        final start = m.start;
        final end = m.end;
        final tail = text.substring(
          end,
          (end + 16).clamp(0, text.length),
        );
        final head = text.substring(
          (start - 8).clamp(0, text.length),
          start,
        );

        if (_perUnitSlash.hasMatch(tail)) continue;
        if (_perUnitWord.hasMatch(tail)) continue;
        if (_weightUnit.hasMatch(tail)) continue;
        if (_timeColon.hasMatch(tail)) continue;
        if (_dateAfter.hasMatch(tail)) continue;
        if (_dateBefore.hasMatch(head)) continue;

        // Numbers fused to letters like `MB170725` or `B12345` are
        // almost always batch / lot codes — unless the letters are a
        // currency marker (`Rs320`, `INR320`).
        final fused = _fusedLetters.firstMatch(head);
        if (fused != null) {
          final letters = fused.group(1)!.toLowerCase();
          if (letters != 'rs' && letters != 'inr') continue;
        }

        // "Near MRP" means the anchor is at most 150 chars before this
        // number — covers same-row layouts (tiny gap) as well as
        // column-split layouts where OCR puts the labels column first
        // and the values column second.
        final nearMrp = mrpEnds.any(
          (anchorEnd) =>
              start >= anchorEnd && start - anchorEnd <= 150,
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
        // Prefer the larger value: on Indian packs the MRP is usually
        // the biggest legitimate number.
        return b.value.compareTo(a.value);
      });

      final best = candidates.first;
      if (score(best) == 0) {
        // No anchors of any kind — too risky to return a guess.
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
