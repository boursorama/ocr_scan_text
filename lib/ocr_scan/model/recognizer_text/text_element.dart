import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';

import '../shape/trapezoid.dart';

class BrsTextElement extends BrsRecognizerText {
  BrsTextElement({
    required String text,
    required Trapezoid trapezoid,
  }) : super(
          text: text,
          trapezoid: trapezoid,
        );

  factory BrsTextElement.fromTextElement(TextElement textElement) {
    return BrsTextElement(
      text: textElement.text,
      trapezoid: Trapezoid.fromCornerPoint(
        textElement.cornerPoints,
      ),
    );
  }
}
