import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml_kit;
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';

import '../shape/trapezoid.dart';

/// Represents a TextElement object of Ml Kit
class TextElement extends RecognizerText {
  TextElement({
    required String text,
    required Trapezoid trapezoid,
  }) : super(
          text: text,
          trapezoid: trapezoid,
        );

  factory TextElement.fromTextElement(
    ml_kit.TextElement textElement,
    Size imageSize,
  ) {
    return TextElement(
      text: textElement.text,
      trapezoid: Trapezoid.fromCornerPoint(
        textElement.cornerPoints,
        imageSize,
      ),
    );
  }

  TextElement copyWith({
    String? text,
    Trapezoid? trapezoid,
  }) {
    return TextElement(
      text: text ?? this.text,
      trapezoid: trapezoid ?? this.trapezoid,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TextElement &&
      runtimeType == other.runtimeType &&
      trapezoid == other.trapezoid &&
      text == other.text;

  @override
  int get hashCode => trapezoid.hashCode ^ text.hashCode;
}
