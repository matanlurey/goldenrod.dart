import 'dart:convert' show Encoding, JsonEncoder, jsonDecode, utf8;
import 'dart:io';

import 'package:matcher/matcher.dart' show Description, Matcher;
import 'package:meta/meta.dart' show required;

import 'src/internal.dart' as internal;

/// Sets a static flag that ignores all golden-file failures.
///
/// Upon a failure, the file is updated with the new expected contents. This
/// method is considered optional, and the preferred way of automatically
/// updating tests is setting an environment variable:
///
/// ```bash
/// $ GOLDENROD_UPDATE=true pub run test
/// ```
void updateGoldensOnFailure() {
  internal.updateGoldensOnFailure = true;
}

bool get _updateGoldens {
  if (Platform.environment['GOLDENROD_UPDATE'] == 'true') {
    return true;
  } else {
    return internal.updateGoldensOnFailure;
  }
}

/// Returns a future that completes with a [Matcher] checking for file contents.
///
/// If [file] does not exist, or the contents do not match the actual [String]
/// (or [Object.toString] value), then the matcher will fail. To ignore failures
/// and automatically update the golden files, see [updateGoldensOnFailure].
///
/// > NOTE: This method returns a `Future<Matcher>` that must be awaited!
Future<Matcher> matchesGoldenText({
  @required String file,
  Encoding encoding = utf8,
}) async {
  ArgumentError.checkNotNull(file, 'file');
  final handle = File(file);
  if (_updateGoldens) {
    return _StringUpdateMatcher(
      await handle.exists()
          ? await handle.readAsString(encoding: encoding)
          : '',
      file,
    );
  } else if (!await handle.exists()) {
    return _FileNotFoundMatcher(file);
  } else {
    return _StringOutputMatcher(
      await handle.readAsString(encoding: encoding),
      file,
    );
  }
}

/// Returns a future that completes with a [Matcher] checking for JSON contents.
///
/// If [file] is found, it is assumed to be a JSON-encoded object, with a [key]
/// where its value is a UTF-8 encoded [String]. If [file] does not exist, or
/// the contents do not match the actual [String] (or [Object.toString] value),
/// then the matcher will fail. To ignore failures and automatically update the
/// golden files, see [updateGoldensOnFailure].
///
/// > NOTE: This method returns a `Future<Matcher>` that must be awaited!
Future<Matcher> matchesGoldenKey({
  @required String key,
  @required String file,
}) async {
  ArgumentError.checkNotNull(key, 'key');
  ArgumentError.checkNotNull(file, 'file');
  final handle = File(file);
  if (!await handle.exists() && !_updateGoldens) {
    return _FileNotFoundMatcher(file);
  } else {
    final tryJson = await handle.readAsString();
    try {
      final text = (jsonDecode(tryJson) as Map<String, Object>)[key] as String;
      if (_updateGoldens) {
        return _StringUpdateMatcher(text, file, key);
      } else {
        return _StringOutputMatcher(text, file, key);
      }
    } catch (e) {
      return _JsonNotFoundMatcher(e);
    }
  }
}

class _FileNotFoundMatcher extends Matcher {
  final String _file;

  const _FileNotFoundMatcher(this._file);

  @override
  bool matches(void _, void __) => false;

  @override
  Description describe(Description description) {
    return description.add('File not found: $_file.');
  }
}

class _JsonNotFoundMatcher extends Matcher {
  final Object _error;

  const _JsonNotFoundMatcher(this._error);

  @override
  bool matches(void _, void __) => false;

  @override
  Description describe(Description description) {
    return description.add('Could not decode JSON: $_error.');
  }
}

class _StringOutputMatcher extends Matcher {
  final String _expected;
  final String _readFile;
  final String _readKey;

  const _StringOutputMatcher(this._expected, this._readFile, [this._readKey]);

  @override
  bool matches(Object item, void _) {
    if (item is String) {
      return item == _expected;
    } else {
      return item.toString() == _expected;
    }
  }

  @override
  Description describe(Description description) {
    description = description.addDescriptionOf(_expected ?? '<No data found>');
    if (_readKey == null) {
      return description.add('(From "$_readFile")');
    } else {
      return description.add('(Key "$_readKey" from "$_readFile")');
    }
  }
}

class _StringUpdateMatcher extends Matcher {
  final String _currentValue;
  final String _updateFile;
  final String _updateKey;

  const _StringUpdateMatcher(
    this._currentValue,
    this._updateFile, [
    this._updateKey,
  ]);

  @override
  bool matches(Object item, void _) {
    if (item is! String) {
      item = item.toString();
    }
    if (item.toString() == _currentValue) {
      return true;
    } else {
      if (_updateKey == null) {
        stdout.writeln('Updating $_updateFile...');
        final future = File(_updateFile).writeAsString(item as String);
        internal.pendingGoldenUpdates.add(future);
      } else {
        stdout.writeln('Updating $_updateFile:$_updateKey...');
        final future = File(_updateFile).readAsString().then((contents) {
          Map<String, Object> json;
          try {
            json = jsonDecode(contents) as Map<String, Object>;
          } catch (_) {
            json = {};
          } finally {
            json[_updateKey] = item;
            final output = JsonEncoder.withIndent('  ').convert(json);
            return File(_updateFile).writeAsString(output);
          }
        });
        internal.pendingGoldenUpdates.add(future);
      }
      return true;
    }
  }

  @override
  Description describe(Description description) {
    description = description.addDescriptionOf(_currentValue);
    if (_updateKey == null) {
      return description.add('(From "$_updateFile")');
    } else {
      return description.add('(Key "$_updateKey" from "$_updateFile")');
    }
  }
}
