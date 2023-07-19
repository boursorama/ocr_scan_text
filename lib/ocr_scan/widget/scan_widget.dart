import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/matched_counter.dart';
import '../model/scan_result.dart';
import '../module/scan_module.dart';
import '../render/scan_renderer.dart';

class ScanWidget extends StatefulWidget {
  /// Liste des modules de recherches
  final List<ScanModule> scanModules;

  /// Methode de callback renvoyant les résultats trouvé et validé
  final Function(ScanModule module, List<ScanResult> textBlockResult) matchedResult;

  const ScanWidget({
    Key? key,
    required this.scanModules,
    required this.matchedResult,
  }) : super(key: key);

  @override
  ScanWidgetState createState() => ScanWidgetState();
}

class ScanWidgetState<T extends ScanWidget> extends State<T> {
  /// Objet MLKit de detection de texte
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Traitement d'une image déjà en cours
  bool _isBusy = false;

  /// Surimpression sur l'image des différentes zones des résultats venant des modules
  CustomPaint? customPaint;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  /// On lance la recherche de résultat à partir de l'image pour tous les modules demarré
  Future<void> processImage(InputImage inputImage, Size imageSize) async {
    if (_isBusy) return;
    _isBusy = true;

    /// On demande a MLKit de nous retourner la liste des TextBlock dans l'image
    final recognizedText = await _textRecognizer.processImage(inputImage);

    /// On crée un String correspondant aux textes trouvé par MLKIt
    String scannedText = '';
    List<TextElement> textBlocks = [];
    for (final textBlock in recognizedText.blocks) {
      for (final element in textBlock.lines) {
        for (final textBlock in element.elements) {
          textBlocks.add(textBlock);
          scannedText += " ${textBlock.text}";
        }
      }
    }

    /// On lance la recherche de texte pour chaque module
    Map<ScanModule, List<MatchedCounter>> mapModule = <ScanModule, List<MatchedCounter>>{};
    for (var scanModule in widget.scanModules) {
      if (!scanModule.started) {
        continue;
      }

      /// On génére les résultats de chaque modules
      List<MatchedCounter> scanLines = await scanModule.generateResult(
        recognizedText.blocks,
        scannedText,
        imageSize,
      );

      mapModule.putIfAbsent(
        scanModule,
        () => scanLines,
      );
    }

    /// On crée un ScanRenderer permettant d'afficher le rendu visuel des résultats trouvé
    var painter = ScanRenderer(
      mapScanModules: mapModule,
      imageRotation: inputImage.metadata?.rotation ?? InputImageRotation.rotation90deg,
      imageSize: imageSize,
    );

    /// On met a jour le customPaint à l'aide du ScanRenderer
    customPaint = CustomPaint(painter: painter);

    mapModule.forEach((key, matchCounterList) {
      List<ScanResult> list = matchCounterList
          .where(
            (matchCounter) => matchCounter.validated == true,
          )
          .map<ScanResult>((e) => e.scanResult)
          .toList();

      if (list.isNotEmpty) {
        /// On retourne la liste des résultat validé
        widget.matchedResult(
          key,
          list,
        );
      }
    });

    _isBusy = false;
    await _textRecognizer.close();
    if (mounted) {
      setState(() {});
    }
  }
}
