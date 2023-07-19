import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/shape/trapezoid.dart';

/// Représente un résultat trouvé par un module de scan
class ScanResult {
  /// Texte trouvé dans l'image; Il peut être différent du texte réel.
  /// Par exemple :
  /// - Texte réel : FR768792929389238923
  /// - cleanedText : FR768 7929 2938 9238 923
  final String? _cleanedText;

  /// Liste de tous les TextElements formant le résultat
  List<BrsTextElement> scannedElementList;

  ScanResult({
    String? cleanedText,
    required this.scannedElementList,
  }) : _cleanedText = cleanedText;

  /// Retourne _cleanedText si il existe, sinon le texte réel
  String get cleanedText {
    return _cleanedText ?? text;
  }

  /// Retourne le texte réel composé des TextElements
  String get text {
    String text = '';
    for (var textElement in scannedElementList) {
      if (scannedElementList.first != textElement) {
        text += ' ';
      }
      text += textElement.text;
    }
    return text;
  }

  /// Retourne le trapezoid global contenant la liste des TextElements
  Trapezoid get trapezoid {
    if (scannedElementList.isEmpty) {
      return Trapezoid(
        bottomLeftOffset: Offset.zero,
        bottomRightOffset: Offset.zero,
        topLeftOffset: Offset.zero,
        topRightOffset: Offset.zero,
      );
    }

    List<Offset> offsets = [];
    for (BrsTextElement element in scannedElementList) {
      offsets.add(element.trapezoid.topLeftOffset);
      offsets.add(element.trapezoid.bottomRightOffset);
      offsets.add(element.trapezoid.topRightOffset);
      offsets.add(element.trapezoid.bottomLeftOffset);
    }
    return _findTrapezoid(offsets);
  }

  /// Retourne un Trapezoid contenant tous les TextElements
  Trapezoid _findTrapezoid(List<Offset> offsets) {
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;

    for (var offset in offsets) {
      left = min(left, offset.dx);
      top = min(top, offset.dy);
      right = max(right, offset.dx);
      bottom = max(bottom, offset.dy);
    }

    return Trapezoid(
      topLeftOffset: Offset(left, top),
      bottomLeftOffset: Offset(left, bottom),
      topRightOffset: Offset(right, top),
      bottomRightOffset: Offset(right, bottom),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult && runtimeType == other.runtimeType && cleanedText == cleanedText && trapezoid == trapezoid;

  @override
  int get hashCode => cleanedText.hashCode ^ trapezoid.hashCode;
}
