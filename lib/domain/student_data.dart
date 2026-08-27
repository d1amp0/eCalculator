class StudentMark {
  const StudentMark({
    required this.id,
    required this.value,
    required this.weight,
    required this.date,
  });

  final String id;
  final double value;
  final double weight;
  final String date;

  StudentMark copyWith({double? value, double? weight}) {
    return StudentMark(
      id: id,
      value: value ?? this.value,
      weight: weight ?? this.weight,
      date: date,
    );
  }
}

typedef SubjectMarks = Map<String, List<StudentMark>>;
