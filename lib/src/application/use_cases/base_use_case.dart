// Clase base para casos de uso
abstract class UseCase<Input, Output> {
  Future<Output> execute(Input input);
}

// Resultado estándar para casos de uso
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result.success(this.data)
      : error = null,
        isSuccess = true;

  const Result.failure(this.error)
      : data = null,
        isSuccess = false;

  bool get hasData => data != null;
  bool get hasError => error != null;

  // Fold method for functional programming pattern
  R fold<R>(
    R Function(T) onSuccess,
    R Function(String) onFailure,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    } else if (!isSuccess && error != null) {
      return onFailure(error!);
    } else {
      throw Exception('Invalid Result state: isSuccess=$isSuccess, hasData=$hasData, hasError=$hasError');
    }
  }
}
