sealed class Failure {
  const Failure(this.message);
  final String message;
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ExportFailure extends Failure {
  const ExportFailure(super.message);
}

class ImportFailure extends Failure {
  const ImportFailure(super.message);
}
