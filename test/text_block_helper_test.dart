import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_scan_text/ocr_scan/helper/text_block_helper.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_block.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_element.dart';
import 'package:ocr_scan_text/ocr_scan/model/recognizer_text/text_line.dart';

import 'test_helper.dart';

void main() {
  List<BrsTextBlock> mockedListOfBrsTextBlock() {
    BrsTextBlock textBlock1 = TestHelper.createTextBlock(
      'How are you ? are you fine ?',
      0,
      0,
    );
    BrsTextBlock textBlock2 = TestHelper.createTextBlock(
      'Welcome !',
      textBlock1.lines.last.elements.last.trapezoid.topRightOffset.dx + 10,
      0,
    );
    BrsTextBlock textBlock3 = TestHelper.createTextBlock(
      'from Paris',
      textBlock2.lines.last.elements.last.trapezoid.topRightOffset.dx + 10,
      0,
    );

    return [
      textBlock1,
      textBlock2,
      textBlock3,
    ];
  }

  test('TextBlockHelper_extractTextElementsWithRegex', () {
    RegExp regExp = RegExp(r'are you');
    List<List<BrsTextElement>> list = TextBlockHelper.extractTextElementsWithRegex(
      mockedListOfBrsTextBlock().first.lines.first.elements,
      regExp,
    );

    expect(list.length, 2);
    expect(list.first.length, 2);
    expect(list.first.first.text, 'are');
    expect(list.first.last.text, 'you');
  });

  test('TextBlockHelper_removeTextElement', () {
    List<BrsTextElement> list = TextBlockHelper.removeTextElement(
      mockedListOfBrsTextBlock().first.lines.first.elements,
      'are you',
    );

    expect(list.length, 2);
    expect(list.first.text, 'How');
    expect(list.last.text, '?');
  });

  test('TextBlockHelper_nextTextElement', () {
    BrsTextBlock textBlock = mockedListOfBrsTextBlock().first;
    BrsTextElement? nextElement = TextBlockHelper.nextTextElement(
      [textBlock.lines.first.elements[1]],
      [textBlock],
      HorizontalDirection.right,
    );

    expect(nextElement?.text, 'you');
  });

  test('TextBlockHelper_combineRecreateTextLine', () {
    List<BrsTextBlock> textBlocks = mockedListOfBrsTextBlock();

    BrsTextLine textLine = TextBlockHelper.combineRecreateTextLine(
      textBlocks.first.lines.first.elements[1],
      textBlocks,
    );

    expect(textLine.text, 'How are you ? Welcome ! from Paris');
  });

  test('TextBlockHelper_combineLeftTextElement', () {
    List<BrsTextBlock> textBlocks = mockedListOfBrsTextBlock();
    List<BrsTextElement> elementsList = TextBlockHelper.combineLeftTextElement(
      textBlocks.first.lines.first.elements.last,
      textBlocks,
    );

    expect(elementsList.length, 8);
    expect(elementsList.first.text, 'How');
    expect(elementsList.last.text, '?');
  });

  test('TextBlockHelper_combineRightTextElement', () {
    List<BrsTextBlock> textBlocks = mockedListOfBrsTextBlock();
    List<BrsTextElement> elementsList = TextBlockHelper.combineRightTextElement(
      textBlocks.first.lines.first.elements[2],
      textBlocks,
    );

    expect(elementsList.length, 10);
    expect(elementsList.first.text, 'you');
    expect(elementsList.last.text, 'Paris');
  });

  test('TextBlockHelper_combineBetweenTextElement', () {
    List<BrsTextBlock> textBlocks = mockedListOfBrsTextBlock();
    List<BrsTextElement> elementsList = TextBlockHelper.combineBetweenTextElement(
      textBlocks.first.lines.first.elements[0],
      textBlocks.first.lines.first.elements[3],
      textBlocks,
    );

    expect(elementsList.length, 2);
    expect(elementsList.first.text, 'are');
    expect(elementsList.last.text, 'you');
  });
}
