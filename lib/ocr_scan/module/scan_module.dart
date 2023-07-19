import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/helper/math_helper.dart';

import '../model/matched_counter.dart';
import '../model/recognizer_text/text_block.dart';
import '../model/scan_result.dart';

abstract class ScanModule {
  /// Determine la distance a la quel un objet peut etre identifié comme un étant le meme (La camera se déplace)
  ///  - Si distanceCorrelation est trop petite, cela va invalider les anciens
  ///    résultats au moindre mouvement de camera.
  ///  - Si distanceCorrelation est trop grande, des résultats similaires a des positions différentes
  ///    peuvent être confondu.
  /// La valeur est a adapter selon ce qu'on cherche à faire.
  double distanceCorrelation;

  /// Determine le nombre minimum de fois ou on doit trouvé le même résultat au même endroit pour valider
  /// le résultat. ( Doit être > 0 )
  int validateCountCorrelation;

  /// Determine si le module est démarré ou arreté
  bool _started = false;
  bool get started => _started;

  /// Si le module est déjà en cours d'utilisation, l'image ne sera pas traité
  bool _busyGenerated = false;

  /// Liste des résultats trouvé par le module
  List<MatchedCounter> matchedCounterList = [];

  /// Nom du module ( Le nom sera affiché dans le rendu final )
  String? label;

  /// Couleur du module ( la couleur sera affiché dans le rendu final )
  Color color;

  ScanModule({
    this.label,
    this.color = Colors.transparent,
    this.validateCountCorrelation = 5,
    this.distanceCorrelation = 30,
  }) {
    assert(validateCountCorrelation > 0);
  }

  /// Démarre le module
  void start() {
    _started = true;
  }

  /// Arret du module
  void stop() {
    _started = false;
  }

  /// Chaque module doit retourner une List de ScanResult contenant tous les résultats trouvé
  Future<List<ScanResult>> matchedResult(
    List<BrsTextBlock> textBlock,
    String text,
  );

  /// Permet de determiner si un résultat est le même
  /// Il faut qu'il ai le même texte et la même position
  /// On considére que le position est la même si elle est comprise entre -distanceCorrelation et +distanceCorrelation
  bool _matchedStringAndPosition(
    ScanResult newScanLine,
    ScanResult oldScanLine,
  ) {
    if (newScanLine.cleanedText == oldScanLine.cleanedText) {
      if (MathHelper.isBetween(
              newScanLine.trapezoid.topLeftOffset.dx,
              oldScanLine.trapezoid.topLeftOffset.dx - distanceCorrelation,
              oldScanLine.trapezoid.topLeftOffset.dx + distanceCorrelation) &&
          MathHelper.isBetween(
              newScanLine.trapezoid.topLeftOffset.dy,
              oldScanLine.trapezoid.topLeftOffset.dy - distanceCorrelation,
              oldScanLine.trapezoid.topLeftOffset.dy + distanceCorrelation)) {
        return true;
      }
    }
    return false;
  }

  /// On converti les TextBlock de MLKit en BrsTextBlock pour faire abstraction de MLKit
  List<BrsTextBlock> _convertTextBlocks(
    List<TextBlock> textBlock,
    Size imageSize,
  ) {
    List<BrsTextBlock> brsTextBlock = [];
    for (var block in textBlock) {
      brsTextBlock.add(BrsTextBlock.fromTextBlock(
        block,
        imageSize,
      ));
    }
    return brsTextBlock;
  }

  /// Lance la recherche de résulat du module puis met a jour la liste
  /// des anciens résultats ( MatchedCounter )
  Future<List<MatchedCounter>> generateResult(
    List<TextBlock> textBlock,
    String text,
    Size imageSize,
  ) async {
    if (_busyGenerated) {
      return matchedCounterList;
    }
    _busyGenerated = true;

    List<ScanResult> newScanResult = await matchedResult(
      _convertTextBlocks(
        textBlock,
        imageSize,
      ),
      text,
    );

    /// On met a jour les compteur de visibilité des objets MatchedCounter :
    /// - Si toujours présent dans la nouvelle liste, on up le compteur
    /// - Si non présent, on down le compteur et on supprime si plus visible
    List<MatchedCounter> matchedCounterListUpdated = [];
    for (var element in matchedCounterList) {
      bool found = false;
      for (var scanResult in newScanResult) {
        if (_matchedStringAndPosition(element.scanResult, scanResult)) {
          found = true;
          element.scanResult = scanResult;
          element.upCounter();
        }
      }
      if (!found) {
        element.downCounter();
      }

      if (element.visible) {
        matchedCounterListUpdated.add(element);
      }
    }
    matchedCounterList = matchedCounterListUpdated;

    /// On ajoute les nouvelles valeurs non connu dans matchedCounterList
    for (var scanResult in newScanResult) {
      bool found = false;
      for (var element in matchedCounterList) {
        if (_matchedStringAndPosition(element.scanResult, scanResult)) {
          found = true;
        }
      }
      if (!found) {
        matchedCounterList.add(
          MatchedCounter(
            scanResult: scanResult,
            validateCountCorrelation: validateCountCorrelation,
            color: color,
          ),
        );
      }
    }
    _busyGenerated = false;
    return matchedCounterList;
  }
}
