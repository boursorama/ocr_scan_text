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
  int maxCorrelation;
  bool get started => _started;

  List<MatchedCounter> matchedCounterList = [];

  String label;
  Color color;

  ScanModule({
    required this.label,
    required this.color,
    this.validateCountCorrelation = 5,
    this.maxCorrelation = 10,
    this.distanceCorrelation = 30,
  });

  void start() {
    _started = true;
  }

  void stop() {
    _started = false;
  }

  Future<List<ScanResult>> matchedScanLines(
    List<BrsTextBlock> textBlock,
    String text,
  );

  bool _matchedStringAndPosition(
    ScanResult newScanLine,
    ScanResult oldScanLine,
  ) {
    if (newScanLine.block.text == oldScanLine.block.text) {
      if (_isBetween(
              newScanLine.block.rect.topLeftOffset.dx,
              oldScanLine.block.rect.topLeftOffset.dx - distanceCorrelation,
              oldScanLine.block.rect.topLeftOffset.dx + distanceCorrelation) &&
          _isBetween(
              newScanLine.block.rect.topLeftOffset.dy,
              oldScanLine.block.rect.topLeftOffset.dy - distanceCorrelation,
              oldScanLine.block.rect.topLeftOffset.dy + distanceCorrelation)) {
        return true;
      }
    }
    return false;
  }

  List<BrsTextBlock> _convertTextBlocks(List<TextBlock> textBlock) {
    List<BrsTextBlock> brsTextBlock = [];
    for (var block in textBlock) {
      brsTextBlock.add(BrsTextBlock.fromTextBlock(block));
    }
    return brsTextBlock;
  }

  Future<List<MatchedCounter>> generateScanLines(
    List<TextBlock> textBlock,
    String text,
  ) async {
    if (_busyGenerated) {
      return matchedCounterList;
    }
    _busyGenerated = true;

    List<ScanResult> tempMatched = await matchedScanLines(
      _convertTextBlocks(textBlock),
      text,
    );

    List<MatchedCounter> newProgressMatched = [];
    for (var scanLine in tempMatched) {
      bool found = false;
      for (var element in matchedCounterList) {
        if (_matchedStringAndPosition(element.scanResult, scanLine)) {
          element.upCounter();
          element.scanResult.block = scanLine.block;
          element.scanResult.visible = true;
          newProgressMatched.add(element);
          found = true;
        }
      }
      if (found == false) {
        newProgressMatched.add(
          MatchedCounter(
            scanResult: ScanResult(
              block: scanLine.block,
              visible: true,
              validated: true,
            ),
            maxCorrelation: maxCorrelation,
            validateCountCorrelation: validateCountCorrelation,
            color: color,
          ),
        );
      }
    }

    for (var element in matchedCounterList) {
      bool found = false;
      for (var scanLine in tempMatched) {
        if (_matchedStringAndPosition(scanLine, element.scanResult)) {
          found = true;
        }
      }
      if (found == false) {
        element.downCounter();
        newProgressMatched.add(element);
      }
    }

    for (var element in newProgressMatched) {
      if (element.counter >= validateCountCorrelation) {
        matchedCounterList.removeWhere(
          (counterMatch) => _matchedStringAndPosition(
            counterMatch.scanResult,
            element.scanResult,
          ),
        );
        element.scanResult.validated = true;
        matchedCounterList.add(element);
      } else if (element.counter >= 0) {
        matchedCounterList.removeWhere(
          (counterMatch) => _matchedStringAndPosition(
            counterMatch.scanResult,
            element.scanResult,
          ),
        );
        element.scanResult.validated = false;
        matchedCounterList.add(element);
      } else {
        matchedCounterList.removeWhere(
          (counterMatch) => _matchedStringAndPosition(
            counterMatch.scanResult,
            element.scanResult,
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
