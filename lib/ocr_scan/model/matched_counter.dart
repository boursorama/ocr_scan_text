import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/scan_result.dart';

class MatchedCounter {
  ScanResult scanResult;
  int _counter = 1;
  int validateCountCorrelation;
  int maxCorrelation;
  int get counter => _counter;
  Color color;

  MatchedCounter({
    required this.scanResult,
    required this.maxCorrelation,
    required this.validateCountCorrelation,
    required this.color,
  }) {
    _counter = validateCountCorrelation;
  }

  void downCounter() {
    _counter = _counter - 1;
  }

  void upCounter() {
    _counter = _counter + 3;
    if (_counter >= maxCorrelation) {
      _counter = maxCorrelation;
    }
  }

  double progressCorrelation() {
    int correlation = validateCountCorrelation > 0 ? validateCountCorrelation : 1;
    return ((_counter / correlation) * 100) > 100 ? 100 : (_counter / correlation) * 100;
  }

  Color actualColor() {
    double progress = progressCorrelation();
    return progress == 100 && scanResult.validated
        ? color
        : Color.lerp(
              color.withOpacity(0.0),
              color.withOpacity(0.5),
              progress / 100,
            ) ??
            color;
  }
}
