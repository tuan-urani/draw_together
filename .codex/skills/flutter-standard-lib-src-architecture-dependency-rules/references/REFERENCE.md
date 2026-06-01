# Reference: Standard lib/src Architecture Examples

This reference shows how the standard `lib/src` structure maps to responsibilities:

- `ui/<page>/interactor`: state + business logic
- `api/`: DTOs + repositories + remote data sources
- `di/` and `ui/<page>/binding`: dependency wiring

## Example: Interactor + Repository + DTO mapping

### 1) App model (used by Interactors / UI)

```dart
class BankModel {
  final String id;
  final String name;
  final String branchCode;

  const BankModel({
    required this.id,
    required this.name,
    required this.branchCode,
  });
}
```

### 2) DTO + mapper (in `lib/src/api/`)

```dart
class BankDto {
  final String id;
  final String name;
  final String branchCode;

  const BankDto({
    required this.id,
    required this.name,
    required this.branchCode,
  });

  factory BankDto.fromJson(Map<String, dynamic> json) => BankDto(
        id: json['bank_id'] as String,
        name: json['bank_name'] as String,
        branchCode: json['code'] as String,
      );

  BankModel toModel() => BankModel(id: id, name: name, branchCode: branchCode);
}
```

### 3) Repository (in `lib/src/api/`)

```dart
abstract class IBankRepository {
  Future<Result<List<BankModel>>> fetchBanks();
}

class BankRepository implements IBankRepository {
  final BankRemoteDataSource remoteDataSource;

  BankRepository(this.remoteDataSource);

  @override
  Future<Result<List<BankModel>>> fetchBanks() async {
    try {
      final dtoList = await remoteDataSource.getBanks();
      final banks = dtoList.map((dto) => dto.toModel()).toList();
      return Success(banks);
    } catch (e) {
      return FailureResult(ApiFailure.fromException(e));
    }
  }
}
```

### 4) Interactor (in `lib/src/ui/<page>/interactor/`)

```dart
enum BankStatus { initial, loading, loaded, failure }

class BankInteractor extends Equatable {
  final IBankRepository repository;
  final BankStatus status;
  final List<BankModel> banks;
  final String? message;

  const BankInteractor({
    required this.repository,
    this.status = BankStatus.initial,
    this.banks = const [],
    this.message,
  });

  Future<BankInteractor> fetch() async {
    final result = await repository.fetchBanks();
    return switch (result) {
      Success(value: final banks) => BankInteractor(
          repository: repository,
          status: BankStatus.loaded,
          banks: banks,
        ),
      FailureResult(failure: final failure) => BankInteractor(
          repository: repository,
          status: BankStatus.failure,
          message: failure.message,
        ),
    };
  }

  @override
  List<Object?> get props => [status, banks, message];
}
```
