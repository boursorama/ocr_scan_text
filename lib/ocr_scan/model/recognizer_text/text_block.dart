import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/recognizer_text.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_line.dart';

import '../shape/trapezoid.dart';

class BrsTextBlock extends BrsRecognizerText {
  final List<BrsTextLine> lines;

  BrsTextBlock({
    required String text,
    required this.lines,
    required Trapezoid trapezoid,
  }) : super(
          text: text,
          trapezoid: trapezoid,
        );

  /// Returns an instance of [BrsTextBlock] from a given [textBlock].
  factory BrsTextBlock.fromTextBlock(TextBlock textBlock) {
    List<BrsTextLine> lines = [];
    for (var line in textBlock.lines) {
      lines.add(BrsTextLine.fromTextLine(line));
    }
    return BrsTextBlock(
      text: textBlock.text,
      lines: lines,
      trapezoid: Trapezoid.fromCornerPoint(
        textBlock.cornerPoints,
      ),
    );
  }
}
