# DI Modules (GetX)

## Global Setup
`lib/src/di/di_graph_setup.dart`

```dart
Future<void> setupDependenciesGraph() async {
  await _initializeEnvironment();
  await _registerCoreModule(); // Repositories, APIs
  _registerManagersModule();   // Managers
}
```

## Feature Binding Example
`lib/src/ui/auth/login/binding/login_binding.dart`

```dart
import 'package:get/get.dart';
import 'package:link_home/src/ui/auth/login/bloc/login_bloc.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy load the Bloc/Controller for this feature
    Get.lazyPut<LoginBloc>(() => LoginBloc());
  }
}
```

## Repository Registration
Repositories are typically registered globally or in a core module.

```dart
// register_core_module.dart
Get.lazyPut<AuthRepository>(
  () => AuthRepository(
    Get.find<AppShared>(),
    Get.find<IAuthApiUrl>(),
  ),
  fenix: true, // Recreate if disposed but needed again
);
```
