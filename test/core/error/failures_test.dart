import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/error/failures.dart';

void main() {
  group('Failure hierarchy', () {
    test('StorageFailure carries message', () {
      const f = StorageFailure('db error');
      expect(f.message, 'db error');
      expect(f, isA<Failure>());
    });

    test('ValidationFailure carries message', () {
      const f = ValidationFailure('too long');
      expect(f.message, 'too long');
    });

    test('ExportFailure carries message', () {
      const f = ExportFailure('write failed');
      expect(f.message, 'write failed');
    });

    test('ImportFailure carries message', () {
      const f = ImportFailure('parse error');
      expect(f.message, 'parse error');
    });
  });
}
