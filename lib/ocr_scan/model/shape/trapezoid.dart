import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

  static Offset pointToOffset(
    Point<int> point,
    Size imageSize,
  ) {
    /// TODO: CA MARCHE PEUT ETRE PAS TOUJOURS
    /// TODO: A TESTER EN LANDSCAPE
    /// Sur android les cornersPoints ont des positions qui différe des axes principaux
    /// X et Y sont inversé et le 0 de l'axe inversé se trouve a imageSize.height
    if (Platform.isAndroid) {
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

  factory Trapezoid.fromCornerPoint(
    List<Point<int>> cornerPoints,
    Size imageSize,
  ) {
    return Trapezoid(
      topLeftOffset: pointToOffset(
        cornerPoints[0],
        imageSize,
      ),
      topRightOffset: pointToOffset(
        cornerPoints[1],
        imageSize,
      ),
      bottomRightOffset: pointToOffset(
        cornerPoints[2],
        imageSize,
      ),
      bottomLeftOffset: pointToOffset(
        cornerPoints[3],
        imageSize,
      ),
    );
  }

  Trapezoid resizedTrapezoid(
    Size size,
    Size inputImageSize,
    InputImageRotation rotation,
    double margeWidth,
    double margeHeight,
  ) {
    return Trapezoid(
      topLeftOffset: Offset(
        _translateX(
          topLeftOffset.dx - margeWidth,
          rotation,
          size,
          inputImageSize,
        ),
        _translateY(
          topLeftOffset.dy - margeHeight,
          rotation,
          size,
          inputImageSize,
        ),
      ),
      bottomLeftOffset: Offset(
        _translateX(
          bottomLeftOffset.dx - margeWidth,
          rotation,
          size,
          inputImageSize,
        ),
        _translateY(
          bottomLeftOffset.dy + margeHeight,
          rotation,
          size,
          inputImageSize,
        ),
      ),
      topRightOffset: Offset(
        _translateX(
          topRightOffset.dx + margeWidth,
          rotation,
          size,
          inputImageSize,
        ),
        _translateY(
          topRightOffset.dy - margeHeight,
          rotation,
          size,
          inputImageSize,
        ),
      ),
      bottomRightOffset: Offset(
        _translateX(
          bottomRightOffset.dx + margeWidth,
          rotation,
          size,
          inputImageSize,
        ),
        _translateY(
          bottomRightOffset.dy + margeHeight,
          rotation,
          size,
          inputImageSize,
        ),
      ),
    );
  }

  double _translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double _translateY(double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }
}
