import '../shape/trapezoid.dart';

abstract class BrsRecognizerText {
  final String text;
  final Trapezoid trapezoid;

  BrsRecognizerText({
    required this.text,
    required this.trapezoid,
  });
}
