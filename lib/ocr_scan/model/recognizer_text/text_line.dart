import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml_kit;
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';

import '../shape/trapezoid.dart';

/// Represents a TextLine object of Ml Kit
class TextLine extends RecognizerText {
  final List<TextElement> elements;

  TextLine({
    required this.elements,
  }) : super(
          text: _generateText(elements),
          trapezoid: _generateTrapezoid(elements),
        );

  static String _generateText(List<TextElement> elements) {
    String text = '';
    for (var element in elements) {
      text += element == elements.first ? element.text : ' ${element.text}';
    }
    return text;
  }

  static Trapezoid _generateTrapezoid(List<TextElement> elements) {
    return Trapezoid.fromElementsList(elements);
  }

  factory TextLine.fromTextLine(
    ml_kit.TextLine textLine,
    Size imageSize,
  ) {
    List<TextElement> elements = [];
    for (var element in textLine.elements) {
      elements.add(TextElement.fromTextElement(
        element,
        imageSize,
      ));
    }
    return TextLine(
      elements: elements,
    );
  }

  TextLine copyWith({
    List<TextElement>? elements,
  }) {
    return TextLine(
      elements: elements ?? this.elements,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TextLine &&
      runtimeType == other.runtimeType &&
      trapezoid == other.trapezoid &&
      text == other.text &&
      elements == other.elements;

  @override
  int get hashCode => trapezoid.hashCode ^ text.hashCode ^ elements.hashCode;
}
