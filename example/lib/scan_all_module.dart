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
  Future<List<ScanResult>> matchedScanLines(
    List<BrsTextBlock> textBlock,
    String text,
  ) async {
    List<ScanResult> list = [];
    for (var block in textBlock) {
      for (var line in block.lines) {
        for (var element in line.elements) {
          list.add(
            ScanResult(
              block: TextBlockResult(
                element.text,
                BrsTextBlock(
                  text: element.text,
                  lines: [
                    BrsTextLine(
                      text: element.text,
                      elements: [element],
                      trapezoid: element.trapezoid,
                    )
                  ],
                  trapezoid: element.trapezoid,
                ),
              ),
              visible: true,
              validated: true,
            ),
          );
        }
      }
    }
    return list;
  }
}
