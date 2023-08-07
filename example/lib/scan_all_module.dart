import 'package:flutter/material.dart';
import 'package:ocr_scan_text/ocr_scan_text.dart';

class ScanAllModule extends ScanModule {
  ScanAllModule()
      : super(
          label: '',
          color: Colors.redAccent.withOpacity(0.3),
          validateCountCorrelation: 1,
        );

  @override
  Future<List<ScanResult>> matchedResult(
    List<TextBlock> textBlock,
    String text,
  ) async {
    List<ScanResult> list = [];
    for (var block in textBlock) {
      for (var line in block.lines) {
        for (var element in line.elements) {
          list.add(
            ScanResult(
              cleanedText: element.text,
              scannedElementList: [element],
            ),
          );
        }
      }
    }
    return list;
  }
}
