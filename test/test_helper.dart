import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_block.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_line.dart';
import 'package:ocr_scan_text/ocr_scan/model/shape/trapezoid.dart';

class TestHelper {
  /// Return a BrsTextBlock starting at position startX and startY.
  /// For each '\n' in text, a BrsTextLine will be created.
  static TextBlock createTextBlock(String text, double startX, double startY) {
    List<String> splitByLine = text.split('\n');
    List<TextLine> linesList = [];
    for (var line in splitByLine) {
      List<String> splitElements = line.split(' ');
      List<TextElement> elementsList = [];
      for (var element in splitElements) {
        elementsList.add(
          TextElement(
            text: element,
            trapezoid: _createTrapezoid(
              startX: startX,
              startY: startY,
            ),
          ),
        );
        startX = elementsList.last.trapezoid.topRightOffset.dx + 10;
      }

      linesList.add(
        TextLine(
          elements: elementsList,
        ),
      );
      startY = linesList.last.trapezoid.bottomRightOffset.dx + 10;
    }

    return TextBlock(
      lines: linesList,
    );
  }

  static Trapezoid _createTrapezoid({
    required double startX,
    required double startY,
    double width = 10,
    double height = 10,
  }) {
    return Trapezoid(
      topLeftOffset: Offset(startX, startY),
      topRightOffset: Offset(startX + width, startY),
      bottomRightOffset: Offset(startX + width, startY + height),
      bottomLeftOffset: Offset(startX, startY + height),
    );
  }
}
