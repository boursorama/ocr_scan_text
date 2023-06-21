import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/helper/math_helper.dart';

import '../model/recognizer_text/text_block.dart';
import '../model/recognizer_text/text_element.dart';
import '../model/recognizer_text/text_line.dart';
import '../model/shape/trapezoid.dart';

enum _HorizontalDirection {
  left,
  right,
}

class TextBlockHelper {
  /// Supprime les elements correspondant au texte
  /// Ex :
  ///     List<BrsTextElement> elementList = ['Ca','va','comment','?','Ca', 'va', 'bien', '!'];
  ///     String text = 'Ca va bien';
  ///     Result : elementList = ['Ca','va','comment','?', '!']
  List<BrsTextElement> removeTextElement(List<BrsTextElement> elementList, String text) {
    for (int i = 0; i < elementList.length; i++) {
      String concatenation = elementList[i].text;
      if (concatenation == text) {
        elementList.removeAt(i);
        i = 0;
        continue;
      } else {
        for (int j = i + 1; j < elementList.length; j++) {
          concatenation += ' ${elementList[j].text}';
          if (concatenation == text) {
            elementList.removeRange(i, j + 1);
            i = 0;
            break;
          }
          if (concatenation.length > text.length) {
            break;
          }
        }
      }
    }

    return elementList;
  }

  static BrsTextElement? _nextTextElement(
    BrsTextElement startElement,
    List<BrsTextBlock> blocks,
    _HorizontalDirection direction,
  ) {
    double angle;

    /// C'est assez compliqué d'obtenir l angle du texte/document
    /// La valeur n'est pas du tout précise
    /// TODO : Si le plus gros block n'est pas dans le meme angle que startElement, ca ne marche pas
    Trapezoid? primaryTrapezoid = _findPrimaryBlock(blocks)?.trapezoid;
    if (primaryTrapezoid == null) {
      return null;
    }
    angle = MathHelper.retrieveAngle(
      primaryTrapezoid.topLeftOffset,
      primaryTrapezoid.topRightOffset,
    );

    Offset startPoint = Offset(
      startElement.trapezoid.topLeftOffset.dx,
      startElement.trapezoid.topLeftOffset.dy +
          (startElement.trapezoid.bottomLeftOffset.dy - startElement.trapezoid.topLeftOffset.dy) / 2,
    );

    // 1000 est un nombre arbitraire, on cherche juste a faire une grande ligne
    Offset endPoint = Offset(
      startPoint.dx + (direction == _HorizontalDirection.left ? -1000 : 1000) * cos(angle),
      startPoint.dy + (direction == _HorizontalDirection.left ? -1000 : 1000) * sin(angle),
    );

    blocks.sort(
      (a, b) => a.trapezoid.topLeftOffset.dx.compareTo(
        b.trapezoid.topLeftOffset.dx,
      ),
    );

    for (BrsTextBlock block in blocks) {
      for (BrsTextLine line in block.lines) {
        for (BrsTextElement element in line.elements) {
          /// On evite les doublons
          bool duplicatedValue = false;
          if (startElement.trapezoid.topLeftOffset == element.trapezoid.topLeftOffset) {
            duplicatedValue = true;
          }

          if (duplicatedValue) {
            continue;
          }
          if (MathHelper.doSegmentsIntersect(
            startPoint,
            endPoint,
            element.trapezoid.topLeftOffset,
            element.trapezoid.bottomLeftOffset,
          )) {
            return element;
          }
        }
      }
    }
    return null;
  }

  /// Pour chaque TextBlock, on récupere les TextElement traversé par la ligne
  /// puis on retourne la nouvelle liste des elements combinés
  static BrsTextLine combineRecreateTextLine(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = _nextTextElement(listTextElement.last, blocks, _HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    listTextElement = listTextElement.reversed.toList();
    asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = _nextTextElement(listTextElement.last, blocks, _HorizontalDirection.right);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }

    String recreatedText = '';
    for (var element in listTextElement) {
      recreatedText += listTextElement.first == element ? element.text : ' ${element.text}';
    }

    return BrsTextLine(
      text: recreatedText,
      elements: listTextElement,
      trapezoid: Trapezoid(
        topLeftOffset: listTextElement.first.trapezoid.topLeftOffset,
        bottomLeftOffset: listTextElement.first.trapezoid.bottomLeftOffset,
        topRightOffset: listTextElement.last.trapezoid.topRightOffset,
        bottomRightOffset: listTextElement.last.trapezoid.bottomRightOffset,
      ),
    );
  }

  /// Pour chaque TextBlock, on récupere les TextElement traversé par la ligne
  /// puis on retourne la nouvelle liste des elements combinés
  static List<BrsTextElement> combineLeftTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = _nextTextElement(listTextElement.last, blocks, _HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement.reversed.toList();
  }

  /// Pour chaque TextBlock, on récupere les TextElement traversé par la ligne
  /// puis on retourne la nouvelle liste des elements combinés
  static List<BrsTextElement> combineRightTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = _nextTextElement(listTextElement.last, blocks, _HorizontalDirection.right);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement;
  }

  /// Permet de récupérer le block de texte le plus grand
  static BrsTextBlock? _findPrimaryBlock(List<BrsTextBlock> allBlocks) {
    BrsTextBlock? longTextBlock;
    for (var block in allBlocks) {
      if (longTextBlock == null) {
        longTextBlock = block;
        continue;
      }

      if (block.trapezoid.topRightOffset.dx - block.trapezoid.topLeftOffset.dx >
              longTextBlock.trapezoid.topRightOffset.dx - longTextBlock.trapezoid.topLeftOffset.dx &&
          block.trapezoid.topRightOffset.dy - block.trapezoid.topRightOffset.dy >
              longTextBlock.trapezoid.topLeftOffset.dy - longTextBlock.trapezoid.topLeftOffset.dy) {
        longTextBlock = block;
      }
    }
    return longTextBlock;
  }
}
