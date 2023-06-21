import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as Img;

import '../model/matched_counter.dart';
import '../module/scan_module.dart';
import '../render/scan_renderer.dart';

class ScanWidget extends StatefulWidget {
  static bool DEBUG_MODE = false;

  final List<ScanModule> scanModules;
  final Function(ScanModule module, List<MatchedCounter> matchedCounterList) matchedResult;

  const ScanWidget({
    Key? key,
    required this.scanModules,
    required this.matchedResult,
  }) : super(key: key);

  @override
  ScanWidgetState createState() => ScanWidgetState();
}

class ScanWidgetState<T extends ScanWidget> extends State<T> {
  final TextRecognizer _textRecognizer = TextRecognizer();

  final bool _canProcess = true;
  bool _isBusy = false;
  bool converting = false;
  CustomPaint? customPaint;
  Img.Image? image;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  // Process image
  Future<void> processImage(InputImage inputImage, Size imageSize) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final recognizedText = await _textRecognizer.processImage(inputImage);
    String scannedText = '';
    List<TextElement> textBlocks = [];
    for (final textBunk in recognizedText.blocks) {
      for (final element in textBunk.lines) {
        for (final textBlock in element.elements) {
          textBlocks.add(textBlock);
          scannedText += " ${textBlock.text}";
        }
      }
    }

    Map<ScanModule, List<MatchedCounter>> mapModule = <ScanModule, List<MatchedCounter>>{};
    for (var scanModule in widget.scanModules) {
      if (!scanModule.started) {
        continue;
      }
      List<MatchedCounter> scanLines = await scanModule.generateScanLines(
        recognizedText.blocks,
        scannedText,
      );

      mapModule.putIfAbsent(
        scanModule,
        () => scanLines,
      );
    }

    var painter = ScanRenderer(
      mapScanModules: mapModule,
      imageRotation: inputImage.metadata?.rotation ?? InputImageRotation.rotation90deg, // TODO : A CORRIGER
      imageSize: imageSize,
    );

    customPaint = CustomPaint(painter: painter);

    mapModule.forEach((key, matchCounterList) {
      widget.matchedResult(
          key,
          matchCounterList
              .where(
                (matchCounter) => matchCounter.scanResult.validated == true,
              )
              .toList());
    });

    // await Future.delayed(Duration(seconds: 3));

    if (!converting) {
      _isBusy = false;
    }

    await _textRecognizer.close();
    if (mounted) {
      setState(() {});
    }
  }
}
