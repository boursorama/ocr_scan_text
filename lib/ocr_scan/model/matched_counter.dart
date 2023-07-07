import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/scan_result.dart';

class MatchedCounter {
  ScanResult scanResult;
  int _counter = 1;
  int validateCountCorrelation;
  int get counter => _counter;
  Color color;
  bool visible = false;
  bool validated = false;

  MatchedCounter({
    required this.scanResult,
    required this.validateCountCorrelation,
    required this.color,
  }) {
    _updateState();
  }

  int get maxCorrelation {
    return max(validateCountCorrelation * 2, 5);
  }

  void _updateState() {
    if (_counter < 0) {
      visible = false;
    } else {
      visible = true;
    }

    if (_counter < validateCountCorrelation) {
      validated = false;
    } else {
      validated = true;
    }
  }

  void downCounter() {
    _counter--;
    _updateState();
  }

  void upCounter() {
    _counter = min(_counter + 1, maxCorrelation);
    _updateState();
  }

  double progressCorrelation() {
    int correlation = validateCountCorrelation > 0 ? validateCountCorrelation : 1;
    return ((_counter / correlation) * 100) > 100 ? 100 : (_counter / correlation) * 100;
  }

  Color actualColor() {
    double progress = progressCorrelation();
    return progress == 100 && validated
        ? color
        : Color.lerp(
              color.withOpacity(0.0),
              color.withOpacity(0.5),
              progress / 100,
            ) ??
            color;
  }
}
