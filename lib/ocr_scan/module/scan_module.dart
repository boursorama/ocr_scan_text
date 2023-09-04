import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml_kit;
import 'package:ocr_scan_text/ocr_scan/helper/math_helper.dart';
import 'package:ocr_scan_text/ocr_scan/model/scan_match_counter.dart';

import '../model/recognizer_text/text_block.dart';
import '../model/scan_result.dart';

abstract class ScanModule {
  /// The distance at which an object can be identified as the same (camera moves)
  ///  - If distanceCorrelation is too small, it will invalidate old results due to camera movement.
  ///  - If distanceCorrelation is too large, similar results at different positions may be confused.
  /// The value is to be adapted according to what you are trying to do.
  double distanceCorrelation;

  /// The minimum number of times the same result must be found in the same place to validate
  /// ( Must be > 0 )
  int validateCountCorrelation;

  /// Module status; started or stopped
  bool _started = false;
  bool get started => _started;

  /// If the module is already in use, the image will not be processed
  bool _busyGenerated = false;

  /// The last list of results found by the module
  List<ScanMatchCounter> matchedCounterList = [];

  /// Module name (The name will be displayed in the final rendering)
  String? label;

  /// Module color (the color will be displayed in the final rendering)
  Color color;

  ScanModule({
    this.label,
    this.color = Colors.transparent,
    this.validateCountCorrelation = 5,
    this.distanceCorrelation = 0,
  }) {
    assert(validateCountCorrelation > 0);
  }

  /// Start the module
  void start() {
    _started = true;
  }

  /// Stop the module
  void stop() {
    _started = false;
  }

  /// Method to be defined in each module to process the text found in the image and output a list of results
  Future<List<ScanResult>> matchedResult(
    List<TextBlock> textBlock,
    String text,
  );

  /// Return true if the text's position is the same
  /// Compare the "topLeftOffset" positions of the elements.
  /// The "topLeftOffset" must be between -distanceCorrelation and +distanceCorrelation
  bool _matchedStringAndPosition(
    ScanResult newScanLine,
    ScanResult oldScanLine,
  ) {
    if (newScanLine.cleanedText == oldScanLine.cleanedText) {
      if (MathHelper.isBetween(
              newScanLine.trapezoid.topLeftOffset.dx,
              oldScanLine.trapezoid.topLeftOffset.dx - distanceCorrelation,
              oldScanLine.trapezoid.topLeftOffset.dx + distanceCorrelation) &&
          MathHelper.isBetween(
              newScanLine.trapezoid.topLeftOffset.dy,
              oldScanLine.trapezoid.topLeftOffset.dy - distanceCorrelation,
              oldScanLine.trapezoid.topLeftOffset.dy + distanceCorrelation)) {
        return true;
      }
    }
    return false;
  }

  /// Convert MlKit TextBlock to BrsTextBlock to ignore MLKit
  List<TextBlock> _convertTextBlocks(
    List<ml_kit.TextBlock> textBlock,
    Size imageSize,
  ) {
    List<TextBlock> brsTextBlock = [];
    for (var block in textBlock) {
      brsTextBlock.add(TextBlock.fromTextBlock(
        block,
        imageSize,
      ));
    }
    return brsTextBlock;
  }

  /// Launches the module result search then updates the list of old results
  Future<List<ScanMatchCounter>> generateResult(
    List<ml_kit.TextBlock> textBlock,
    String text,
    Size imageSize,
  ) async {
    if (_busyGenerated) {
      return matchedCounterList;
    }
    _busyGenerated = true;

    List<ScanResult> newScanResult = await matchedResult(
      _convertTextBlocks(
        textBlock,
        imageSize,
      ),
      text,
    );

    /// We update the visibility counters of the MatchedCounter objects:
    /// - If still present in the new list, we up the counter
    /// - If not present, we down the counter and we delete if no longer visible
    List<ScanMatchCounter> matchedCounterListUpdated = [];
    for (var element in matchedCounterList) {
      bool found = false;
      for (var scanResult in newScanResult) {
        if (_matchedStringAndPosition(element.scanResult, scanResult)) {
          found = true;
          element.scanResult = scanResult;
          element.upCounter();
        }
      }
      if (!found) {
        element.downCounter();
      }

      if (element.visible) {
        matchedCounterListUpdated.add(element);
      }
    }
    matchedCounterList = matchedCounterListUpdated;

    /// We add the new unknown values in matchedCounterList
    for (var scanResult in newScanResult) {
      bool found = false;
      for (var element in matchedCounterList) {
        if (_matchedStringAndPosition(element.scanResult, scanResult)) {
          found = true;
        }
      }
      if (!found) {
        matchedCounterList.add(
          ScanMatchCounter(
            scanResult: scanResult,
            validateCountCorrelation: validateCountCorrelation,
            color: color,
          ),
        );
      }
    }
    _busyGenerated = false;
    return matchedCounterList;
  }
}
