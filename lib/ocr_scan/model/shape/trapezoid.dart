import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml_kit;
import 'package:ocr_scan_text/ocr_scan/services/ocr_scan_service.dart';

import '../recognizer_text/text_element.dart';

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
    if (Platform.isAndroid && OcrScanService.actualMode == Mode.camera) {
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

  /// Return the global trapezoid containing the list of Offsets
  factory Trapezoid.fromElementsList(List<TextElement> elements) {
    List<Offset> offsets = [];
    for (TextElement element in elements) {
      offsets.add(element.trapezoid.topLeftOffset);
      offsets.add(element.trapezoid.bottomRightOffset);
      offsets.add(element.trapezoid.topRightOffset);
      offsets.add(element.trapezoid.bottomLeftOffset);
    }

    return Trapezoid.fromOffsetList(offsets);
  }

  /// Return the global trapezoid containing the list of Offsets
  factory Trapezoid.fromOffsetList(List<Offset> offsets) {
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;

    for (var offset in offsets) {
      left = min(left, offset.dx);
      top = min(top, offset.dy);
      right = max(right, offset.dx);
      bottom = max(bottom, offset.dy);
    }

    return Trapezoid(
      topLeftOffset: Offset(left, top),
      bottomLeftOffset: Offset(left, bottom),
      topRightOffset: Offset(right, top),
      bottomRightOffset: Offset(right, bottom),
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
    ml_kit.InputImageRotation rotation,
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
    ml_kit.InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
    double adjustTranslate,
  ) {
    double denominator = Platform.isIOS ||
            (Platform.isAndroid && OcrScanService.actualMode == Mode.static)
        ? absoluteImageSize.width
        : absoluteImageSize.height;
    switch (rotation) {
      case ml_kit.InputImageRotation.rotation90deg:
        return (x * size.width / denominator) + adjustTranslate;
      case ml_kit.InputImageRotation.rotation270deg:
        return (size.width - x * size.width / denominator) + adjustTranslate;
      default:
        return (x * size.width / absoluteImageSize.width) + adjustTranslate;
    }
  }

  double _translateY(
    double y,
    ml_kit.InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
    double adjustTranslate,
  ) {
    double denominator = Platform.isIOS ||
            (Platform.isAndroid && OcrScanService.actualMode == Mode.static)
        ? absoluteImageSize.height
        : absoluteImageSize.width;
    switch (rotation) {
      case ml_kit.InputImageRotation.rotation90deg:
      case ml_kit.InputImageRotation.rotation270deg:
        return (y * size.height / denominator) + adjustTranslate;
      default:
        return (y * size.height / absoluteImageSize.height) + adjustTranslate;
    }
  }

  bool isInside(Trapezoid outerTrapezoid) {
    return (topLeftOffset.dx >= outerTrapezoid.topLeftOffset.dx &&
        topRightOffset.dx <= outerTrapezoid.topRightOffset.dx &&
        bottomLeftOffset.dx >= outerTrapezoid.bottomLeftOffset.dx &&
        bottomRightOffset.dx <= outerTrapezoid.bottomRightOffset.dx &&
        topLeftOffset.dy >= outerTrapezoid.topLeftOffset.dy &&
        bottomLeftOffset.dy <= outerTrapezoid.bottomLeftOffset.dy &&
        topRightOffset.dy >= outerTrapezoid.topRightOffset.dy &&
        bottomRightOffset.dy <= outerTrapezoid.bottomRightOffset.dy);
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
      topLeftOffset.hashCode ^
      topRightOffset.hashCode ^
      bottomRightOffset.hashCode ^
      bottomLeftOffset.hashCode;
}
