import 'dart:math';
import 'dart:ui';

import 'package:ocr_scan_text/ocr_scan/helper/math_helper.dart';

import '../model/recognizer_text/text_block.dart';
import '../model/recognizer_text/text_element.dart';
import '../model/recognizer_text/text_line.dart';
import '../model/shape/trapezoid.dart';

enum HorizontalDirection {
  left,
  right,
}

class TextBlockHelper {
  /// Retourne les résultats de la regex sous forme de List<List<BrsTextElement>>
  /// Ex :
  ///
  ///     List<BrsTextElement> elementList = ['Ca','va','comment','?','Ca','va', 'bien', '!'];
  ///     RegExp regExp = RegExp(r'Ca va');
  ///     Result : elementList = [['Ca','va']['Ca','va']]
  ///
  static List<List<BrsTextElement>> extractTextElementsWithRegex(
    List<BrsTextElement> textElements,
    RegExp regExp,
  ) {
    List<List<BrsTextElement>> listScannedText = [];
    String text = '';
    for (var textElement in textElements) {
      text += textElement.text;
    }

    List<RegExpMatch> matchs = regExp.allMatches(text).toList();
    for (RegExpMatch match in matchs) {
      if (match.start < 0 || match.end == 0) {
        continue;
      }

      /// On reconstruit la liste des TextElements
      List<BrsTextElement> foundElements = [];
      String matchString = text.substring(match.start, match.end);
      for (BrsTextElement element in textElements) {
        if (matchString.contains(element.text)) {
          foundElements.add(element);
        }
      }
      listScannedText.add(foundElements);
    }

    return listScannedText;
  }

  /// Supprime les TextElements correspondant au texte
  /// Ex :
  ///
  ///     List<BrsTextElement> elementList = ['Ca','va','comment','?','Ca', 'va', 'bien', '!'];
  ///     String text = 'Ca va bien';
  ///     Result : elementList = ['Ca','va','comment','?', '!']
  ///
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

  /// Retourne le prochain BrsTextElement a gauche ou a droite
  /// Ex :
  /// Pour simplifier, on considére que tous les block sont dans l'ordre et sur la meme ligne.
  ///
  ///     List<BrsTextBlock> blocks = [['Ca','va','comment']['?']['Ca', 'va', 'bien', '!']];
  ///     HorizontalDirection direction = HorizontalDirection.right;
  ///     BrsTextElement startElement = 'comment';
  ///     Result : BrsTextElement = ['?']
  ///
  static BrsTextElement? nextTextElement(
    BrsTextElement startElement,
    List<BrsTextBlock> blocks,
    HorizontalDirection direction,
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
      startPoint.dx + (direction == HorizontalDirection.left ? -1000 : 1000) * cos(angle),
      startPoint.dy + (direction == HorizontalDirection.left ? -1000 : 1000) * sin(angle),
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

  /// Retourne une BrsTextLine qui est ligne compléte crée a partir d'un TextElement
  /// Ex :
  /// Pour simplifier, on considére que tous les block sont dans l'ordre et sur la meme ligne.
  ///
  ///     List<BrsTextBlock> blocks = [['Ca','va','comment']['?']['Ca', 'va', 'bien', '!']];
  ///     HorizontalDirection direction = HorizontalDirection.right;
  ///     BrsTextElement startElement = '?';
  ///     Result : BrsTextElement = ['Ca','va','comment','?','Ca', 'va','bien', '!']
  ///
  static BrsTextLine combineRecreateTextLine(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement.last, blocks, HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    listTextElement = listTextElement.reversed.toList();
    asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement.last, blocks, HorizontalDirection.right);
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

  /// Retourne une Liste de BrsTextElement avec tout les BrsTextElement a gauche de startElement
  /// Ex :
  /// Pour simplifier, on considére que tous les block sont dans l'ordre et sur la meme ligne.
  ///
  ///     List<BrsTextBlock> blocks = [['Ca','va','comment']['?']['Ca', 'va', 'bien', '!']];
  ///     BrsTextElement startElement = 'comment';
  ///     Result : List<BrsTextElement> = ['Ca','va','comment']
  ///
  static List<BrsTextElement> combineLeftTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement.last, blocks, HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement.reversed.toList();
  }

  /// Retourne une Liste de BrsTextElement avec tout les BrsTextElement a droite de startElement
  /// Ex :
  /// Pour simplifier, on considére que tous les block sont dans l'ordre et sur la meme ligne.
  ///
  ///     List<BrsTextBlock> blocks = [['Ca','va','comment']['?']['Ca', 'va', 'bien', '!']];
  ///     BrsTextElement startElement = 'comment';
  ///     Result : List<BrsTextElement> = ['?', 'Ca','va', 'bien', '!']
  ///
  static List<BrsTextElement> combineRightTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement.last, blocks, HorizontalDirection.right);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement;
  }

  static List<BrsTextElement> combineBetweenTextElement(
      BrsTextElement startElement, BrsTextElement endElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement.last, blocks, HorizontalDirection.right);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);

      if (asNext && nextElement!.text == endElement!.text) {
        asNext = false;
      }
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
