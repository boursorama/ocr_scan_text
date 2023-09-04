# Flutter OCR Scan Text
OCR Flutter
`v1.3.1`

Flutter OCR Scan Text is a wrapper around the "[Google ML kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition)" library.
It helps to facilitate accurate text search and display of results from the camera. It also allows to manage text searches from an image or a pdf.

## Features

Allows you to easily scan text from the camera, extract accurate results and display them to the user.

The results are returned by list of Block.
- A Block contains: the global text of the block, a list of Lines and the position.
- A Line contains: the global text of the line, a list of Elements and the position.
- An Element contains: a word and the position.

<p float="left">
  <img src="https://developers.google.com/static/ml-kit/vision/text-recognition/images/text-structure.png" width="600" />
</p>

Note: The library uses the [Camera](https://pub.dev/packages/camera) package, be sure to ask for permission.

## Usage

#### Add package in pubspec.yaml :

```dart
dependencies:
ocr_scan_text: 1.3.1
```

#### To use the library, import :

```dart
import 'package:ocr_scan_text/ocr_scan_text.dart';
```

#### To display the text detection widget with camera:

```dart
 LiveScanWidget(ocrTextResult: (ocrTextResult) {}, scanModules: [ScanAllModule()],)
```

A LiveScanWidget needs a module list to start detection.
Validated results will be returned to the "matchedResult" method.

#### Create a scan module :

In this example (see the `/example` folder), we consider all Elements to be results.

Create a scan module :
```dart
class ScanAllModule extends ScanModule
```

The constructor of a module:
- label: A label (optional) that will be displayed to the user during rendering
- color: A color (optional) that will be used for rendering
- validateCountCorrelation: The number of times the same result must be found in the same place for it to be valid. (As the camera moves certain numbers / letters may be misinterpreted over several frames).
```dart
ScanAllModule() : super(label: 'All',color: Colors.redAccent.withOpacity(0.3), validateCountCorrelation: 1);
```

The purpose of a module is to search among the Blocks for a list of results (ScanResult) and to return it using the "matchedResult" method.
```dart
@override
Future<List<ScanResult>> matchedResult(List<TextBlock> textBlock, String text) async {
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

#### Start a module :

```dart
module.start();
```

#### Stop a module :

```dart
module.stop();
```

## Scan file with Widget (Supported extension : png, jpg and pdf )

```dart
StaticScanWidget(ocrTextResult: (ocrTextResult) {}, scanModules: [ScanAllModule()], file: File("path/image.png"));
```

## Scan file without Widget (Supported extension : png, jpg and pdf )

This method open gallery for pick a pics and start text analyze. ( /!\ verify permissions before )
```dart
OcrScanService([module]).startScanWithPhoto();
```

This method open file folder for pick a file and start text analyze. ( /!\ verify permissions before )
```dart
OcrScanService([module]).startScanWithOpenFile();
```

This method start text analyze
```dart
OcrScanService([module]).startScanProcess(File('path/image.png'));
```


## Helper

You can use TextBlockHelper methods to help find results.

* TextBlockHelper.extractTextElementsWithRegex :
  Find the list of elements that match with the regex

* TextBlockHelper.nextTextElement :
  Find the next TextElement a right or left of TextElement

* TextBlockHelper.combineRecreateTextLine :
  When texts are on the same line but distant, MLKit can create two different TextBlock. The "combineRecreateTextLine" method will create a TextLine, from a starting TextElement, taking into account the Elements of each TextBlock

* TextBlockHelper.combineLeftTextElement :
  Return a List of TextElement with all TextElement to the left of startElement including startElement.

* TextBlockHelper.combineRightTextElement :
  Return a List of TextElement with all TextElement to the right of startElement including startElement.

* TextBlockHelper.combineBetweenTextElement :
  Return a List of TextElement between startElement and endElement
