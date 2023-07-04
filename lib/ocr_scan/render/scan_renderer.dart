import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/matched_counter.dart';
import '../model/shape/trapezoid.dart';
import '../module/scan_module.dart';

class ScanRenderer extends CustomPainter {
  final Map<ScanModule, List<MatchedCounter>> mapScanModules;
  final InputImageRotation imageRotation;
  final Size imageSize;
  ScanRenderer({
    required this.mapScanModules,
    required this.imageRotation,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    mapScanModules.forEach(
      (module, matchedCounterList) {
        for (MatchedCounter matchedCount in matchedCounterList) {
          if (!matchedCount.scanResult.visible) {
            continue;
          }

          double marge = 8;
          Trapezoid trapezoid = matchedCount.scanResult.block.rect.resizedTrapezoid(
            size,
            imageSize,
            imageRotation,
            marge,
            marge,
          );

          canvas.saveLayer(Offset.zero & size, Paint());
          canvas.translate(
            trapezoid.topLeftOffset.dx < trapezoid.bottomLeftOffset.dx
                ? trapezoid.topLeftOffset.dx
                : trapezoid.bottomLeftOffset.dx,
            trapezoid.topLeftOffset.dy.toDouble(),
          );
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
          canvas.rotate(angle * (pi / 180));

          /// Calcul de la width selon le ratio width / angle.
          double lerp = lerpDouble(
                1,
                2.8, // valeur arbitraire
                ((angle < 0 ? -angle : angle) / 90) * ((angle < 0 ? -angle : angle) / 90),
              ) ??
              1;

          double width = (trapezoid.topRightOffset.dx - trapezoid.topLeftOffset.dx) * lerp;

          double height = trapezoid.bottomRightOffset.dy - trapezoid.topRightOffset.dy;
          if (trapezoid.bottomLeftOffset.dy - trapezoid.topLeftOffset.dy > height) {
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
              width: width + marge,
              height: height + marge,
            ),
            Radius.circular(r),
          );
          canvas.drawRRect(
            fullRect,
            paint,
          );

          String? moduleLabel = module.label;
          if (moduleLabel != null && matchedCount.scanResult.validated) {
            paintNamed(
              canvas,
              moduleLabel,
              module.color,
            );
          } else {
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

  void paintNamed(
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
