import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MrpOcrService {
  MrpOcrService();

  static final RegExp _mrpAnchor = RegExp(
    r'(?:Maximum\s*Retail\s*Price|M\s*\.?\s*R\s*\.?\s*P\s*\.?)',
    caseSensitive: false,
  );

  static final RegExp _numberRegex = RegExp(r'\d+(?:,\d{3})*(?:\.\d{1,2})?');

  static final RegExp _perUnitSlash = RegExp(
    r'^\s*/\s*(?:g|gm|gms|kg|mg|ml|l|litre|liter|oz|lb|pc|pcs|piece|serving|tab|tabs|tablet|tablets|cap|caps|capsule|capsules|100\s*(?:g|ml))\b',
    caseSensitive: false,
  );
  static final RegExp _perUnitWord = RegExp(
    r'^\s*per\s+(?:g|gm|gms|kg|ml|l|oz|serving|piece|pc|tab|tablet|cap|capsule)\b',
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

  static final RegExp _ocrCurrencyPrefix = RegExp(
    r'(?:^|[\s.])(?:f|r)\s*[:.]?\s*$',
    caseSensitive: false,
  );
  static final RegExp _explicitCurrencyAmount = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([0-9OoSsIl|Bb]+(?:[.,][0-9OoSsIl|Bb]{1,2})?)\s*(?:/-|/)?',
    caseSensitive: false,
  );
  static final RegExp _ocrStickerCurrencyAmount = RegExp(
    r'(?:^|[\s:])(?:[EeFfRr])\s*([0-9OoSsIl|Bb]+(?:[.,][0-9OoSsIl|Bb]{1,2})?)\s*(?:/-|/)?',
    caseSensitive: false,
  );
  static final RegExp _explicitMrpAmount = RegExp(
    r'(?:M\s*\.?\s*R\s*\.?\s*P\s*\.?|Maximum\s*Retail\s*Price(?:\s*[:.-])?)\s*'
    r'(?:Rs\.?|INR|₹)?\s*'
    r'([0-9OoSsIl|Bb]+(?:[.,][0-9OoSsIl|Bb]{1,2})?)\s*(?:/-|/)?',
    caseSensitive: false,
  );
  static final RegExp _currencyToken = RegExp(
    r'(?:Rs\.?|INR|₹)',
    caseSensitive: false,
  );
  static final RegExp _ocrCurrencyCue = RegExp(
    r'(?:^|[\s:])(?:[EeFfRr])\s*[0-9OoSsIl|Bb]',
    caseSensitive: false,
  );
  static final RegExp _amountToken = RegExp(
    r'([0-9OoSsIl|Bb]{1,5}(?:[.,][0-9OoSsIl|Bb]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _quantityToken = RegExp(
    r'\b(?:g|gm|gms|kg|mg|ml|l|litre|liter|pcs?|pieces?)\b',
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
      final textLines = recognized.blocks
          .expand((block) => block.lines)
          .toList();
      final lines = textLines
          .map((line) => line.text)
          .where((line) => line.trim().isNotEmpty)
          .toList();
      debugPrint('[MrpOcr] lines:\n${lines.join("\n")}');

      final text = rawText.replaceAllMapped(
        _dateRegex,
        (m) => ' ' * (m.end - m.start),
      );

      final mrpEnds = _mrpAnchor.allMatches(text).map((m) => m.end).toList();
      debugPrint('[MrpOcr] MRP anchor ends at: $mrpEnds');

      final candidates = <_PriceCandidate>[];
      final seenKeys = <String>{};

      void addCandidate({
        required double value,
        required int position,
        required bool nearMrp,
        required bool currencyPrefix,
        required int? distanceFromMrp,
        required bool hasDecimal,
        required int signalStrength,
      }) {
        final key = [
          value.toStringAsFixed(2),
          position,
          nearMrp ? '1' : '0',
          currencyPrefix ? '1' : '0',
          distanceFromMrp ?? -1,
          signalStrength,
        ].join('|');
        if (!seenKeys.add(key)) return;
        candidates.add(
          _PriceCandidate(
            value: value,
            position: position,
            nearMrp: nearMrp,
            currencyPrefix: currencyPrefix,
            distanceFromMrp: distanceFromMrp,
            hasDecimal: hasDecimal,
            signalStrength: signalStrength,
          ),
        );
      }

      for (final line in textLines) {
        final lineText = line.text.trim();
        if (lineText.isEmpty) continue;

        final lineBox = line.boundingBox;

        final hasMrpCue = _mrpAnchor.hasMatch(lineText);
        final hasCurrencyCue =
            _currencyToken.hasMatch(lineText) || _ocrCurrencyCue.hasMatch(lineText);
        final endsWithTinyMrpSymbol = hasMrpCue && RegExp(r'[.:\s][0-9Oo]$').hasMatch(lineText);

        if (!hasMrpCue && !hasCurrencyCue && !endsWithTinyMrpSymbol) {
          continue;
        }

        for (final candidateLine in textLines) {
          final candidateText = candidateLine.text.trim();
          if (candidateText.isEmpty) continue;
          if (identical(candidateLine, line)) continue;

          final candidateBox = candidateLine.boundingBox;
          if (!_isToRightOf(lineBox, candidateBox)) continue;
          if (!_isOnSameVisualRow(lineBox, candidateBox)) continue;
          if (_perUnitSlash.hasMatch(candidateText)) continue;
          if (_perUnitWord.hasMatch(candidateText)) continue;
          if (_weightUnit.hasMatch(candidateText)) continue;

          final amount = _extractBestAmount(candidateText);
          if (amount == null) continue;

          addCandidate(
            value: amount.value,
            position: amount.position,
            nearMrp: true,
            currencyPrefix: true,
            distanceFromMrp: 0,
            hasDecimal: amount.hasDecimal,
            signalStrength: 4,
          );
        }
      }

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final hasCurrency =
            _currencyToken.hasMatch(trimmed) || _ocrCurrencyCue.hasMatch(trimmed);
        final prevHasCurrency =
            i > 0 &&
            (_currencyToken.hasMatch(lines[i - 1].trim()) ||
                _ocrCurrencyCue.hasMatch(lines[i - 1].trim()));
        final nextLine = i + 1 < lines.length ? lines[i + 1].trim() : null;
        final lineHasMrp = _mrpAnchor.hasMatch(trimmed);
        final prevLineHasMrp = i > 0 && _mrpAnchor.hasMatch(lines[i - 1].trim());
        final nextLineHasMrp =
            nextLine != null && _mrpAnchor.hasMatch(nextLine.trim());

        if (!hasCurrency && !prevHasCurrency) {
          continue;
        }

        final amountSources = <String>[
          trimmed,
          ?nextLine,
        ];

        for (final source in amountSources) {
          if (_quantityToken.hasMatch(source) &&
              !_currencyToken.hasMatch(source) &&
              !_mrpAnchor.hasMatch(source)) {
            continue;
          }

          for (final match in _amountToken.allMatches(source)) {
            final rawAmount = match.group(1);
            if (rawAmount == null) continue;

            final normalizedAmount = _normalizeOcrAmount(rawAmount);
            final value = double.tryParse(normalizedAmount.replaceAll(',', '.'));
            if (value == null || value < 2 || value >= 100000) continue;

            final syntheticPosition = (i * 1000) + match.start;
            final nearMrp =
                lineHasMrp || prevLineHasMrp || nextLineHasMrp || hasCurrency || prevHasCurrency;

            addCandidate(
              value: value,
              position: syntheticPosition,
              nearMrp: nearMrp,
              currencyPrefix: hasCurrency || prevHasCurrency,
              distanceFromMrp: nearMrp ? 0 : null,
              hasDecimal: normalizedAmount.contains('.') || normalizedAmount.contains(','),
              signalStrength: hasCurrency ? 3 : (prevHasCurrency ? 2 : 1),
            );
          }
        }
      }

      for (final m in _explicitCurrencyAmount.allMatches(text)) {
        _addRegexCandidate(
          match: m,
          text: text,
          mrpEnds: mrpEnds,
          addCandidate: addCandidate,
          signalStrength: 5,
        );
      }

      for (final m in _ocrStickerCurrencyAmount.allMatches(text)) {
        _addRegexCandidate(
          match: m,
          text: text,
          mrpEnds: mrpEnds,
          addCandidate: addCandidate,
          signalStrength: 5,
        );
      }

      for (final m in _explicitMrpAmount.allMatches(text)) {
        _addRegexCandidate(
          match: m,
          text: text,
          mrpEnds: mrpEnds,
          addCandidate: addCandidate,
          signalStrength: 6,
        );
      }

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

        final distanceFromMrp = _distanceFromMrp(mrpEnds, start);
        final nearMrp = distanceFromMrp != null && distanceFromMrp <= 150;

        final currencyPrefix = _currencyPrefix.hasMatch(head);
        final ocrCurrencyPrefix = _ocrCurrencyPrefix.hasMatch(head);

        addCandidate(
          value: v,
          position: start,
          nearMrp: nearMrp,
          currencyPrefix: currencyPrefix || ocrCurrencyPrefix,
          distanceFromMrp: distanceFromMrp,
          hasDecimal: raw.contains('.') || raw.contains(','),
          signalStrength: (currencyPrefix || ocrCurrencyPrefix) ? 3 : 1,
        );
      }

      debugPrint(
        '[MrpOcr] candidates:\n'
        '${candidates.map((c) => '  ${c.value}  mrp=${c.nearMrp}  cur=${c.currencyPrefix}  dist=${c.distanceFromMrp}  sig=${c.signalStrength}').join("\n")}',
      );

      if (candidates.isEmpty) {
        debugPrint('[MrpOcr] no candidates survived filtering');
        return null;
      }

      final hasStrongMrpPrice = candidates.any(
        (c) =>
            c.nearMrp &&
            c.value >= 10 &&
            (c.currencyPrefix || c.hasDecimal || c.signalStrength >= 4),
      );
      if (hasStrongMrpPrice) {
        candidates.removeWhere(
          (c) =>
              c.value < 10 &&
              c.signalStrength < 4 &&
              (!c.currencyPrefix || !c.hasDecimal),
        );
      }

      final hasExplicitCurrencyPrice = candidates.any(
        (c) => c.signalStrength >= 5 && c.value >= 10,
      );
      if (hasExplicitCurrencyPrice) {
        candidates.removeWhere(
          (c) =>
              c.signalStrength <= 1 &&
              !c.hasDecimal &&
              c.value > 500,
        );
      }

      int score(_PriceCandidate c) {
        var score = 0;
        score += c.signalStrength * 3;
        if (c.nearMrp) score += 4;
        if (c.currencyPrefix) score += 4;
        if (c.hasDecimal) score += 2;
        if (c.value >= 10 && c.value <= 5000) score += 1;
        if (c.signalStrength >= 5 && c.value >= 10 && c.value <= 5000) {
          score += 3;
        }
        if (c.signalStrength >= 5 && c.value < 10) {
          score -= 6;
        }
        if (c.value > 9999 && c.signalStrength <= 2) {
          score -= 6;
        }
        if (c.nearMrp && !c.currencyPrefix && !c.hasDecimal && c.value < 10) {
          score -= 3;
        }
        return score;
      }

      candidates.sort((a, b) {
        final diff = score(b) - score(a);
        if (diff != 0) return diff;

        final aDistance = a.distanceFromMrp ?? 1 << 30;
        final bDistance = b.distanceFromMrp ?? 1 << 30;
        final distanceDiff = aDistance.compareTo(bDistance);
        if (distanceDiff != 0) return distanceDiff;

        return a.position.compareTo(b.position);
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

bool _isToRightOf(Rect anchor, Rect candidate) {
  return candidate.left >= anchor.right - (anchor.width * 0.25);
}

bool _isOnSameVisualRow(Rect anchor, Rect candidate) {
  final anchorCenterY = anchor.top + (anchor.height / 2);
  final candidateCenterY = candidate.top + (candidate.height / 2);
  final delta = (anchorCenterY - candidateCenterY).abs();
  final tolerance = (anchor.height + candidate.height) * 0.75;
  return delta <= tolerance;
}

_ParsedAmount? _extractBestAmount(String text) {
  _ParsedAmount? best;
  for (final match in MrpOcrService._amountToken.allMatches(text)) {
    final rawAmount = match.group(1);
    if (rawAmount == null) continue;

    final normalizedAmount = _normalizeOcrAmount(rawAmount);
    final value = double.tryParse(normalizedAmount.replaceAll(',', '.'));
    if (value == null || value < 2 || value >= 100000) continue;

    final parsed = _ParsedAmount(
      value: value,
      position: match.start,
      hasDecimal:
          normalizedAmount.contains('.') || normalizedAmount.contains(','),
    );
    if (best == null) {
      best = parsed;
      continue;
    }

    if (parsed.hasDecimal && !best.hasDecimal) {
      best = parsed;
      continue;
    }

    if (parsed.position < best.position) {
      best = parsed;
    }
  }
  return best;
}

int? _distanceFromMrp(List<int> mrpEnds, int start) {
  int? best;
  for (final anchorEnd in mrpEnds) {
    if (start < anchorEnd) continue;
    final distance = start - anchorEnd;
    if (best == null || distance < best) best = distance;
  }
  return best;
}

void _addRegexCandidate({
  required RegExpMatch match,
  required String text,
  required List<int> mrpEnds,
  required void Function({
    required double value,
    required int position,
    required bool nearMrp,
    required bool currencyPrefix,
    required int? distanceFromMrp,
    required bool hasDecimal,
    required int signalStrength,
  })
  addCandidate,
  required int signalStrength,
}) {
  final rawAmount = match.group(1);
  if (rawAmount == null) return;

  final normalizedAmount = _normalizeOcrAmount(rawAmount);
  final value = double.tryParse(normalizedAmount.replaceAll(',', '.'));
  if (value == null || value < 2 || value >= 100000) return;

  final start = match.start;
  final end = match.end;
  final tail = text.substring(end, (end + 20).clamp(0, text.length));

  if (MrpOcrService._perUnitSlash.hasMatch(tail)) return;
  if (MrpOcrService._perUnitWord.hasMatch(tail)) return;
  if (MrpOcrService._weightUnit.hasMatch(tail)) return;

  final distanceFromMrp = _distanceFromMrp(mrpEnds, start);

  addCandidate(
    value: value,
    position: start,
    nearMrp: distanceFromMrp != null && distanceFromMrp <= 150,
    currencyPrefix: true,
    distanceFromMrp: distanceFromMrp,
    hasDecimal: normalizedAmount.contains('.') || normalizedAmount.contains(','),
    signalStrength: signalStrength,
  );
}

String _normalizeOcrAmount(String raw) {
  return raw
      .replaceAll(RegExp(r'[OoQqDd]'), '0')
      .replaceAll(RegExp(r'[Ss]'), '5')
      .replaceAll(RegExp(r'[Il|]'), '1')
      .replaceAll(RegExp(r'[Bb]'), '8');
}

class _ParsedAmount {
  const _ParsedAmount({
    required this.value,
    required this.position,
    required this.hasDecimal,
  });

  final double value;
  final int position;
  final bool hasDecimal;
}

class _PriceCandidate {
  _PriceCandidate({
    required this.value,
    required this.position,
    required this.nearMrp,
    required this.currencyPrefix,
    required this.distanceFromMrp,
    required this.hasDecimal,
    required this.signalStrength,
  });

  final double value;
  final int position;
  final bool nearMrp;
  final bool currencyPrefix;
  final int? distanceFromMrp;
  final bool hasDecimal;
  final int signalStrength;
}
