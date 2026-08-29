import 'package:ecalculator/domain/student_data.dart';

abstract interface class StudentDataSource {
  Future<List<String>> academicYears();

  Future<String?> periodId(String periodName);

  Future<SubjectMarks> marks(String periodId);

  Future<List<dynamic>> homework();

  Future<void> reset();
}

class StudentDataSession {
  StudentDataSession({StudentDataSource? source, bool isDemo = false})
      : _source = source,
        _isDemo = isDemo;

  StudentDataSource? _source;
  bool _isDemo;

  bool get isDemo => _isDemo;
  bool get hasSource => _source != null;

  StudentDataSource get source {
    final current = _source;
    if (current == null) throw StateError('No active student data source');
    return current;
  }

  void activateReal(StudentDataSource source) {
    _source = source;
    _isDemo = false;
  }

  void enterDemo(StudentDataSource source) {
    _source = source;
    _isDemo = true;
  }

  void clear() {
    _source = null;
    _isDemo = false;
  }
}

final studentDataSession = StudentDataSession();
