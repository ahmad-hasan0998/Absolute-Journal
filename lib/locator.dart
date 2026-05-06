import 'package:get_it/get_it.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
final locator = GetIt.instance;
void setupLocator() {
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<ApiService>(() => ApiService());
}