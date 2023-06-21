import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_block_result.dart';

class ScanResult {
  TextBlockResult block;
  bool visible;
  bool validated;

  ScanResult({
    required this.block,
    this.visible = true,
    this.validated = false,
  });
}
