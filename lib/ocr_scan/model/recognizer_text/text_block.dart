import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml_kit;
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_line.dart';

import '../shape/trapezoid.dart';

/// Represents a TextBlock object of Ml Kit
class TextBlock extends RecognizerText {
  final List<TextLine> lines;

  TextBlock({
    required this.lines,
  }) : super(
          text: _generateText(lines),
          trapezoid: _generateTrapezoid(lines),
        );

  static String _generateText(List<TextLine> lines) {
    String text = '';
    for (var line in lines) {
      text += line == lines.first ? '' : '\n';
      for (var element in line.elements) {
        text +=
            element == line.elements.first ? element.text : ' ${element.text}';
      }
    }
    return text;
  }

  static Trapezoid _generateTrapezoid(List<TextLine> lines) {
    List<TextElement> elements = [];
    for (var line in lines) {
      for (var element in line.elements) {
        elements.add(element);
      }
    }
    return Trapezoid.fromElementsList(elements);
  }

  /// Returns an instance of [TextBlock] from a given [textBlock].
  factory TextBlock.fromTextBlock(
    ml_kit.TextBlock textBlock,
    Size imageSize,
  ) {
    List<TextLine> lines = [];
    for (var line in textBlock.lines) {
      lines.add(TextLine.fromTextLine(
        line,
        imageSize,
      ));
    }
    return TextBlock(
      lines: lines,
    );
  }

  TextBlock copyWith({
    List<TextLine>? lines,
  }) {
    return TextBlock(
      lines: lines ?? this.lines,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TextBlock &&
      runtimeType == other.runtimeType &&
      trapezoid == other.trapezoid &&
      text == other.text &&
      lines == other.lines;

  @override
  int get hashCode => trapezoid.hashCode ^ text.hashCode ^ lines.hashCode;
}
