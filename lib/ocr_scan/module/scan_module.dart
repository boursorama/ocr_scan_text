import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/matched_counter.dart';
import '../model/recognizer_text/text_block.dart';
import '../model/scan_result.dart';

abstract class ScanModule {
  /// Determine la distance a la quel un objet peut etre identifié comme un étant le meme (La camera se déplace)
  double distanceCorrelation;

  int validateCountCorrelation;

  bool _started = false;
  bool _busyGenerated = false;
  bool get started => _started;

  List<MatchedCounter> matchedCounterList = [];

  String? label;
  Color color;

  ScanModule({
    this.label,
    this.color = Colors.transparent,
    this.validateCountCorrelation = 5,
    this.distanceCorrelation = 30,
  }) {
    assert(validateCountCorrelation > 0);
  }

  void start() {
    _started = true;
  }

  void stop() {
    _started = false;
  }

  Future<List<ScanResult>> matchedResult(
    List<BrsTextBlock> textBlock,
    String text,
  );

  bool _matchedStringAndPosition(
    ScanResult newScanLine,
    ScanResult oldScanLine,
  ) {
    if (newScanLine.cleanedText == oldScanLine.cleanedText) {
      if (_isBetween(
              newScanLine.trapezoid.topLeftOffset.dx,
              oldScanLine.trapezoid.topLeftOffset.dx - distanceCorrelation,
              oldScanLine.trapezoid.topLeftOffset.dx + distanceCorrelation) &&
          _isBetween(
              newScanLine.trapezoid.topLeftOffset.dy,
              oldScanLine.trapezoid.topLeftOffset.dy - distanceCorrelation,
              oldScanLine.trapezoid.topLeftOffset.dy + distanceCorrelation)) {
        return true;
      }
    }
    return false;
  }

  List<BrsTextBlock> _convertTextBlocks(
    List<TextBlock> textBlock,
    Size imageSize,
  ) {
    List<BrsTextBlock> brsTextBlock = [];
    for (var block in textBlock) {
      brsTextBlock.add(BrsTextBlock.fromTextBlock(
        block,
        imageSize,
      ));
    }
    return brsTextBlock;
  }

  Future<List<MatchedCounter>> generateScanLines(
    List<TextBlock> textBlock,
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

    /// On met a jour les counter de visibilité des objets MatchedCounter :
    /// - Si toujours présent dans la nouvelle liste, on up
    /// - Si non présent, on down et on supprime si plus visible
    List<MatchedCounter> matchedCounterListUpdated = [];
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

    /// On ajoute les nouvelles valeurs non connu dans matchedCounterList
    for (var scanResult in newScanResult) {
      bool found = false;
      for (var element in matchedCounterList) {
        if (_matchedStringAndPosition(element.scanResult, scanResult)) {
          found = true;
        }
      }
      if (!found) {
        matchedCounterList.add(
          MatchedCounter(
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

  bool _isBetween(num value, num from, num to) {
    return from < value && value < to;
  }
}
