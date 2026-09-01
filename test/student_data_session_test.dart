import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/services/student_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student data session activates and clears an authenticated source', () {
    final session = StudentDataSession();
    final source = FakeStudentDataSource();

    expect(session.hasSource, isFalse);
    expect(() => session.source, throwsStateError);

    session.activate(source);

    expect(session.hasSource, isTrue);
    expect(session.source, same(source));

    session.clear();

    expect(session.hasSource, isFalse);
    expect(() => session.source, throwsStateError);
  });
}

class FakeStudentDataSource implements StudentDataSource {
  @override
  Future<List<String>> academicYears() async => const [];

  @override
  Future<List<dynamic>> homework() async => const [];

  @override
  Future<SubjectMarks> marks(String periodId) async => const {};

  @override
  Future<String?> periodId(String periodName) async => null;

  @override
  Future<void> reset() async {}
}
