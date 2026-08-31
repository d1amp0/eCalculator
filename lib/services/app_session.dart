import 'package:ecalculator/services/eschool/eschool_data_source.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/services/student_data_source.dart';

class AppSessionController {
  AppSessionController({
    required this.eschool,
    required this.studentData,
    StudentDataSource Function(EschoolSession)? eschoolSourceFactory,
  }) : _eschoolSourceFactory =
            eschoolSourceFactory ?? ((session) => EschoolDataSource(session));

  final EschoolSession eschool;
  final StudentDataSession studentData;
  final StudentDataSource Function(EschoolSession) _eschoolSourceFactory;

  void activateAuthenticatedAccount() {
    if (!eschool.isAuthenticated) {
      throw StateError('Cannot activate an unauthenticated eSchool account');
    }
    studentData.activate(_eschoolSourceFactory(eschool));
  }

  Future<void> exit() async {
    await eschool.logout();
    studentData.clear();
  }
}

final appSession = AppSessionController(
  eschool: eschoolSession,
  studentData: studentDataSession,
);
