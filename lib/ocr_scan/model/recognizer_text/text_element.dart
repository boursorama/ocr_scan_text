import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';

import '../shape/trapezoid.dart';

/// Represents a TextElement object of Ml Kit
class BrsTextElement extends BrsRecognizerText {
  BrsTextElement({
    required String text,
    required Trapezoid trapezoid,
  }) : super(
          text: text,
          trapezoid: trapezoid,
        );

  factory BrsTextElement.fromTextElement(
    TextElement textElement,
    Size imageSize,
  ) {
    return BrsTextElement(
      text: textElement.text,
      trapezoid: Trapezoid.fromCornerPoint(
        textElement.cornerPoints,
        imageSize,
      ),
    );
  }

  BrsTextElement copyWith({
    String? text,
    Trapezoid? trapezoid,
  }) {
    return BrsTextElement(
      text: text ?? this.text,
      trapezoid: trapezoid ?? this.trapezoid,
    );
  }
}
