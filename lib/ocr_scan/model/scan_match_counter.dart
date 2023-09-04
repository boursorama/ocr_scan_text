import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/scan_result.dart';

/// Determines the visibility and validity of the results found by the different modules
///   - For an element to be validated, the "_counter" must be equal to or greater than "validateCountCorrelation".
///   - For an element to be visible, the counter must be at least 1.
/// At each "frame", counter is updated.
class ScanMatchCounter {
  /// Scan module result found in image
  ScanResult scanResult;

  /// Determine the number of times he must find the same result in the same place to validate it
  int validateCountCorrelation;

  ///Number of times it found the result.it is incremented when the result has been found
  /// and decremented if not found. (Min: -1 , Max: maxCorrelation)
  int _counter = 1;
  int get counter => _counter;

  /// The maximum number before stopping to increment "counter".
  /// We avoid going too high to be able to quickly invalidate if the camera scans something else.
  /// ( Min : 5 , Max : validateCountCorrelation * 2 )
  int get maxCorrelation {
    return max(validateCountCorrelation * 2, 5);
  }

  /// The color to display during validation.
  Color color;

  /// Determines if the result is visible
  bool visible = false;

  /// Determines if the result is validated
  bool validated = false;

  ScanMatchCounter({
    required this.scanResult,
    required this.validateCountCorrelation,
    required this.color,
  }) {
    _updateState();
  }

  /// Update of visible and validated states
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

  /// Decrement "counter" if no result found
  void downCounter() {
    _counter--;
    _updateState();
  }

  /// Increment "counter" if the result was found
  void upCounter() {
    _counter = min(_counter + 1, maxCorrelation);
    _updateState();
  }

  /// Level of progress in % before validation of the result
  double progressCorrelation() {
    int correlation =
        validateCountCorrelation > 0 ? validateCountCorrelation : 1;
    return ((_counter / correlation) * 100) > 100
        ? 100
        : (_counter / correlation) * 100;
  }

  /// Return a color so the opacity is tied to the progress
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
