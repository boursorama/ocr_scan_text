import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

class PDFHelper {
  static Future<ImagePDF?> convertToPDFImage(PdfDocument document) async {
    img.Image? image = await _createFullImageFromPDF(document: document);
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

  static Future<img.Image?> _createFullImageFromPDF({required PdfDocument document, int scale = 5}) async {
    final List<img.Image> imageList = [];
    int width = 0;
    List<int> heights = [];

    /// On prend que les 2 premiers page max, sinon c'est le bordel
    for (int i = 1; i <= min(2, document.pageCount); i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width.toInt() * scale,
        height: page.height.toInt() * scale,
        backgroundFill: true,
        allowAntialiasingIOS: true,
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
      );
      var imageUI = await pageImage.createImageDetached();
      var imgBytes = await imageUI.toByteData(format: ImageByteFormat.png);
      if (imgBytes == null) {
        continue;
      }
      var libImage = img.decodeImage(imgBytes.buffer.asUint8List(imgBytes.offsetInBytes, imgBytes.lengthInBytes));
      if (libImage == null) {
        continue;
      }
      heights.add(imageUI.height);
      if ((imageUI.width) > width) {
        width = imageUI.width;
      }

      imageList.add(libImage);
    }

    int fullHeight = 0;
    for (var height in heights) {
      fullHeight += height;
    }

    final img.Image mergedImage = img.Image(
      width: width,
      height: fullHeight,
    );

    // Merge generated image vertically as vertical-orientated-multi-pdf
    var lastOffset = 0;
    for (var i = 0; i < imageList.length; i++) {
      img.compositeImage(
        mergedImage,
        imageList[i],
        srcW: width,
        srcH: heights[i].round(),
        dstY: lastOffset.round(),
      );
      lastOffset += heights[i];
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
