import 'environment_module.dart';
import 'register_core_module.dart';
import 'register_manager_module.dart';

Future<void> setupDependenciesGraph() async {
  await registerEnvironmentModule();
  await registerCoreModule();
  await registerManagerModule();
}
