# Error Handling Reference

## **Dio Error Mapping**

Since the project uses `Dio` and a centralized `Api` wrapper (`lib/src/api/api.dart`), errors are processed as follows:

1.  **Low-Level Catching (`Api.request`)**:
    -   Catches `DioException`.
    -   Parses `response.data['errors']` (Map) or `response.data['message']` (String).
    -   Shows Toast automatically via `showErrorToast`.
    -   Rethrows the exception for the Repository to handle logic flow.

2.  **Repository Layer Mapping**:
    Repositories should wrap API calls in try-catch blocks to return `Result<T>` (Success/Failure).

    ```dart
    // Example Repository
    Future<Result<LoginResponse>> login(LoginRequest request) async {
      try {
        final response = await Api.request(
          url: ApiUrl.login,
          method: 'POST',
          body: request.toJson(),
        );
        return Result.success(LoginResponse.fromJson(response));
      } catch (e) {
        // Dio errors are already toasted by Api class, 
        // but we return Failure so BLoC knows to stop loading.
        return Result.failure(ServerFailure(e.toString()));
      }
    }
    ```

## **Failure Types**

-   **ServerFailure**: API returned 4xx/5xx or connection failed.
-   **CacheFailure**: Local storage error.
-   **ValidationFailure**: Invalid input (caught before API call).
