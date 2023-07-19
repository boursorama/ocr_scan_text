# Flutter OCR Scan Text
 OCR Flutter
 `v1.0.0`

Flutter OCR Scan Text est un wrapper autour de la librairie "[Google ML kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition)".
Il permet de faciliter la recherche précise de texte et l'affichage des résultats à partir de la caméra. 

## Features

Permet de numérisez facilement le texte à partir de la caméra, d'extraire des résultats précis et les afficher à l'utilisateur.

Les résultats sont renvoyé par liste de Block.
Un Block contient : le texte global du block, une liste de Line et la position.
Une Line contient : le texte global de la line, une liste d'Element et la position.
Un Element contient : un mot et la position.

<p float="left">
  <img src="https://developers.google.com/static/ml-kit/vision/text-recognition/images/text-structure.png" width="600" />
</p>

Note: La librairie utilise le package de [Camera](https://pub.dev/packages/camera), assuré vous d'avoir la permission.

## Usage

#### Ajouter le package dans pubspec.yaml :

```dart
dependencies:
  ocr_scan_text: x.x.x
```

#### Pour utiliser la librairie, importer : 

```dart
import 'package:ocr_scan_text/ocr_scan_text.dart';
```

#### Pour afficher le widget de detection de texte :

```dart
LiveScanWidget(
  matchedResult: (ScanModule module, List<ScanResult> scanResult) {},
  scanModules: [],
)
```

Un LiveScanWidget a besoin d'une liste de module pour commencer la detection. 
Les résultats validé seront renvoyé a la methode "matchedResult".

#### Créer un module de scan : 

Dans cette exemple (voir le dossier `/example`), nous consideront que tous les Elements sont des résultats.

Pour créer un nouveau module :
```dart
class ScanAllModule extends ScanModule
```

Le constructeur d'un module définit :
- label : Un label (optionnel) qui sera affiché à l'utilisateur lors du rendu 
- color : Une couleur (optionnel) qui sera utilisé pour le rendu 
- validateCountCorrelation : Le nombre de fois qu'il faut trouver le même résultat au même endroit pour qu'il soit valide. ( Comme la camera bouge certain chiffre / lettre peuvent être mal intépreter sur plusieurs frame ).
```dart
ScanAllModule() : super(label: 'All',color: Colors.redAccent.withOpacity(0.3), validateCountCorrelation: 1);
```

Un module a pour but de rechercher, parmis les Block, une liste de résultat (ScanResult) et de la retourner à l'aide de la méthode "matchedResult".

```dart
@override
Future<List<ScanResult>> matchedResult(List<BrsTextBlock> textBlock, String text) async {
  List<ScanResult> list = [];
  for (var block in textBlock) {
    for (var line in block.lines) {
      for (var element in line.elements) {
        list.add(ScanResult(cleanedText: element.text, scannedElementList: [element]));
      }
    }
  }
  return list;
}
```

#### Pour demarrer un module : 

```dart
monModule.start();
```

#### Pour arreter un module :

```dart
monModule.stop();
```