/// TODO : A mettre a jour et corriger les défauts d'orientation
/*import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as Img;
import 'package:ocr_scan_text/ocr_scan/widget/scan_widget.dart';

class StaticScanWidget extends ScanWidget {
  const StaticScanWidget({super.key, required super.scanModules, required super.matchedResult});

  @override
  StaticScanWidgetState createState() => StaticScanWidgetState();
}

class StaticScanWidgetState extends ScanWidgetState<StaticScanWidget> {
  XFile? xImage;

  @override
  Widget build(BuildContext context) {
    return customPaint == null
        ? Center(
            child: ElevatedButton(
                child: const SizedBox(
                  height: 100,
                  child: Text(
                    'Raised Button',
                  ),
                ),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker(); // Pick an image.
                  XFile? xImage = await picker.pickImage(source: ImageSource.gallery);
                  if (xImage == null) {
                    return;
                  }

                  Uint8List imageBytes = await xImage.readAsBytes();
                  Img.Image? image = Img.decodeImage(imageBytes);
                  if (image == null) {
                    return;
                  }
                  this.xImage = xImage;

                  await _processStaticImage(
                    xImage,
                    Size(
                      image.width.toDouble(),
                      image.height.toDouble(),
                    ),
                  );
                  setState(() {});
                }),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                fit: BoxFit.fill,
                File(xImage!.path),
                width: image?.width.toDouble() ?? 0,
                height: image?.height.toDouble() ?? 0,
              ),
              SizedBox(
                width: image?.width.toDouble() ?? 0,
                height: image?.height.toDouble() ?? 0,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return customPaint!;
                  },
                ),
              ),
            ],
          );
  }

  // Process image from camera stream
  Future<void> _processStaticImage(
    XFile xImage,
    Size imageSize,
  ) async {
    await processImage(
      InputImage.fromFilePath(xImage.path),
      imageSize,
    );
    setState(() {});
  }
}*/
