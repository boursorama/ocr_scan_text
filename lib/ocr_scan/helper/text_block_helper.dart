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
  /// Return regex result as List<List<BrsTextElement>>
  /// Ex :
  ///
  ///     List<BrsTextElement> elementList = ['How', 'are', 'you', '?'];
  ///     RegExp regExp = RegExp(r'are you');
  ///     Result : elementList = ['are', 'you']
  ///
  static List<List<BrsTextElement>> extractTextElementsWithRegex(
    List<BrsTextElement> textElements,
    RegExp regExp,
  ) {
    List<List<BrsTextElement>> listScannedText = [];
    String text = '';
    for (var textElement in textElements) {
      text += '${textElements.first == textElement ? '' : ' '}${textElement.text}';
    }

    List<RegExpMatch> matchs = regExp.allMatches(text).toList();
    for (RegExpMatch match in matchs) {
      if (match.start < 0 || match.end == 0) {
        continue;
      }

      /// Rebuild the new list of TextElements
      List<BrsTextElement> foundElements = [];
      int elementBeforeMatch = text.substring(0, match.start).split('').where((char) => char == ' ').length;
      int elementBetweenMatch =
          text.substring(match.start, match.end).split('').where((char) => char == ' ').length + 1;

      for (int i = 0; i < elementBetweenMatch; i++) {
        if (elementBeforeMatch + i < textElements.length) {
          foundElements.add(textElements[elementBeforeMatch + i]);
        }
      }

      listScannedText.add(foundElements);
    }

    return listScannedText;
  }

  /// Remove the TextElements from the list corresponding to the text
  /// Ex :
  ///
  ///     List<BrsTextElement> elementList =  ['How', 'are', 'you', '?'];
  ///     String text = 'are you';
  ///     Result : elementList = ['How','?']
  ///
  static List<BrsTextElement> removeTextElement(List<BrsTextElement> elementList, String text) {
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

  /// Return the next BrsTextElement to the left or right of "startElement"
  /// Ex :
  ///
  ///     List<BrsTextBlock> blocks =  ['How', 'are', 'you', '?'];
  ///     HorizontalDirection direction = HorizontalDirection.right;
  ///     BrsTextElement startElement = 'are';
  ///     Result : BrsTextElement = ['you']
  ///
  static BrsTextElement? nextTextElement(
    List<BrsTextElement> startElements,
    List<BrsTextBlock> blocks,
    HorizontalDirection direction,
  ) {
    double angle;

    Trapezoid? primaryTrapezoid = _findPrimaryBlock(blocks)?.trapezoid;
    if (primaryTrapezoid == null) {
      return null;
    }

    /// TODO: If the biggest block is not in the same angle as startElement, it doesn't work.
    /// TODO: This case should not happen
    angle = MathHelper.retrieveAngle(
      primaryTrapezoid.topLeftOffset,
      primaryTrapezoid.topRightOffset,
    );

    Offset startPoint = Offset(
      startElements.last.trapezoid.topLeftOffset.dx,
      startElements.last.trapezoid.topLeftOffset.dy +
          (startElements.last.trapezoid.bottomLeftOffset.dy - startElements.last.trapezoid.topLeftOffset.dy) / 2,
    );

    // 1000 is an arbitrary number, we just want to make a big line
    Offset endPoint = Offset(
      startPoint.dx + (direction == HorizontalDirection.left ? -1000 : 1000) * cos(angle),
      startPoint.dy + (direction == HorizontalDirection.left ? -1000 : 1000) * sin(angle),
    );

    for (BrsTextBlock block in blocks) {
      for (BrsTextLine line in block.lines) {
        for (BrsTextElement element in line.elements) {
          bool duplicated = false;
          for (BrsTextElement startElement in startElements) {
            if (startElement.trapezoid.topLeftOffset == element.trapezoid.topLeftOffset) {
              duplicated = true;
              continue;
            }
          }

          if (duplicated) {
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

  static List<BrsTextBlock> _sortTextBlock(List<BrsTextBlock> blocks, HorizontalDirection direction) {
    if (direction == HorizontalDirection.right) {
      blocks.sort(
        (a, b) => a.trapezoid.topLeftOffset.dx.compareTo(
          b.trapezoid.topLeftOffset.dx,
        ),
      );
    } else {
      blocks.sort(
        (a, b) => b.trapezoid.topLeftOffset.dx.compareTo(
          a.trapezoid.topLeftOffset.dx,
        ),
      );

      for (var block in blocks) {
        block.lines.sort(
          (a, b) => b.trapezoid.topLeftOffset.dx.compareTo(
            a.trapezoid.topLeftOffset.dx,
          ),
        );

        for (var line in block.lines) {
          line.elements.sort(
            (a, b) => b.trapezoid.topLeftOffset.dx.compareTo(
              a.trapezoid.topLeftOffset.dx,
            ),
          );
        }
      }
    }

    return blocks;
  }

  /// Return a BrsTextLine : It's full line by combining left and right all TextElement on the same line
  /// of "startElement", including "startElement".
  /// Ex :
  ///
  ///     List<BrsTextBlock> blocks =  [['How', 'are', 'you', '?']['Welcome', '!']];
  ///     BrsTextElement startElement = 'are';
  ///     Result : BrsTextElement = ['How','are','you','?','Welcome', '!']
  ///
  static BrsTextLine combineRecreateTextLine(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    //blocks = _sortTextBlock(blocks, HorizontalDirection.left);
    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement, blocks, HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }

    // blocks = _sortTextBlock(blocks, HorizontalDirection.right);

    listTextElement = listTextElement.reversed.toList();
    asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement, blocks, HorizontalDirection.right);
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

  /// Return a List of BrsTextElement with all BrsTextElement to the left of startElement
  /// including startElement.
  /// Ex :
  ///     List<BrsTextBlock> blocks =  [['How', 'are', 'you', '?']['Welcome', '!']];
  ///     BrsTextElement startElement = 'Welcome';
  ///     Result : BrsTextElement = ['How','are','you','?', 'Welcome']
  ///
  static List<BrsTextElement> combineLeftTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    blocks = _sortTextBlock(blocks, HorizontalDirection.left);
    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement, blocks, HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement.reversed.toList();
  }

  /// Return a List of BrsTextElement with all BrsTextElement to the reight of startElement
  /// including startElement.
  /// Ex :
  ///     List<BrsTextBlock> blocks =  [['How', 'are', 'you', '?']['Welcome', '!']];
  ///     BrsTextElement startElement = 'you';
  ///     Result : BrsTextElement = ['you','?', 'Welcome', '!']
  ///
  static List<BrsTextElement> combineRightTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [startElement];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement, blocks, HorizontalDirection.right);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement;
  }

  /// Return a List of BrsTextElement between startElement and endElement
  /// Ex :
  ///     List<BrsTextBlock> blocks =  [['How', 'are', 'you', '?']['Welcome', '!']];
  ///     BrsTextElement startElement = 'are';
  ///     BrsTextElement endElement = 'Welcome';
  ///     Result : BrsTextElement = ['you','?']
  ///
  static List<BrsTextElement> combineBetweenTextElement(
      BrsTextElement startElement, BrsTextElement endElement, List<BrsTextBlock> blocks) {
    List<BrsTextElement> listTextElement = [];

    bool asNext = true;

    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(
        listTextElement.isEmpty ? [startElement] : listTextElement,
        blocks,
        HorizontalDirection.right,
      );
      if (nextElement == endElement) {
        nextElement = null;
      }

      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }
    return listTextElement;
  }

  /// Returns the "main" (largest) text block
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
