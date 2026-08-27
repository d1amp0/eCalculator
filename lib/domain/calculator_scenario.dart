import 'package:ecalculator/domain/mark_calculator.dart';
import 'package:ecalculator/domain/student_data.dart';

enum ScenarioOperationType { add, edit, exclude }

class ScenarioOperation {
  const ScenarioOperation({
    required this.type,
    required this.mark,
    this.original,
  });

  final ScenarioOperationType type;
  final StudentMark mark;
  final StudentMark? original;
}

class ScenarioMark {
  const ScenarioMark({
    required this.mark,
    this.original,
    this.isAdded = false,
    this.isExcluded = false,
  });

  final StudentMark mark;
  final StudentMark? original;
  final bool isAdded;
  final bool isExcluded;

  bool get isEdited => original != null;
}

/// A temporary calculation layered over immutable source marks.
class CalculatorScenario {
  CalculatorScenario(Iterable<StudentMark> sourceMarks)
      : _sourceMarks = List<StudentMark>.unmodifiable(sourceMarks);

  final List<StudentMark> _sourceMarks;
  final Map<String, StudentMark> _edits = {};
  final Set<String> _excluded = {};
  final List<StudentMark> _added = [];
  int _nextAddedId = 1;

  List<StudentMark> get sourceMarks => _sourceMarks;
  bool get hasChanges =>
      _edits.isNotEmpty || _excluded.isNotEmpty || _added.isNotEmpty;

  double? get originalAverage => _average(_sourceMarks);

  double? get predictedAverage => _average(
        marks.where((item) => !item.isExcluded).map((item) => item.mark),
      );

  List<ScenarioMark> get marks => [
        for (final source in _sourceMarks)
          ScenarioMark(
            mark: _edits[source.id] ?? source,
            original: _edits.containsKey(source.id) ? source : null,
            isExcluded: _excluded.contains(source.id),
          ),
        for (final added in _added) ScenarioMark(mark: added, isAdded: true),
      ];

  List<ScenarioOperation> get operations => [
        for (final source in _sourceMarks)
          if (_excluded.contains(source.id))
            ScenarioOperation(
              type: ScenarioOperationType.exclude,
              mark: _edits[source.id] ?? source,
              original: source,
            )
          else if (_edits.containsKey(source.id))
            ScenarioOperation(
              type: ScenarioOperationType.edit,
              mark: _edits[source.id]!,
              original: source,
            ),
        for (final added in _added)
          ScenarioOperation(type: ScenarioOperationType.add, mark: added),
      ];

  void add({required double value, required double weight}) {
    _validate(value, weight);
    _added.add(
      StudentMark(
        id: 'scenario-${_nextAddedId++}',
        value: value,
        weight: weight,
        date: 'Сценарий',
      ),
    );
  }

  void edit(String id, {required double value, required double weight}) {
    _validate(value, weight);
    final source = _sourceById(id);
    if (source.value == value && source.weight == weight) {
      _edits.remove(id);
    } else {
      _edits[id] = source.copyWith(value: value, weight: weight);
    }
    _excluded.remove(id);
  }

  void exclude(String id) {
    _sourceById(id);
    _excluded.add(id);
  }

  void restore(String id) {
    if (id.startsWith('scenario-')) {
      _added.removeWhere((mark) => mark.id == id);
      return;
    }
    _sourceById(id);
    _edits.remove(id);
    _excluded.remove(id);
  }

  void reset() {
    _edits.clear();
    _excluded.clear();
    _added.clear();
    _nextAddedId = 1;
  }

  StudentMark _sourceById(String id) {
    return _sourceMarks.firstWhere(
      (mark) => mark.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown mark'),
    );
  }

  static double? _average(Iterable<StudentMark> marks) {
    return MarkCalculator.weightedAverage(
      marks.map((mark) => WeightedMark(mark.value, mark.weight)),
    );
  }

  static void _validate(double value, double weight) {
    if (!value.isFinite || value < 0.8 || value > 5.2) {
      throw ArgumentError.value(value, 'value', 'Unsupported mark value');
    }
    if (!weight.isFinite || weight <= 0) {
      throw ArgumentError.value(weight, 'weight', 'Weight must be positive');
    }
  }
}
