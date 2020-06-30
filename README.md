# Goldenrod

Goldenrod is a simple set of [matchers][] that enables simple golden-file based
`String` assertions for Dart and Flutter testing.

[![Binary on pub.dev][pub_img]][pub_url]
[![Code coverage][cov_img]][cov_url]
[![Github action status][gha_img]][gha_url]
[![Dartdocs][doc_img]][doc_url]
[![Style guide][sty_img]][sty_url]

[pub_url]: https://pub.dartlang.org/packages/goldenrod
[pub_img]: https://img.shields.io/pub/v/goldenrod.svg
[gha_url]: https://github.com/matanlurey/goldenrod.dart/actions
[gha_img]: https://github.com/matanlurey/goldenrod.dart/workflows/Dart/badge.svg
[cov_url]: https://codecov.io/gh/matanlurey/goldenrod.dart
[cov_img]: https://codecov.io/gh/matanlurey/goldenrod.dart/branch/master/graph/badge.svg
[doc_url]: https://www.dartdocs.org/documentation/goldenrod/latest
[doc_img]: https://img.shields.io/badge/Documentation-goldenrod-blue.svg
[sty_url]: https://pub.dev/packages/pedantic
[sty_img]: https://img.shields.io/badge/style-pedantic-40c4ff.svg

Ever tired of writing tests like?

```dart
import 'package:app/app.dart';
import 'package:test/test.dart';

void main() {
  test('should output a pretty string', () {
    expect(shrugEmoji(), '¯\_(ツ)_/¯');
  });
}
```

... and needing to _manually_ update the assertions when you update your app?
Automate it using golden-file based matches and `package:goldenrod`!

> NOTE: This package assumes access to File I/O using `dart:io`, and will not
> work properly (or at all) in read-only file systems, or in environments where
> `dart:io` is not available (such as on the web).
>
> Add `@TestOn('vm')` to the top of your tests that use `package:goldenrod`!

```dart
@TestOn('vm')
import 'package:app/app.dart';
import 'package:goldenrod/goldenrod.dart';
import 'package:test/test.dart';

void main() {
  test('should output a pretty string', () async {
    expect(shrugEmoji(), await matchesGoldenText(file: 'test/shrug.golden'));
  });
}
```

To update goldens pass the environment variable `GOLDENROD_UPDATE=true`:

```bash
GOLDENROD_UPDATE=true pub run test
```

## `matchesGoldenText`

Asserts that the actual `String` matches the contents of the `file` specified:

```dart
// test/foo_test.dart
@TestOn('vm')
import 'package:app/app.dart';
import 'package:goldenrod/goldenrod.dart';
import 'package:test/test.dart';

void main() {
  test('some computation is stable', () async {
    expect(fooString(), await matchesGoldenText(file: 'test/foo_test.golden'));
  });
}
```

[matchers]: https://pub.dev/documentation/matcher/latest/matcher/matcher-library.html

## `matchesGoldenKey`

Asserts than the actual `String` matches the value of the JSON `file`/`key`:

```dart
// test/foo_test.dart
@TestOn('vm')
import 'package:app/app.dart';
import 'package:goldenrod/goldenrod.dart';
import 'package:test/test.dart';

void main() {
  test('some computation is stable', () async {
    expect(a(), await matchesGoldenKey(file: 'test/foo_test.golden', key: 'a'));
    expect(b(), await matchesGoldenKey(file: 'test/foo_test.golden', key: 'b'));
  });
}
```
