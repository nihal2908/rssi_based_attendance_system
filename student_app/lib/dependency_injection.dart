import 'package:get_it/get_it.dart';
import 'package:student_app/controllers/room_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/course_controller.dart';
// import 'controllers/session_controller.dart';
import 'services/auth_service.dart';

final GetIt sl = GetIt.instance;

void initSl() {
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<AuthController>(() => AuthController());
  sl.registerLazySingleton<RoomController>(() => RoomController());
  sl.registerLazySingleton<CourseController>(() => CourseController());
  // sl.registerLazySingleton<SessionController>(() => SessionController());
}
