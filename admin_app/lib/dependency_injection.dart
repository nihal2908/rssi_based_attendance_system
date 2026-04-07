import 'package:admin_app/controllers/dashboard_controller.dart';
import 'package:admin_app/controllers/notification_controller.dart';
import 'package:admin_app/controllers/room_controller.dart';
import 'package:get_it/get_it.dart';
import 'controllers/auth_controller.dart';
import 'services/auth_service.dart';

final GetIt sl = GetIt.instance;

void initSl() {
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<AuthController>(() => AuthController());
  sl.registerLazySingleton<DashboardController>(() => DashboardController());
  sl.registerLazySingleton<NotificationController>(
    () => NotificationController(),
  );
  sl.registerLazySingleton<RoomsController>(() => RoomsController());
}
