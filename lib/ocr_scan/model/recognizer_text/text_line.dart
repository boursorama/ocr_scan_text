import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';

import '../shape/trapezoid.dart';

class BrsTextLine extends BrsRecognizerText {
  final List<BrsTextElement> elements;

  BrsTextLine({
    required String text,
    required this.elements,
    required Trapezoid trapezoid,
  }) : super(
          text: text,
          trapezoid: trapezoid,
        );

  factory BrsTextLine.fromTextLine(TextLine textLine) {
    List<BrsTextElement> elements = [];
    for (var element in textLine.elements) {
      elements.add(BrsTextElement.fromTextElement(element));
    }
    return BrsTextLine(
      text: textLine.text,
      elements: elements,
      trapezoid: Trapezoid.fromCornerPoint(
        textLine.cornerPoints,
      ),
    );
  }
}
