import '../shape/trapezoid.dart';

/// Objet de base pour représenter un objet MlKit
abstract class BrsRecognizerText {
  final String text;
  final Trapezoid trapezoid;

  BrsRecognizerText({
    required this.text,
    required this.trapezoid,
  });
}
