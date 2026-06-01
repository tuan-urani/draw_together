import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> registerEnvironmentModule() async {
  if (dotenv.isInitialized) return;
  await dotenv.load(fileName: '.env');
}
