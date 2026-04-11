import 'package:get_it/get_it.dart';
import 'controllers/auth_controller.dart';
import 'services/auth_service.dart';

final GetIt sl = GetIt.instance;

void initSl() {
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<AuthController>(() => AuthController());
}
