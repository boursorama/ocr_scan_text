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

  static Offset pointToOffset(Point<int> point) {
    return Offset(
      point.x.toDouble(),
      point.y.toDouble(),
    );
  }

  factory Trapezoid.fromCornerPoint(List<Point<int>> cornerPoints) {
    return Trapezoid(
      topLeftOffset: pointToOffset(cornerPoints[0]),
      bottomLeftOffset: pointToOffset(cornerPoints[3]),
      topRightOffset: pointToOffset(cornerPoints[1]),
      bottomRightOffset: pointToOffset(cornerPoints[2]),
    );
  }

  Trapezoid resizedTrapezoid(
    Size size,
    Size inputImageSize,
    InputImageRotation rotation,
    double margeWidth,
    double margeHeight,
  ) {
    /// TODO: CA MARCHE PAS TOUJOURS
    /// TODO: A TESTER EN LANDSCAPE
    /// C'est la merde sur android, il y a un soucis d'orientation entre
    /// la photo et le resultat de ml_kit :
    ///   - 1) Les valeurs x et y sont inversé, on inverse donc les valeurs
    ///   - 2) L'axe X est inversé, le 0 se trouve a size.width, on inverse les valeurs
    if (Platform.isAndroid) {
      return Trapezoid(
        topLeftOffset: Offset(
          size.width -
              _translateY(
                topLeftOffset.dy - margeHeight,
                rotation,
                size,
                inputImageSize,
              ),
          _translateX(
            topLeftOffset.dx - margeWidth,
            rotation,
            size,
            inputImageSize,
          ),
        ),
        bottomLeftOffset: Offset(
          size.width -
              _translateY(
                bottomLeftOffset.dy + margeHeight,
                rotation,
                size,
                inputImageSize,
              ),
          _translateX(
            bottomLeftOffset.dx - margeWidth,
            rotation,
            size,
            inputImageSize,
          ),
        ),
        topRightOffset: Offset(
          size.width -
              _translateY(
                topRightOffset.dy - margeHeight,
                rotation,
                size,
                inputImageSize,
              ),
          _translateX(
            topRightOffset.dx + margeWidth,
            rotation,
            size,
            inputImageSize,
          ),
        ),
        bottomRightOffset: Offset(
          size.width -
              _translateY(
                bottomRightOffset.dy + margeHeight,
                rotation,
                size,
                inputImageSize,
              ),
          _translateX(
            bottomRightOffset.dx + margeWidth,
            rotation,
            size,
            inputImageSize,
          ),
        ),
      );
    }

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
