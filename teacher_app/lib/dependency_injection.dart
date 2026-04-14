import 'package:get_it/get_it.dart';

import 'controllers/teacher_course_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/rooms_controller.dart';
import 'services/auth_service.dart';

final GetIt sl = GetIt.instance;

void initSl() {
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<AuthController>(() => AuthController());
  sl.registerLazySingleton<RoomsController>(() => RoomsController());
  sl.registerLazySingleton<TeacherCourseController>(
    () => TeacherCourseController(),
  );
}
