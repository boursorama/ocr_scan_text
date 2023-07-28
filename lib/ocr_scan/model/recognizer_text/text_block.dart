import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_line.dart';

import '../shape/trapezoid.dart';

/// Represents a TextBlock object of Ml Kit
class BrsTextBlock extends BrsRecognizerText {
  final List<BrsTextLine> lines;

  BrsTextBlock({
    required this.lines,
  }) : super(
          text: _generateText(lines),
          trapezoid: _generateTrapezoid(lines),
        );

  static String _generateText(List<BrsTextLine> lines) {
    String text = '';
    for (var line in lines) {
      text += line == lines.first ? '' : '\n';
      for (var element in line.elements) {
        text += element == line.elements.first ? element.text : ' ${element.text}';
      }
    }
    return text;
  }

  static Trapezoid _generateTrapezoid(List<BrsTextLine> lines) {
    List<BrsTextElement> elements = [];
    for (var line in lines) {
      for (var element in line.elements) {
        elements.add(element);
      }
    }
    return Trapezoid.fromElementsList(elements);
  }

  /// Returns an instance of [BrsTextBlock] from a given [textBlock].
  factory BrsTextBlock.fromTextBlock(
    TextBlock textBlock,
    Size imageSize,
  ) {
    List<BrsTextLine> lines = [];
    for (var line in textBlock.lines) {
      lines.add(BrsTextLine.fromTextLine(
        line,
        imageSize,
      ));
    }
    return BrsTextBlock(
      lines: lines,
    );
  }

  BrsTextBlock copyWith({
    List<BrsTextLine>? lines,
  }) {
    return BrsTextBlock(
      lines: lines ?? this.lines,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BrsTextBlock &&
      runtimeType == other.runtimeType &&
      trapezoid == other.trapezoid &&
      text == other.text &&
      lines == other.lines;

  @override
  int get hashCode => trapezoid.hashCode ^ text.hashCode ^ lines.hashCode;
}
