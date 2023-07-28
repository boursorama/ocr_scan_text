import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';

import '../shape/trapezoid.dart';

/// Represents a TextLine object of Ml Kit
class BrsTextLine extends BrsRecognizerText {
  final List<BrsTextElement> elements;

  BrsTextLine({
    required this.elements,
  }) : super(
          text: _generateText(elements),
          trapezoid: _generateTrapezoid(elements),
        );

  static String _generateText(List<BrsTextElement> elements) {
    String text = '';
    for (var element in elements) {
      text += element == elements.first ? element.text : ' ${element.text}';
    }
    return text;
  }

  static Trapezoid _generateTrapezoid(List<BrsTextElement> elements) {
    return Trapezoid.fromElementsList(elements);
  }

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
      elements: elements,
    );
  }

  BrsTextLine copyWith({
    List<BrsTextElement>? elements,
  }) {
    return BrsTextLine(
      elements: elements ?? this.elements,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BrsTextLine &&
      runtimeType == other.runtimeType &&
      trapezoid == other.trapezoid &&
      text == other.text &&
      elements == other.elements;

  @override
  int get hashCode => trapezoid.hashCode ^ text.hashCode ^ elements.hashCode;
}
