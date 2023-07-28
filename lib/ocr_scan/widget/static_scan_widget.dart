import 'dart:io';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:ocr_scan_text/ocr_scan/helper/pdf_helper.dart';
import 'package:ocr_scan_text/ocr_scan/widget/scan_widget.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_render/pdf_render.dart';

class StaticScanWidget extends ScanWidget {
  final File file;
  StaticScanWidget({
    super.key,
    required super.scanModules,
    required super.matchedResult,
    required this.file,
    super.respectRatio = false,
  }) : super(mode: Mode.static);

  @override
  StaticScanWidgetState createState() => StaticScanWidgetState();
}

class StaticScanWidgetState extends ScanWidgetState<StaticScanWidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startProcess();
  }

  Future<void> _startProcess() async {
    String extension = path.extension(widget.file.path).toLowerCase();

    assert(extension == '.pdf' || extension == '.png' || extension == '.jpg');

    if (extension == '.pdf') {
      final PdfDocument document = await PdfDocument.openFile(
        widget.file.path,
      );
      await _processStaticPDF(document);
    } else if (extension == '.png' || extension == '.jpg') {
      await _processStaticImage(widget.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    CustomPaint? customPaint = this.customPaint;

    final size = MediaQuery.of(context).size;
    return customPaint == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SizedBox(
            width: size.width,
            height: size.height,
            child: customPaint,
          );
  }

  // Process image from camera stream
  Future<void> _processStaticPDF(
    PdfDocument pdfDocument,
  ) async {
    ImagePDF? imagePDF = await PDFHelper.convertToPDFImage(pdfDocument);
    if (imagePDF == null) {
      return;
    }

    ui.Image background = await decodeImageFromList(await imagePDF.file.readAsBytes());

    await processImage(
      InputImage.fromFilePath(imagePDF.file.path),
      Size(
        background.width.toDouble() ?? 0,
        background.height.toDouble() ?? 0,
      ),
      background,
    );
    setState(() {});
  }

  Future<void> _processStaticImage(File file) async {
    final cmd = img.Command()..decodeImageFile(file.path);
    await cmd.executeThread();
    img.Image? image = cmd.outputImage;
    if (image == null) {
      return;
    }
    ui.Image background = await decodeImageFromList(await file.readAsBytes());

    await processImage(
      InputImage.fromFilePath(file.path),
      Size(
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      background,
    );
    setState(() {});
  }
}
