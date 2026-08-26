List<List<String>> getMarksList() {
  return [
    ["5", "0.5", "Алгебра", "Monday"],
    ["5", "1.5", "Алгебра", "Tuesday"],
    ["5", "0.3", "Алгебра", "Wednesday"],
    ["5", "3", "Алгебра", "Thursday"],
    ["5", "3.5", "Алгебра", "Friday"],
    ["5", "0.5", "Алгебра", "Saturday"],
    ["4", "0.5", "Геометрия", "Monday"],
    ["4", "1.5", "Геометрия", "Tuesday"],
    ["4", "0.3", "Геометрия", "Wednesday"],
    ["4", "3", "Геометрия", "Thursday"],
    ["4", "3.5", "Геометрия", "Friday"],
    ["4", "0.5", "Геометрия", "Saturday"],
    ["3", "0.5", "Физика", "Monday"],
    ["3", "1.5", "Физика", "Tuesday"],
    ["3", "0.3", "Физика", "Wednesday"],
    ["3", "3", "Физика", "Thursday"],
    ["3", "3.5", "Физика", "Friday"],
    ["3", "0.5", "Физика", "Saturday"],
  ];
}

List<String> getSubjects() {
  List<String> subjects = [];
  for (final elem in getMarksList()) {
    if (!subjects.contains(elem[2])) {
      subjects.add(elem[2]);
    }
  }
  return subjects;
}
