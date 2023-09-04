import 'dart:io';
import 'dart:ui' as ui show Image;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml_kit;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:ocr_scan_text/ocr_scan/model/scan_match_counter.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_render/pdf_render.dart';

import '../../ocr_scan_text.dart';
import '../helper/pdf_helper.dart';
import '../render/scan_renderer.dart';

enum Mode {
  camera,
  static,
}

class OcrScanService {
  static Mode _actualMode = Mode.camera;
  static Mode get actualMode => _actualMode;
  List<ScanModule> scanModules;

  /// MLKit text detection object
  final ml_kit.TextRecognizer textRecognizer = ml_kit.TextRecognizer();

  OcrScanService(
    this.scanModules,
  );

  Future<OcrTextRecognizerResult?> startScanWithPhoto() async {
    // FilePicker don't work with iOS LivePhoto
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return null;
    }

    return startScanProcess(File(file.path));
  }

  Future<OcrTextRecognizerResult?> startScanWithOpenFile() async {
    return _startStaticScanProcess(
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowCompression: false,
        allowMultiple: false,
        allowedExtensions: [
          'png',
          'jpg',
          'jpeg',
          'pdf',
        ],
      ),
    );
  }

  Future<OcrTextRecognizerResult?> _startStaticScanProcess(
      FilePickerResult? result) async {
    if (result == null) {
      return null;
    }
    String? path = result.files.first.path;
    if (path == null) {
      return null;
    }
    return await startScanProcess(
      File(path),
    );
  }

  Future<OcrTextRecognizerResult?> startScanProcess(
    File file,
  ) async {
    String extension = path.extension(file.path).toLowerCase();

    assert(extension == '.pdf' ||
        extension == '.png' ||
        extension == '.jpg' ||
        extension == '.jpeg');
    if (extension == '.pdf') {
      final PdfDocument document = await PdfDocument.openFile(
        file.path,
      );
      return await _processStaticPDF(
        document,
        scanModules,
      );
    } else if (extension == '.png' ||
        extension == '.jpg' ||
        extension == '.jpeg') {
      return await _processStaticImage(
        file,
        scanModules,
      );
    }
    return null;
  }

// Process image from camera stream
  Future<OcrTextRecognizerResult?> _processStaticPDF(
    PdfDocument pdfDocument,
    List<ScanModule> scanModules,
  ) async {
    ImagePDF? imagePDF = await PDFHelper.convertToPDFImage(pdfDocument);
    if (imagePDF == null) {
      return null;
    }

    ui.Image background =
        await decodeImageFromList(await imagePDF.file.readAsBytes());

    return await processImage(
      ml_kit.InputImage.fromFilePath(imagePDF.file.path),
      Size(
        background.width.toDouble(),
        background.height.toDouble(),
      ),
      background,
      Mode.static,
      scanModules,
      null,
    );
  }

  Future<OcrTextRecognizerResult?> _processStaticImage(
    File file,
    List<ScanModule> scanModules,
  ) async {
    final cmd = img.Command()..decodeImageFile(file.path);
    await cmd.executeThread();
    img.Image? image = cmd.outputImage;
    if (image == null) {
      return null;
    }
    ui.Image background = await decodeImageFromList(await file.readAsBytes());

    return await processImage(
      ml_kit.InputImage.fromFilePath(file.path),
      Size(
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      background,
      Mode.static,
      scanModules,
      null,
    );
  }

  /// Launch the search for results from the image for all the modules started
  Future<OcrTextRecognizerResult?> processImage(
    ml_kit.InputImage inputImage,
    Size imageSize,
    ui.Image? background,
    Mode mode,
    List<ScanModule> scanModules,
    ml_kit.TextRecognizer? recognizer,
  ) async {
    _actualMode = mode;
    ml_kit.TextRecognizer textRecognizer =
        recognizer ?? ml_kit.TextRecognizer();

    /// Ask MLKit to return the list of TextBlocks in the image
    final recognizedText = await textRecognizer.processImage(inputImage);

    /// create a global String corresponding to the texts found by MLKIt
    String scannedText = '';
    List<ml_kit.TextElement> textBlocks = [];
    for (final textBlock in recognizedText.blocks) {
      for (final element in textBlock.lines) {
        for (final textBlock in element.elements) {
          textBlocks.add(textBlock);
          scannedText += " ${textBlock.text}";
        }
      }
    }

    /// Start the text search for each module
    Map<ScanModule, List<ScanMatchCounter>> mapModule =
        <ScanModule, List<ScanMatchCounter>>{};
    for (var scanModule in scanModules) {
      if (!scanModule.started) {
        continue;
      }

      /// Generate the results of each module
      List<ScanMatchCounter> scanLines = await scanModule.generateResult(
        recognizedText.blocks,
        scannedText,
        imageSize,
      );

      mapModule.putIfAbsent(
        scanModule,
        () => scanLines,
      );
    }

    /// Create a ScanRenderer to display the visual rendering of the results found
    var painter = ScanRenderer(
      mapScanModules: mapModule,
      imageRotation: inputImage.metadata?.rotation ??
          ml_kit.InputImageRotation.rotation90deg,
      imageSize: imageSize,
      background: background,
    );

    Map<ScanModule, List<ScanResult>> mapResult =
        <ScanModule, List<ScanResult>>{};
    mapModule.forEach((key, matchCounterList) {
      List<ScanResult> list = matchCounterList
          .where(
            (matchCounter) => matchCounter.validated == true,
          )
          .map<ScanResult>((e) => e.scanResult)
          .toList();

      if (list.isNotEmpty) {
        mapResult.putIfAbsent(key, () => list);
      }
    });

    await textRecognizer.close();
    if (mapResult.isEmpty) {
      return null;
    }

    return OcrTextRecognizerResult(
      CustomPaint(
        painter: painter,
      ),
      mapResult,
    );
  }
}

class OcrTextRecognizerResult {
  CustomPaint customPaint;
  Map<ScanModule, List<ScanResult>> mapResult;

  OcrTextRecognizerResult(this.customPaint, this.mapResult);
}
