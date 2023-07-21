import '../shape/trapezoid.dart';

/// Base object to represent a MlKit object
abstract class BrsRecognizerText {
  final String text;
  final Trapezoid trapezoid;

  BrsRecognizerText({
    required this.text,
    required this.trapezoid,
  });
}
