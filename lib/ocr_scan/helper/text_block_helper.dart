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

    // 10000 is an arbitrary number, we just want to make a big line
    Offset endPoint = Offset(
      startPoint.dx + (direction == HorizontalDirection.left ? -10000 : 10000) * cos(angle),
      startPoint.dy + (direction == HorizontalDirection.left ? -10000 : 10000) * sin(angle),
    );

    List<BrsTextElement> sortedElement = _sortTextElement(List.from(blocks), direction);
    int i = 0;
    for (BrsTextElement element in sortedElement) {
      bool duplicated = false;
      for (BrsTextElement startElement in startElements) {
        if (startElement == element) {
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

      i++;
    }
    return null;
  }

  static List<BrsTextElement> _sortTextElement(List<BrsTextBlock> blocks, HorizontalDirection direction) {
    List<BrsTextElement> listElements = [];
    for (var block in blocks) {
      for (var line in block.lines) {
        for (var element in line.elements) {
          listElements.add(element);
        }
      }
    }

    if (direction == HorizontalDirection.right) {
      listElements.sort(
        (a, b) => a.trapezoid.topLeftOffset.dx.compareTo(
          b.trapezoid.topLeftOffset.dx,
        ),
      );
    } else {
      listElements.sort(
        (a, b) => b.trapezoid.topLeftOffset.dx.compareTo(
          a.trapezoid.topLeftOffset.dx,
        ),
      );
    }
    return listElements;
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
    while (asNext) {
      BrsTextElement? nextElement = nextTextElement(listTextElement, blocks, HorizontalDirection.left);
      nextElement == null ? asNext = false : listTextElement.add(nextElement);
    }

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
      elements: listTextElement,
    );
  }

  static List<BrsTextElement> _combineTextElement(
    BrsTextElement startElement,
    List<BrsTextBlock> blocks,
    HorizontalDirection direction,
  ) {
    double angle;

    Trapezoid? primaryTrapezoid = _findPrimaryBlock(blocks)?.trapezoid;
    if (primaryTrapezoid == null) {
      return [startElement];
    }

    /// TODO: If the biggest block is not in the same angle as startElement, it doesn't work.
    /// TODO: This case should not happen
    angle = MathHelper.retrieveAngle(
      primaryTrapezoid.topLeftOffset,
      primaryTrapezoid.topRightOffset,
    );

    // 10000 is an arbitrary number, we just want to make a big line
    int lineDistance = (direction == HorizontalDirection.right ? 10000 : -10000);

    List<BrsTextElement> sortedElement = _sortTextElement(
      List.from(blocks),
      direction,
    );
    List<BrsTextElement> newListTextElement = [startElement];
    for (BrsTextElement element in sortedElement) {
      if (startElement == element) {
        continue;
      }

      Offset startPoint = Offset(
        newListTextElement.last.trapezoid.topRightOffset.dx,
        newListTextElement.last.trapezoid.topRightOffset.dy +
            (newListTextElement.last.trapezoid.bottomRightOffset.dy -
                    newListTextElement.last.trapezoid.topRightOffset.dy) /
                2,
      );
      Offset endPoint = Offset(
        startPoint.dx + lineDistance * cos(angle),
        startPoint.dy + lineDistance * sin(angle),
      );

      if (MathHelper.doSegmentsIntersect(
        startPoint,
        endPoint,
        element.trapezoid.topLeftOffset,
        element.trapezoid.bottomLeftOffset,
      )) {
        newListTextElement.add(element);
      }
    }

    newListTextElement.sort(
      (a, b) => a.trapezoid.topLeftOffset.dx.compareTo(
        b.trapezoid.topLeftOffset.dx,
      ),
    );

    return newListTextElement;
  }

  /// Return a List of BrsTextElement with all BrsTextElement to the left of startElement
  /// including startElement.
  /// Ex :
  ///     List<BrsTextBlock> blocks =  [['How', 'are', 'you', '?']['Welcome', '!']];
  ///     BrsTextElement startElement = 'Welcome';
  ///     Result : BrsTextElement = ['How','are','you','?', 'Welcome']
  ///
  static List<BrsTextElement> combineLeftTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    return _combineTextElement(startElement, blocks, HorizontalDirection.left);
  }

  /// Return a List of BrsTextElement with all BrsTextElement to the reight of startElement
  /// including startElement.
  /// Ex :
  ///     List<BrsTextBlock> blocks =  [['How', 'are', 'you', '?']['Welcome', '!']];
  ///     BrsTextElement startElement = 'you';
  ///     Result : BrsTextElement = ['you','?', 'Welcome', '!']
  ///
  static List<BrsTextElement> combineRightTextElement(BrsTextElement startElement, List<BrsTextBlock> blocks) {
    return _combineTextElement(startElement, blocks, HorizontalDirection.right);
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
