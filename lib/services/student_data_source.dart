import 'package:ecalculator/domain/student_data.dart';

abstract interface class StudentDataSource {
  Future<List<String>> academicYears();

  Future<String?> periodId(String periodName);

  Future<SubjectMarks> marks(String periodId);

  Future<List<dynamic>> homework();

  Future<void> reset();
}

class StudentDataSession {
  StudentDataSession({StudentDataSource? source}) : _source = source;

  StudentDataSource? _source;

  bool get hasSource => _source != null;

  StudentDataSource get source {
    final current = _source;
    if (current == null) throw StateError('No active student data source');
    return current;
  }

  void activate(StudentDataSource source) {
    _source = source;
  }

  void clear() {
    _source = null;
  }
}

final studentDataSession = StudentDataSession();
