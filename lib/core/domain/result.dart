import 'package:ghar360/core/utils/app_exceptions.dart';

/// A type that represents either a success [T] or a failure [AppException].
/// Inspired by functional programming Result/Either types.
sealed class Result<T> {
  const Result();

  /// Creates a successful result with the given value.
  factory Result.success(T value) = Success<T>;

  /// Creates a failure result with the given exception.
  factory Result.failure(AppException exception) = Failure<T>;

  /// Returns true if this is a success result.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result.
  bool get isFailure => this is Failure<T>;

  /// Transforms the success value if present, otherwise returns the failure.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => Result.success(transform(v)),
      Failure(exception: final e) => Result.failure(e),
    };
  }

  /// Executes the given function based on success or failure.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success(value: final v) => success(v),
      Failure(exception: final e) => failure(e),
    };
  }

  /// Gets the value if success, otherwise throws.
  T get valueOrThrow {
    return switch (this) {
      Success(value: final v) => v,
      Failure(exception: final e) => throw e,
    };
  }

  /// Gets the value if success, otherwise returns null.
  T? get valueOrNull {
    return switch (this) {
      Success(value: final v) => v,
      Failure() => null,
    };
  }

  /// Gets the exception if failure, otherwise returns null.
  AppException? get exceptionOrNull {
    return switch (this) {
      Success() => null,
      Failure(exception: final e) => e,
    };
  }
}

/// A successful result containing a value.
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A failure result containing an exception.
final class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure<T> && exception == other.exception;

  @override
  int get hashCode => exception.hashCode;
}
