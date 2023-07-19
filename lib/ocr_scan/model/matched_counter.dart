import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/model/scan_result.dart';

/// MatchedCounter permet de determiner la visibilité et si les trouvé par les différents module
/// sont validé.
/// Pour qu'un element soit validé, il faut que counter soit égale ou supérieur à "validateCountCorrelation".
/// Pour qu'un element soit visible, il faut que counter soit au minimum à 1.
/// A chaque "frame", counter est mis à jour.
class MatchedCounter {
  /// Résultat du module de scan trouvé dans l'image
  ScanResult scanResult;

  /// Determine le nombre de fois ou il doit trouver le meme résultat au meme endroit pour le valider
  int validateCountCorrelation;

  /// Nombre de fois qu'il a trouvé le résultat. Celui ci est incrementé lorsque le résultat a été trouvé
  /// et décrémenté si non trouvé. (Min: -1 , Max: maxCorrelation)
  int _counter = 1;
  int get counter => _counter;

  /// Le nombre maximum avant d'arreter d'incrementer "counter".
  /// On évite de monter trop haut pour pouvoir
  /// invalider rapidement si la caméra scan autre chose. ( Min : 5 , Max : validateCountCorrelation * 2 )
  int get maxCorrelation {
    return max(validateCountCorrelation * 2, 5);
  }

  /// La couleur a afficher lors de la validation.
  Color color;

  /// Determine si le résultat est visible
  bool visible = false;

  /// Determine si le résultat est validé
  bool validated = false;

  MatchedCounter({
    required this.scanResult,
    required this.validateCountCorrelation,
    required this.color,
  }) {
    _updateState();
  }

  /// Mise a jour des états visible et validated
  void _updateState() {
    if (_counter < 0) {
      visible = false;
    } else {
      visible = true;
    }

    if (_counter < validateCountCorrelation) {
      validated = false;
    } else {
      validated = true;
    }
  }

  /// Permet de décrementer "counter" si aucun résultat trouvé
  void downCounter() {
    _counter--;
    _updateState();
  }

  /// Permet d'incrementer "counter" si le résultat a été trouvé
  /// On incremente plus vite les résultats trouvé que non trouvé pour ne pas les perdre trop rapidement
  void upCounter() {
    _counter = min(_counter + 1, maxCorrelation);
    _updateState();
  }

  /// Niveau de progression en % avant validation du résultat
  double progressCorrelation() {
    int correlation = validateCountCorrelation > 0 ? validateCountCorrelation : 1;
    return ((_counter / correlation) * 100) > 100 ? 100 : (_counter / correlation) * 100;
  }

  /// Retourne une couleur donc l'opacité est lié à la progression
  Color actualColor() {
    double progress = progressCorrelation();
    return progress == 100 && validated
        ? color
        : Color.lerp(
              color.withOpacity(0.0),
              color.withOpacity(0.5),
              progress / 100,
            ) ??
            color;
  }
}
