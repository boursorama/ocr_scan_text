import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_block.dart';

import '../shape/trapezoid.dart';

class TextBlockResult {
  final String text;
  final Trapezoid rect;

  TextBlockResult(
    this.text,
    BrsTextBlock block,
  ) : rect = block.trapezoid;
}
