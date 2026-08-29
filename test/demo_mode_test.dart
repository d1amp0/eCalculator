import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:ecalculator/services/demo/demo_data_source.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/services/student_data_source.dart';
import 'package:ecalculator/storage/auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo marks load deterministically and cover varied weights', () async {
    final source = DemoDataSource();
    final firstLoad = await source.marks('any');
    final secondLoad = await source.marks('any');

    expect(firstLoad.keys, containsAll(['Алгебра', 'Физика', 'История']));
    expect(firstLoad['Алгебра']!.map((mark) => mark.value),
        orderedEquals(secondLoad['Алгебра']!.map((mark) => mark.value)));
    expect(
      firstLoad.values.expand((marks) => marks).map((mark) => mark.weight),
      containsAll([1, 1.5, 2]),
    );
  });

  test('demo reset returns fresh fixture data', () async {
    final source = DemoDataSource();
    final loaded = await source.marks('demo');
    loaded['Алгебра']!.clear();

    await source.reset();
    final restored = await source.marks('demo');

    expect(restored['Алгебра'], hasLength(5));
  });

  test('calculator operations work on demo marks and reset cleanly', () async {
    final source = DemoDataSource();
    final fixtures = await source.marks('demo');
    final scenario = CalculatorScenario(fixtures['Алгебра']!);
    final original = scenario.originalAverage;

    scenario.edit('Алгебра-0', value: 4, weight: 1.5);
    scenario.exclude('Алгебра-1');
    scenario.add(value: 5, weight: 2);

    expect(scenario.operations, hasLength(3));
    expect(scenario.predictedAverage, isNot(original));

    scenario.reset();
    expect(scenario.predictedAverage, original);
    expect(scenario.hasChanges, isFalse);
  });

  test('entering and exiting demo never touches real authentication', () async {
    final authStorage = _RecordingAuthStorage()..value = 'saved-real-session';
    var eschoolSourcesConstructed = 0;
    final controller = AppSessionController(
      eschool: EschoolSession(authStorage: authStorage),
      studentData: StudentDataSession(),
      demoSourceFactory: DemoDataSource.new,
      eschoolSourceFactory: (_) {
        eschoolSourcesConstructed++;
        return DemoDataSource();
      },
    );

    controller.enterDemo();
    final marks = await controller.studentData.source.marks('demo');
    await controller.exit();

    expect(marks, isNotEmpty);
    expect(eschoolSourcesConstructed, 0);
    expect(authStorage.value, 'saved-real-session');
    expect(authStorage.readCalls, 0);
    expect(authStorage.writeCalls, 0);
    expect(authStorage.clearCalls, 0);
    expect(controller.studentData.hasSource, isFalse);
  });
}

class _RecordingAuthStorage implements AuthStorage {
  String? value;
  int readCalls = 0;
  int writeCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    value = null;
  }

  @override
  Future<String?> readSession() async {
    readCalls++;
    return value;
  }

  @override
  Future<void> writeSession(String value) async {
    writeCalls++;
    this.value = value;
  }
}
