import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../lib/src/utils.dart';

void main() {
  // Ensure deterministic US-style formatting for intl.
  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  void checkIfSameAfterParse(String text) {
    final result = parseTextString(text);
    expect(result, equals(text));
  }

  void checkCorrectTransform(String text, String expected) {
    final toTest = parseTextString(text);
    expect(toTest, equals(expected));
  }

  test('Does not change normal or malformed text', () {
    checkIfSameAfterParse('Hello');
    checkIfSameAfterParse('Some stuff {{ Hello');
    checkIfSameAfterParse('Hello my name is {{Norbert}}');
    checkIfSameAfterParse('This is the current date: {{text, SHORT}}');
    // Raw string so backslashes aren’t treated as escapes.
    checkIfSameAfterParse(r'{{\\\n\r\a\0 a123084 }}');
    checkIfSameAfterParse('{{DATE(2017-02-14T06:00Z, SHORTSSS)}}');
    checkIfSameAfterParse('{{DATE(2017-0322-14T06:00Z, SHORTSHORTSSS)}}');
    checkIfSameAfterParse('{{DDATE(2017-02-14T06:00Z, SHORT)}}');
    checkIfSameAfterParse('{{DATE(2017-02-14T06:00Z, SHORT))}}');

    checkIfSameAfterParse('{{TIME(2017-02-14T06:00Z, SHORT)}}');
    checkIfSameAfterParse('{{TIME(2017-02-14T06:00Z, )}}');
    checkIfSameAfterParse('{{TIMES(2017-02-14T06:00Z)}}');
  });

  test('Basic parsing', () {
    checkCorrectTransform('{{DATE(2017-02-14T06:00Z, SHORT)}}', 'Tue, Feb 14th, 2017');
    checkCorrectTransform('{{DATE(2017-02-14T06:00Z, COMPACT)}}', '2/14/2017');
    checkCorrectTransform('{{DATE(2017-02-14T06:00Z)}}', '2/14/2017');
    checkCorrectTransform('{{DATE(2017-02-14T06:00Z, LONG)}}', 'Tuesday, February 14th, 2017');

    checkCorrectTransform('{{TIME(2017-02-14T06:00Z)}}', '6:00 AM');
    checkCorrectTransform('{{TIME(2017-02-14T13:00Z)}}', '1:00 PM');
    checkCorrectTransform('{{TIME(2017-02-14T13:23Z)}}', '1:23 PM');
    checkCorrectTransform('{{TIME(2017-02-14T13:59Z)}}', '1:59 PM');
    checkCorrectTransform('{{TIME(2017-02-14T13:04Z)}}', '1:04 PM');
  });
}
