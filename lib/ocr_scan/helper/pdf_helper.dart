import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

class PDFHelper {
  static Future<ImagePDF?> convertToPDFImage(PdfDocument document) async {
    img.Image? image = await _createFullImageFromPDF(document);
    if (image == null) {
      return null;
    }

    File? file = await _imageToFile(image);
    if (file == null) {
      return null;
    }

    return ImagePDF(
      document: document,
      file: file,
      image: image,
    );
  }

  static Future<img.Image?> _createFullImageFromPDF(
      PdfDocument document) async {
    final List<img.Image> imageList = [];
    int height = 0, width = 0;

    /// On prend que les 2 premiers page max, sinon c'est le bordel
    for (int i = 1; i <= min(2, document.pageCount); i++) {
      final page = await document.getPage(i);
      int scaleUp =
          5; // 5 is an arbitrary number, we enlarge the image to improve text detection
      final pageImage = await page.render(
        width: page.width.toInt() * scaleUp,
        height: page.height.toInt() * scaleUp,
        backgroundFill: true,
        allowAntialiasingIOS: true,
        fullWidth: page.width * scaleUp,
        fullHeight: page.height * scaleUp,
      );
      var imageUI = await pageImage.createImageDetached();
      var imgBytes = await imageUI.toByteData(format: ImageByteFormat.png);
      if (imgBytes == null) {
        continue;
      }
      var libImage = img.decodeImage(imgBytes.buffer
          .asUint8List(imgBytes.offsetInBytes, imgBytes.lengthInBytes));
      if (libImage == null) {
        continue;
      }
      height += imageUI.height;
      if ((imageUI.width) > width) {
        width = imageUI.width;
      }

      imageList.add(libImage);
    }

    final img.Image mergedImage = img.Image(width: width, height: height);

    // Merge generated image vertically as vertical-orientated-multi-pdf
    for (var i = 0; i < imageList.length; i++) {
      // one page height
      final onePageImageOffset = height / document.pageCount;

      // offset for actual page from by y axis
      final actualPageOffset = i == 0 ? 0 : onePageImageOffset * i - 1;

      img.compositeImage(
        mergedImage,
        imageList[i],
        srcW: width,
        srcH: onePageImageOffset.round(),
        dstY: actualPageOffset.round(),
      );
    }

    return mergedImage;
  }

  static Future<File?> _imageToFile(img.Image pfdImage) async {
    final imageBytes = Uint8List.fromList(img.encodePng(pfdImage));

    final appDir = await getTemporaryDirectory();
    String path = '${appDir.path}/ocr_temp.png';

    return await File(path).writeAsBytes(imageBytes);
  }
}

class ImagePDF {
  PdfDocument document;
  File file;
  img.Image image;

  ImagePDF({
    required this.document,
    required this.file,
    required this.image,
  });
}
