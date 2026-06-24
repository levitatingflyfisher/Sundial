import 'package:fpdart/fpdart.dart';
import 'package:sundial/core/error/failures.dart';

/// Domain contract for export operations.
/// Phase 1: ExportScreen calls [PlaintextExporter]/[JsonExporter]/[PdfExporter] directly.
/// Phase 2: wire a LocalExportRepository implementing this interface via Riverpod.
abstract interface class ExportRepository {
  Future<Either<ExportFailure, String>> exportPlaintext();
  Future<Either<ExportFailure, String>> exportJson();
  Future<Either<ExportFailure, Unit>> sharePdf();
}
