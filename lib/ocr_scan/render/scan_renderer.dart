import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/model/scan_match_counter.dart';

import '../model/shape/trapezoid.dart';
import '../module/scan_module.dart';

/// Overlays the results found by the ScanModules
class ScanRenderer extends CustomPainter {
  /// Map containing each module and the list of associated results
  final Map<ScanModule, List<ScanMatchCounter>> mapScanModules;

  /// Orients the rendering according to the angle of the image
  final InputImageRotation imageRotation;

  /// Size of image
  final Size imageSize;

  ui.Image? background;

  ScanRenderer({
    required this.mapScanModules,
    required this.imageRotation,
    required this.imageSize,
    this.background,
  });

  Size paintBackground(Canvas canvas, Size size, ui.Image image) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(BoxFit.contain, imageSize, size);

    final Rect dstRect =
        Alignment.center.inscribe(sizes.destination, Offset.zero & size);
    canvas.drawImageRect(image, Offset.zero & imageSize, dstRect, Paint());
    return sizes.destination;
  }

  @override
  void paint(Canvas canvas, Size size) {
    ui.Image? background = this.background;
    Size? backgroundSize;
    if (background != null) {
      backgroundSize = paintBackground(canvas, size, background);
    }

    mapScanModules.forEach(
      (module, matchedCounterList) {
        for (ScanMatchCounter matchedCount in matchedCounterList) {
          if (!matchedCount.visible) {
            /// If the result is not visible, do nothing.
            continue;
          }

          /// Resize the trapezoid of the result to adapt it to the size of the preview of the camera
          double padding = 8;
          Trapezoid trapezoid =
              matchedCount.scanResult.trapezoid.resizedTrapezoid(
            backgroundSize ?? size,
            imageSize,
            imageRotation,
            padding,
            padding,
            backgroundSize != null
                ? (size.width - backgroundSize.width) / 2
                : 0,
            backgroundSize != null
                ? (size.height - backgroundSize.height) / 2
                : 0,
          );

          canvas = _setCanvasPosition(canvas, size, trapezoid);

          /// Calculate the angle between the topLeftOffset and the topRightOffset
          double angle = calculateAngle(
            Offset(
              trapezoid.topLeftOffset.dx.toDouble(),
              trapezoid.topLeftOffset.dy.toDouble(),
            ),
            Offset(
              trapezoid.topRightOffset.dx.toDouble(),
              trapezoid.topRightOffset.dy.toDouble(),
            ),
          );

          if (!angle.isFinite) {
            angle = 0;
          }

          /// Calculate the width according to the ratio width / angle.
          double lerp = lerpDouble(
                1,
                2.8, // arbitrary value
                ((angle < 0 ? -angle : angle) / 90) *
                    ((angle < 0 ? -angle : angle) / 90),
              ) ??
              1;

          /// idth calculated from modified canvas angle
          double width =
              (trapezoid.topRightOffset.dx - trapezoid.topLeftOffset.dx) * lerp;

          /// Height calculated from modified canvas angle
          double height =
              trapezoid.bottomRightOffset.dy - trapezoid.topRightOffset.dy;
          if (trapezoid.bottomLeftOffset.dy - trapezoid.topLeftOffset.dy >
              height) {
            height = trapezoid.bottomLeftOffset.dy - trapezoid.topLeftOffset.dy;
          }

          Paint paint = Paint()
            ..color = matchedCount.actualColor()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;

          double r = 15;
          RRect fullRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset((width) / 2, (height) / 2),
              width: width + padding,
              height: height + padding,
            ),
            Radius.circular(r),
          );
          canvas.drawRRect(
            fullRect,
            paint,
          );

          String? moduleLabel = module.label;
          if (moduleLabel != null && matchedCount.validated) {
            _paintLabel(
              canvas,
              moduleLabel,
              module.color,
            );
          } else if (!matchedCount.validated) {
            Paint paint = Paint()
              ..color = matchedCount.actualColor()
              ..style = PaintingStyle.fill
              ..strokeWidth = 0;
            RRect fullRect2 = RRect.fromRectAndRadius(
              Rect.fromPoints(
                Offset(
                  fullRect.left,
                  fullRect.top,
                ),
                Offset(
                  fullRect.right * (matchedCount.progressCorrelation() / 100),
                  fullRect.bottom,
                ),
              ),
              Radius.circular(r),
            );
            canvas.drawRRect(
              fullRect2,
              paint,
            );
          }
          canvas.restore();
        }
      },
    );
  }

  /// Draw the name of the module, if there is one, around the found result
  void _paintLabel(
    Canvas canvas,
    String label,
    Color color,
  ) {
    double r = 15;

    final paintBackground = Paint()
      // parametrize
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.clear;

    TextSpan span = TextSpan(
      style: TextStyle(
        color: color,
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
      ),
      text: label,
    );
    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    double margeX = 10;
    RRect fullRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset((tp.width / 2) + margeX, (tp.height / 2) - 18),
        width: tp.width + margeX,
        height: tp.height + 4,
      ),
      Radius.circular(r),
    );
    canvas.drawRRect(fullRect, paintBackground);
    final paintBackground2 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(fullRect, paintBackground2);
    tp.paint(
      canvas,
      Offset(margeX, -18),
    );
  }

  Canvas _setCanvasPosition(
    Canvas canvas,
    Size size,
    Trapezoid trapezoid,
  ) {
    /// Reset canvas
    canvas.saveLayer(Offset.zero & size, Paint());

    /// Translate canvas to initial position of Trapezoid
    canvas.translate(
      trapezoid.topLeftOffset.dx < trapezoid.bottomLeftOffset.dx
          ? trapezoid.topLeftOffset.dx
          : trapezoid.bottomLeftOffset.dx,
      trapezoid.topLeftOffset.dy.toDouble(),
    );

    /// Calculate the angle between the topLeftOffset and topRightOffset
    double angle = calculateAngle(
      Offset(
        trapezoid.topLeftOffset.dx.toDouble(),
        trapezoid.topLeftOffset.dy.toDouble(),
      ),
      Offset(
        trapezoid.topRightOffset.dx.toDouble(),
        trapezoid.topRightOffset.dy.toDouble(),
      ),
    );

    /// Rotate the canvas
    canvas.rotate(angle * (pi / 180));
    return canvas;
  }

  /// Returns the angle between two offsets
  double calculateAngle(Offset point1, Offset point2) {
    double deltaX = point2.dx - point1.dx;
    double deltaY = point2.dy - point1.dy;
    return atan2(deltaY, deltaX) * 180 / pi;
  }

  @override
  bool shouldRepaint(ScanRenderer oldDelegate) {
    return true;
  }
}
