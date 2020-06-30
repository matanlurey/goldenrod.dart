import 'package:goldenrod/goldenrod.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

// To update expectations, run `GOLDENROD_UPDATE=true pub run test example`.
void main() {
  test('should match some output', () async {
    expect(
      'Hello World',
      await matchesGoldenText(
        file: path.join('example', 'example_test.golden'),
      ),
    );
  });
}
