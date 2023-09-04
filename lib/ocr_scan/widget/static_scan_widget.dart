import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ocr_scan_text/ocr_scan/services/ocr_scan_service.dart';
import 'package:ocr_scan_text/ocr_scan/widget/scan_widget.dart';

class StaticScanWidget extends ScanWidget {
  final File file;
  const StaticScanWidget({
    super.key,
    required super.scanModules,
    required super.ocrTextResult,
    required this.file,
    super.respectRatio = false,
  });

  @override
  StaticScanWidgetState createState() => StaticScanWidgetState();
}

class StaticScanWidgetState extends ScanWidgetState<StaticScanWidget> {
  @override
  void initState() {
    super.initState();
    _startProcess();
  }

  Future<void> _startProcess() async {
    OcrTextRecognizerResult? result =
        await OcrScanService(widget.scanModules).startScanProcess(widget.file);
    if (result == null) {
      return;
    }
    customPaint = result.customPaint;
    widget.ocrTextResult(result);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    CustomPaint? customPaint = this.customPaint;

    final size = MediaQuery.of(context).size;
    return customPaint == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SizedBox(
            width: size.width,
            height: size.height,
            child: customPaint,
          );
  }
}
