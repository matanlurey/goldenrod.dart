import 'dart:convert';
import 'dart:io';

import 'package:goldenrod/goldenrod.dart';
import 'package:goldenrod/src/internal.dart' as internal;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  _testMissingFile();
  _testMissingKey();
  _testPassingFile();
  _testPassingKey();
  _testFailingFile();
  _testFailingKey();
  _testUpdateFile();
  _testUpdateKey();
}

Future<Directory> _createTemp() {
  return Directory(path.join('test', 'data')).createTemp();
}

void _testMissingFile() {
  group('', () {
    setUp(() {
      internal.updateGoldensOnFailure = false;
    });

    test('should fail due to a missing file', () async {
      final matcher = await matchesGoldenText(file: 'not_found.txt');
      expect(
        matcher.matches('SOME_TEXT', <void, void>{}),
        isFalse,
      );
      expect(
        matcher.describe(StringDescription()).toString(),
        'File not found: not_found.txt.',
      );
    });
  });
}

void _testMissingKey() {
  group('', () {
    Directory tempDir;
    File tempJson;

    setUp(() async {
      tempDir = await _createTemp();
      tempJson = File(path.join(tempDir.path, 'temp.json'));
      await tempJson.writeAsString('{"a": "AAA"}');
      internal.updateGoldensOnFailure = false;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should fail due to missing file', () async {
      final matcher = await matchesGoldenKey(file: 'not_found.json', key: 'a');
      expect(
        matcher.matches('SOME_TEXT', <void, void>{}),
        isFalse,
      );
      expect(
        matcher.describe(StringDescription()).toString(),
        'File not found: not_found.json.',
      );
    });

    test('should fail due to missing key', () async {
      final matcher = await matchesGoldenKey(file: tempJson.path, key: 'b');
      expect(
        matcher.matches('SOME_TEXT', <void, void>{}),
        isFalse,
      );
      expect(
        matcher.describe(StringDescription()).toString(),
        allOf(contains('Key "b" from'), contains('temp.json')),
      );
    });
  });
}

void _testPassingFile() {
  group('', () {
    Directory tempDir;
    File tempTxt;

    setUp(() async {
      tempDir = await _createTemp();
      tempTxt = File(path.join(tempDir.path, 'pass.txt'));
      await tempTxt.writeAsString('AaaBbbCcc');
      internal.updateGoldensOnFailure = false;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should read a file', () async {
      expect('AaaBbbCcc', await matchesGoldenText(file: tempTxt.path));
    });
  });
}

void _testPassingKey() {
  group('', () {
    Directory tempDir;
    File tempJson;

    setUp(() async {
      tempDir = await _createTemp();
      tempJson = File(path.join(tempDir.path, 'temp.json'));
      await tempJson.writeAsString('{"a": "AAA"}');
      internal.updateGoldensOnFailure = false;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should read a file and key', () async {
      expect('AAA', await matchesGoldenKey(file: tempJson.path, key: 'a'));
    });
  });
}

void _testFailingFile() {
  group('', () {
    Directory tempDir;
    File tempTxt;

    setUp(() async {
      tempDir = await _createTemp();
      tempTxt = File(path.join(tempDir.path, 'pass.txt'));
      await tempTxt.writeAsString('AaaBbbCcc');
      internal.updateGoldensOnFailure = false;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should read an out of date file', () async {
      expect('OutOfDate', isNot(await matchesGoldenText(file: tempTxt.path)));
    });
  });
}

void _testFailingKey() {
  group('', () {
    Directory tempDir;
    File tempJson;

    setUp(() async {
      tempDir = await _createTemp();
      tempJson = File(path.join(tempDir.path, 'temp.json'));
      await tempJson.writeAsString('{"a": "AAA"}');
      internal.updateGoldensOnFailure = false;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should read an out of date file and key', () async {
      expect('B', isNot(await matchesGoldenKey(file: tempJson.path, key: 'a')));
    });
  });
}

void _testUpdateFile() {
  group('', () {
    Directory tempDir;
    File tempTxt;

    setUp(() async {
      tempDir = await _createTemp();
      tempTxt = File(path.join(tempDir.path, 'pass.txt'));
      await tempTxt.writeAsString('AaaBbbCcc');
      updateGoldensOnFailure();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should update an out of date file', () async {
      expect('NewData', await matchesGoldenText(file: tempTxt.path));
      await internal.waitForGoldenUpdates();
      expect(await tempTxt.readAsString(), 'NewData');
    });
  });
}

void _testUpdateKey() {
  group('', () {
    Directory tempDir;
    File tempJson;

    setUp(() async {
      tempDir = await _createTemp();
      tempJson = File(path.join(tempDir.path, 'temp.json'));
      await tempJson.writeAsString('{"a": "AAA"}');
      updateGoldensOnFailure();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should update an out of date key', () async {
      expect('NewData', await matchesGoldenKey(file: tempJson.path, key: 'a'));
      await internal.waitForGoldenUpdates();
      expect(jsonDecode(await tempJson.readAsString()), {'a': 'NewData'});
    });
  });
}
