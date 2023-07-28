import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/widget/scan_widget.dart';

class Trapezoid {
  Offset topLeftOffset;
  Offset bottomLeftOffset;
  Offset topRightOffset;
  Offset bottomRightOffset;
  Trapezoid({
    required this.topLeftOffset,
    required this.bottomLeftOffset,
    required this.topRightOffset,
    required this.bottomRightOffset,
  });

  /// Cconvert cornerPoints from MlKit to Offset
  /// (We also "fix" the axis problem on android)
  static Offset _initPointToOffset(
    Point<int> point,
    Size imageSize,
  ) {
    /// The cornersPoints, with Android, have positions that differ from the main axes
    /// X and Y are inverted and the 0 of the inverted axis is at imageSize.height
    /// Just with camera
    if (Platform.isAndroid && ScanWidget.actualMode == Mode.camera) {
      return Offset(
        imageSize.height - point.y.toDouble(),
        point.x.toDouble(),
      );
    }

    return Offset(
      point.x.toDouble(),
      point.y.toDouble(),
    );
  }

  /// Convert list of 4 cornersPoints from MlKit to Trapezoid
  factory Trapezoid.fromCornerPoint(
    List<Point<int>> cornerPoints,
    Size imageSize,
  ) {
    return Trapezoid(
      topLeftOffset: _initPointToOffset(
        cornerPoints[0],
        imageSize,
      ),
      topRightOffset: _initPointToOffset(
        cornerPoints[1],
        imageSize,
      ),
      bottomRightOffset: _initPointToOffset(
        cornerPoints[2],
        imageSize,
      ),
      bottomLeftOffset: _initPointToOffset(
        cornerPoints[3],
        imageSize,
      ),
    );
  }

  /// Resize Trapezoid to scaled image
  Trapezoid resizedTrapezoid(
    Size size,
    Size inputImageSize,
    InputImageRotation rotation,
    double paddingWidth,
    double paddingHeight,
    double? adjustTranslateX,
    double? adjustTranslateY,
  ) {
    return Trapezoid(
      topLeftOffset: Offset(
        _translateX(
          topLeftOffset.dx - paddingWidth,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateX ?? 0),
        ),
        _translateY(
          topLeftOffset.dy - paddingHeight,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateY ?? 0),
        ),
      ),
      bottomLeftOffset: Offset(
        _translateX(
          bottomLeftOffset.dx - paddingWidth,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateX ?? 0),
        ),
        _translateY(
          bottomLeftOffset.dy + paddingHeight,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateY ?? 0),
        ),
      ),
      topRightOffset: Offset(
        _translateX(
          topRightOffset.dx + paddingWidth,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateX ?? 0),
        ),
        _translateY(
          topRightOffset.dy - paddingHeight,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateY ?? 0),
        ),
      ),
      bottomRightOffset: Offset(
        _translateX(
          bottomRightOffset.dx + paddingWidth,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateX ?? 0),
        ),
        _translateY(
          bottomRightOffset.dy + paddingHeight,
          rotation,
          size,
          inputImageSize,
          (adjustTranslateY ?? 0),
        ),
      ),
    );
  }

  double _translateX(
    double x,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
    double adjustTranslate,
  ) {
    double denominator = Platform.isIOS || (Platform.isAndroid && ScanWidget.actualMode == Mode.static)
        ? absoluteImageSize.width
        : absoluteImageSize.height;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return (x * size.width / denominator) + adjustTranslate;
      case InputImageRotation.rotation270deg:
        return (size.width - x * size.width / denominator) + adjustTranslate;
      default:
        return (x * size.width / absoluteImageSize.width) + adjustTranslate;
    }
  }

  double _translateY(
    double y,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
    double adjustTranslate,
  ) {
    double denominator = Platform.isIOS || (Platform.isAndroid && ScanWidget.actualMode == Mode.static)
        ? absoluteImageSize.height
        : absoluteImageSize.width;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return (y * size.height / denominator) + adjustTranslate;
      default:
        return (y * size.height / absoluteImageSize.height) + adjustTranslate;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Trapezoid &&
      runtimeType == other.runtimeType &&
      topLeftOffset == other.topLeftOffset &&
      topRightOffset == other.topRightOffset &&
      bottomRightOffset == other.bottomRightOffset &&
      bottomLeftOffset == other.bottomLeftOffset;

  @override
  int get hashCode =>
      topLeftOffset.hashCode ^ topRightOffset.hashCode ^ bottomRightOffset.hashCode ^ bottomLeftOffset.hashCode;
}
