import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_block.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_line.dart';
import 'package:ocr_scan_text/ocr_scan/model/shape/trapezoid.dart';

class TestHelper {
  /// Return a BrsTextBlock starting at position startX and startY.
  /// For each '\n' in text, a BrsTextLine will be created.
  static BrsTextBlock createTextBlock(String text, double startX, double startY) {
    List<String> splitByLine = text.split('\n');
    List<BrsTextLine> linesList = [];
    for (var line in splitByLine) {
      List<String> splitElements = line.split(' ');
      List<BrsTextElement> elementsList = [];
      for (var element in splitElements) {
        elementsList.add(
          BrsTextElement(
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
        BrsTextLine(
          text: line,
          elements: elementsList,
          trapezoid: _createTrapezoid(
            startX: elementsList.first.trapezoid.topLeftOffset.dx,
            startY: elementsList.first.trapezoid.topLeftOffset.dy,
            width: elementsList.last.trapezoid.topRightOffset.dx - elementsList.first.trapezoid.topLeftOffset.dx,
          ),
        ),
      );
      startY = linesList.last.trapezoid.bottomRightOffset.dx + 10;
    }

    return BrsTextBlock(
      text: text,
      lines: linesList,
      trapezoid: _createTrapezoid(
        startX: linesList.first.trapezoid.topLeftOffset.dx,
        startY: linesList.first.trapezoid.topLeftOffset.dy,
        width: linesList.last.trapezoid.topRightOffset.dx - linesList.first.trapezoid.topLeftOffset.dx,
        height: linesList.last.trapezoid.bottomRightOffset.dy - linesList.first.trapezoid.topRightOffset.dy,
      ),
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
