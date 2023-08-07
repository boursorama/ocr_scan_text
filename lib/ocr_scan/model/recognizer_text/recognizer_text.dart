import '../shape/trapezoid.dart';

/// Base object to represent a MlKit object
abstract class RecognizerText {
  final String text;
  final Trapezoid trapezoid;

  RecognizerText({
    required this.text,
    required this.trapezoid,
  });
}
