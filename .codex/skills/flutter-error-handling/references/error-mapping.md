# Functional Failure Patterns

## **Global Failures (No Code-gen)**

```dart
abstract class ApiFailure implements Exception {
  const ApiFailure();
}

class ServerFailure extends ApiFailure {
  const ServerFailure();
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure();
}

class UnauthenticatedFailure extends ApiFailure {
  const UnauthenticatedFailure();
}

class BadRequestFailure extends ApiFailure {
  final String message;
  const BadRequestFailure(this.message);
}
```

## **Infrastructure Mapper**

```dart
extension DioErrorX on DioException {
  ApiFailure toFailure() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        if (response?.statusCode == 401) return const UnauthenticatedFailure();
        return const ServerFailure();
      default:
        return const ServerFailure();
    }
  }
}
```
