import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/matched_counter.dart';
import '../model/scan_result.dart';
import '../module/scan_module.dart';
import '../render/scan_renderer.dart';

class ScanWidget extends StatefulWidget {
  /// List of research modules
  final List<ScanModule> scanModules;

  /// Callback method returning the results found and validated
  final Function(ScanModule module, List<ScanResult> textBlockResult) matchedResult;

  const ScanWidget({
    Key? key,
    required this.scanModules,
    required this.matchedResult,
  }) : super(key: key);

  @override
  ScanWidgetState createState() => ScanWidgetState();
}

class ScanWidgetState<T extends ScanWidget> extends State<T> {
  /// MLKit text detection object
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Processing an image already in progress
  bool _isBusy = false;

  /// Overlay on the image of the different areas of the results coming from the modules
  CustomPaint? customPaint;

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

  /// Launch the search for results from the image for all the modules started
  Future<void> processImage(InputImage inputImage, Size imageSize) async {
    if (_isBusy) return;
    _isBusy = true;

    /// Ask MLKit to return the list of TextBlocks in the image
    final recognizedText = await _textRecognizer.processImage(inputImage);

    /// create a global String corresponding to the texts found by MLKIt
    String scannedText = '';
    List<TextElement> textBlocks = [];
    for (final textBlock in recognizedText.blocks) {
      for (final element in textBlock.lines) {
        for (final textBlock in element.elements) {
          textBlocks.add(textBlock);
          scannedText += " ${textBlock.text}";
        }
      }
    }

    /// Start the text search for each module
    Map<ScanModule, List<MatchedCounter>> mapModule = <ScanModule, List<MatchedCounter>>{};
    for (var scanModule in widget.scanModules) {
      if (!scanModule.started) {
        continue;
      }

      /// Generate the results of each module
      List<MatchedCounter> scanLines = await scanModule.generateResult(
        recognizedText.blocks,
        scannedText,
        imageSize,
      );

      mapModule.putIfAbsent(
        scanModule,
        () => scanLines,
      );
    }

    /// Create a ScanRenderer to display the visual rendering of the results found
    var painter = ScanRenderer(
      mapScanModules: mapModule,
      imageRotation: inputImage.metadata?.rotation ?? InputImageRotation.rotation90deg,
      imageSize: imageSize,
    );

    /// Update the customPaint with the ScanRenderer
    customPaint = CustomPaint(painter: painter);

    mapModule.forEach((key, matchCounterList) {
      List<ScanResult> list = matchCounterList
          .where(
            (matchCounter) => matchCounter.validated == true,
          )
          .map<ScanResult>((e) => e.scanResult)
          .toList();

      if (list.isNotEmpty) {
        /// Return the list of validated results with CallBack method
        widget.matchedResult(
          key,
          list,
        );
      }
    });

    _isBusy = false;
    await _textRecognizer.close();
    if (mounted) {
      setState(() {});
    }
  }
}
