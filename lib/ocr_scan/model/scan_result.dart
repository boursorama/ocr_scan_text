import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/shape/trapezoid.dart';

class ScanResult {
  final String? _cleanedText;
  List<BrsTextElement> scannedElementList;

  ScanResult({
    String? cleanedText,
    required this.scannedElementList,
  }) : _cleanedText = cleanedText;

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
      bottomRightOffset: Offset(
        right,
        bottom,
      ),
    );
  }

  String get cleanedText {
    return _cleanedText ?? text;
  }

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

  Trapezoid get trapezoid {
    List<Offset> offsets = [];
    for (BrsTextElement element in scannedElementList) {
      offsets.add(element.trapezoid.topLeftOffset);
      offsets.add(element.trapezoid.topRightOffset);
      offsets.add(element.trapezoid.bottomRightOffset);
      offsets.add(element.trapezoid.bottomLeftOffset);
    }
    return _findTrapezoid(offsets);
  }
}
