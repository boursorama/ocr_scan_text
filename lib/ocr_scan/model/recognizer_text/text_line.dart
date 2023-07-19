import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';

import '../shape/trapezoid.dart';

/// Permet de représenté un objet TextLine de MlKit
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

  factory BrsTextLine.fromTextLine(
    TextLine textLine,
    Size imageSize,
  ) {
    List<BrsTextElement> elements = [];
    for (var element in textLine.elements) {
      elements.add(BrsTextElement.fromTextElement(
        element,
        imageSize,
      ));
    }
    return BrsTextLine(
      text: textLine.text,
      elements: elements,
      trapezoid: Trapezoid.fromCornerPoint(
        textLine.cornerPoints,
        imageSize,
      ),
    );
  }

  BrsTextLine copyWith({
    String? text,
    List<BrsTextElement>? elements,
    Trapezoid? trapezoid,
  }) {
    return BrsTextLine(
      text: text ?? this.text,
      elements: elements ?? this.elements,
      trapezoid: trapezoid ?? this.trapezoid,
    );
  }
}
