import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';

class ScannedText {
  String originalText;
  String scannedText;
  List<BrsTextElement> originalElementList;
  List<BrsTextElement> scannedElementList;

  ScannedText({
    required this.originalText,
    required this.scannedText,
    required this.originalElementList,
    required this.scannedElementList,
  });
}
