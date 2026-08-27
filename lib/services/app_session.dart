import 'package:ecalculator/services/demo/demo_data_source.dart';
import 'package:ecalculator/services/eschool/eschool_data_source.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/services/student_data_source.dart';

class AppSessionController {
  AppSessionController({
    required this.eschool,
    required this.studentData,
    StudentDataSource Function()? demoSourceFactory,
    StudentDataSource Function(EschoolSession)? eschoolSourceFactory,
  })  : _demoSourceFactory = demoSourceFactory ?? DemoDataSource.new,
        _eschoolSourceFactory =
            eschoolSourceFactory ?? ((session) => EschoolDataSource(session));

  final EschoolSession eschool;
  final StudentDataSession studentData;
  final StudentDataSource Function() _demoSourceFactory;
  final StudentDataSource Function(EschoolSession) _eschoolSourceFactory;

  bool get isDemo => studentData.isDemo;

  void enterDemo() {
    studentData.enterDemo(_demoSourceFactory());
  }

  void activateAuthenticatedAccount() {
    if (!eschool.isAuthenticated) {
      throw StateError('Cannot activate an unauthenticated eSchool account');
    }
    studentData.activateReal(_eschoolSourceFactory(eschool));
  }

  Future<void> exit() async {
    if (isDemo) {
      studentData.clear();
      return;
    }
    await eschool.logout();
    studentData.clear();
  }
}

final appSession = AppSessionController(
  eschool: eschoolSession,
  studentData: studentDataSession,
);
