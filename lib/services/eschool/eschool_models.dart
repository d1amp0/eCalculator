class EschoolMfaChallenge {
  const EschoolMfaChallenge({
    required this.challengeToken,
    required this.factors,
    this.expiresAt,
  });

  final String challengeToken;
  final List<EschoolMfaFactor> factors;
  final DateTime? expiresAt;

  static EschoolMfaChallenge? tryParse(Object? value) {
    final outer = eschoolMap(value);
    final data = eschoolMap(outer?['result']) ?? outer;
    if (data == null) return null;
    final token = eschoolString(data['challengeToken']);
    if (token == null || token.isEmpty) return null;
    return EschoolMfaChallenge(
      challengeToken: token,
      factors: eschoolList(data['factors'])
          .map(EschoolMfaFactor.tryParse)
          .whereType<EschoolMfaFactor>()
          .toList(growable: false),
      expiresAt: eschoolDateTime(data['expiresAt']),
    );
  }
}

class EschoolMfaFactor {
  const EschoolMfaFactor({this.id, required this.type, this.label});

  final String? id;
  final String type;
  final String? label;

  static EschoolMfaFactor? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final type = eschoolString(map['type'] ?? map['factorType']);
    if (type == null || type.isEmpty) return null;
    return EschoolMfaFactor(
      id: eschoolString(map['factorId'] ?? map['id']),
      type: type,
      label: eschoolString(map['label'] ?? map['name']),
    );
  }
}

class EschoolAcademicYear {
  const EschoolAcademicYear({
    required this.yearId,
    this.name,
    this.startDate,
    this.endDate,
  });

  final String yearId;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, Object?> toJson() => {
        'yearId': yearId,
        'name': name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  String? get displayName {
    final start = startDate;
    if (start != null) {
      return '${start.year}/${endDate?.year ?? start.year + 1}';
    }
    final explicit = name?.trim();
    if (explicit == null || explicit.isEmpty) return null;
    final years = RegExp(r'(\d{4}).*?(\d{4})').firstMatch(explicit);
    if (years != null) return '${years.group(1)}/${years.group(2)}';
    return explicit;
  }

  bool matchesYears(int startYear, int endYear) {
    final start = startDate?.year;
    final end = endDate?.year;
    if (start != null) {
      return start == startYear && (end ?? start + 1) == endYear;
    }
    final label = displayName;
    return label != null &&
        label.contains('$startYear') &&
        label.contains('$endYear');
  }

  static EschoolAcademicYear? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final id = eschoolString(map['yearId'] ?? map['id']);
    if (id == null) return null;
    return EschoolAcademicYear(
      yearId: id,
      name: eschoolString(
        map['name'] ?? map['yearName'] ?? map['academYearName'],
      ),
      startDate: eschoolDateTime(
        map['startDate'] ?? map['begDate'] ?? map['date1'] ?? map['begDateStr'],
      ),
      endDate: eschoolDateTime(
        map['endDate'] ?? map['date2'] ?? map['endDateStr'],
      ),
    );
  }
}

class EschoolClassInfo {
  const EschoolClassInfo({
    required this.groupId,
    this.yearId,
    this.startDate,
    this.endDate,
  });

  final String groupId;
  final String? yearId;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, Object?> toJson() => {
        'groupId': groupId,
        'yearId': yearId,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  static EschoolClassInfo? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final groupId = eschoolString(map['groupId']);
    if (groupId == null) return null;
    return EschoolClassInfo(
      groupId: groupId,
      yearId: eschoolString(map['yearId']),
      startDate: eschoolDateTime(
        map['startDate'] ?? map['begDate'] ?? map['begDateStr'],
      ),
      endDate: eschoolDateTime(map['endDate'] ?? map['endDateStr']),
    );
  }

  bool belongsToDisplayYear(String displayYear) {
    final startYear = int.tryParse(displayYear.split('/').first);
    return startYear != null && startDate?.year == startYear;
  }

  bool belongsToAcademicYear(
    EschoolAcademicYear? academicYear,
    int startYear,
  ) {
    if (academicYear != null && yearId != null) {
      return yearId == academicYear.yearId;
    }
    return startDate?.year == startYear;
  }
}

class EschoolPeriod {
  const EschoolPeriod({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  static EschoolPeriod? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final id = eschoolString(map['id']);
    final name = eschoolString(map['name']);
    if (id == null || name == null) return null;
    return EschoolPeriod(
      id: id,
      name: name,
      startDate: eschoolDateTime(map['startDate'] ?? map['date1']),
      endDate: eschoolDateTime(map['endDate'] ?? map['date2']),
    );
  }
}

/// The static projection of getDiaryUnits. Dynamic totals, averages, ratings,
/// and final marks are deliberately not retained in this model/cache.
class EschoolSubjectMetadata {
  const EschoolSubjectMetadata({
    required this.unitId,
    required this.unitName,
    this.markSystemId,
    this.markSystemCode,
  });

  final String unitId;
  final String unitName;
  final String? markSystemId;
  final String? markSystemCode;

  Map<String, Object?> toJson() => {
        'unitId': unitId,
        'unitName': unitName,
        'markSysId': markSystemId,
        'markSysCode': markSystemCode,
      };

  static EschoolSubjectMetadata? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final id = eschoolString(map['unitId']);
    final name = eschoolString(map['unitName']);
    if (id == null || name == null) return null;
    return EschoolSubjectMetadata(
      unitId: id,
      unitName: name,
      markSystemId: eschoolString(map['markSysId']),
      markSystemCode: eschoolString(map['markSysCode']),
    );
  }
}

class EschoolGradesResponse {
  const EschoolGradesResponse(this.lessons);

  final List<EschoolGradeLesson> lessons;

  factory EschoolGradesResponse.fromJson(Object? value) {
    final map = eschoolMap(value);
    final raw = map == null ? value : (map['result'] ?? const []);
    return EschoolGradesResponse(
      eschoolList(raw)
          .map(EschoolGradeLesson.tryParse)
          .whereType<EschoolGradeLesson>()
          .toList(growable: false),
    );
  }
}

class EschoolGradeLesson {
  const EschoolGradeLesson({
    required this.lessonId,
    required this.unitId,
    this.startDate,
    this.classId,
    this.teacherName,
    required this.parts,
  });

  final String lessonId;
  final String unitId;
  final DateTime? startDate;
  final String? classId;
  final String? teacherName;
  final List<EschoolGradePart> parts;

  static EschoolGradeLesson? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final lessonId = eschoolString(map['lessonId']);
    final unitId = eschoolString(map['unitId']);
    if (lessonId == null || unitId == null) return null;
    return EschoolGradeLesson(
      lessonId: lessonId,
      unitId: unitId,
      startDate: eschoolDateTime(map['startDt']),
      classId: eschoolString(map['classId']),
      teacherName: eschoolString(map['teacherFio']),
      parts: eschoolList(map['part'])
          .map(EschoolGradePart.tryParse)
          .whereType<EschoolGradePart>()
          .toList(growable: false),
    );
  }
}

class EschoolGradePart {
  const EschoolGradePart({
    required this.partId,
    this.name,
    this.color,
    this.markSystemCode,
    this.weight,
    this.maxPoint,
    this.teacherComment,
    required this.marks,
  });

  final String partId;
  final String? name;
  final String? color;
  final String? markSystemCode;
  final double? weight;
  final double? maxPoint;
  final String? teacherComment;
  final List<EschoolGradeMark> marks;

  static EschoolGradePart? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    // `lesPartId` is the canonical identifier in the live August 2026
    // getDiaryPeriod_ response. Keep `partId` only for historical payloads.
    final partId = eschoolString(map['lesPartId'] ?? map['partId']);
    if (partId == null) return null;
    return EschoolGradePart(
      partId: partId,
      name: eschoolString(map['lptName']),
      color: eschoolString(map['lptColor']),
      markSystemCode: eschoolString(map['markSysCode']),
      weight: eschoolDouble(map['mrkWt']),
      maxPoint: eschoolDouble(map['maxpoint']),
      teacherComment: eschoolString(map['teacherComm']),
      marks: eschoolList(map['mark'])
          .map(EschoolGradeMark.tryParse)
          .whereType<EschoolGradeMark>()
          .toList(growable: false),
    );
  }
}

class EschoolGradeMark {
  const EschoolGradeMark({
    required this.value,
    this.markId,
    this.markValueId,
    this.markDate,
    this.isUpdated,
    this.criterionUseId,
    this.criterionLabel,
    this.markNumber,
    this.teacherName,
  });

  final String value;
  // Both IDs occur in the same live mark object. Their exact roles must be
  // verified against official frontend behavior before either is used for
  // notification diff identity.
  final int? markId;
  final int? markValueId;
  final DateTime? markDate;
  final bool? isUpdated;
  final String? criterionUseId;
  final String? criterionLabel;
  final int? markNumber;
  final String? teacherName;

  static EschoolGradeMark? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final markValue = eschoolString(map['markValue']);
    if (markValue == null) return null;
    return EschoolGradeMark(
      value: markValue,
      markId: eschoolInt(map['markId']),
      markValueId: eschoolInt(map['markValId']),
      markDate: eschoolDateTime(map['markDt']),
      isUpdated: eschoolBool(map['isUpdated']),
      criterionUseId: eschoolString(map['crUseId']),
      criterionLabel: eschoolString(map['crLabel']),
      markNumber: eschoolInt(map['markNum']),
      teacherName: eschoolString(map['teacherFio']),
    );
  }
}

/// Provisional protocol identity only. It must not be used for notification
/// diffing until a sanitized non-empty response confirms markNum/instance IDs.
class EschoolGradeIdentity {
  const EschoolGradeIdentity({
    required this.lessonId,
    required this.partId,
    this.criterionUseId,
    this.markNumber,
  });

  final String lessonId;
  final String partId;
  final String? criterionUseId;
  final int? markNumber;

  String get provisionalKey =>
      '$lessonId|$partId|${criterionUseId ?? '-'}|${markNumber ?? '-'}';
}

class EschoolResolvedGrade {
  const EschoolResolvedGrade({
    required this.subject,
    required this.lesson,
    required this.part,
    required this.mark,
  });

  final EschoolSubjectMetadata subject;
  final EschoolGradeLesson lesson;
  final EschoolGradePart part;
  final EschoolGradeMark mark;

  EschoolGradeIdentity get identity => EschoolGradeIdentity(
        lessonId: lesson.lessonId,
        partId: part.partId,
        criterionUseId: mark.criterionUseId,
        markNumber: mark.markNumber,
      );
}

class EschoolDiaryResponse {
  const EschoolDiaryResponse(this.lessons);

  final List<EschoolDiaryLesson> lessons;

  factory EschoolDiaryResponse.fromJson(Object? value) {
    final map = eschoolMap(value);
    return EschoolDiaryResponse(
      eschoolList(map?['lesson'])
          .map(EschoolDiaryLesson.tryParse)
          .whereType<EschoolDiaryLesson>()
          .toList(growable: false),
    );
  }
}

class EschoolDiaryLesson {
  const EschoolDiaryLesson({
    required this.id,
    this.date,
    this.unitName,
    required this.parts,
  });

  final String id;
  final DateTime? date;
  final String? unitName;
  final List<EschoolDiaryPart> parts;

  static EschoolDiaryLesson? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final id = eschoolString(map['id'] ?? map['lessonId']);
    if (id == null) return null;
    return EschoolDiaryLesson(
      id: id,
      date: eschoolDateTime(map['date'] ?? map['startDt']),
      unitName:
          eschoolString(eschoolMap(map['unit'])?['name'] ?? map['unitName']),
      parts: eschoolList(map['part'])
          .map(EschoolDiaryPart.tryParse)
          .whereType<EschoolDiaryPart>()
          .toList(growable: false),
    );
  }
}

class EschoolDiaryPart {
  const EschoolDiaryPart({required this.variants});

  final List<EschoolHomeworkVariant> variants;

  static EschoolDiaryPart? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    return EschoolDiaryPart(
      variants: eschoolList(map['variant'])
          .map(EschoolHomeworkVariant.tryParse)
          .whereType<EschoolHomeworkVariant>()
          .toList(growable: false),
    );
  }
}

class EschoolHomeworkVariant {
  const EschoolHomeworkVariant({
    required this.id,
    required this.text,
    required this.files,
  });

  final String id;
  final String text;
  final List<EschoolHomeworkFile> files;

  static EschoolHomeworkVariant? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final id = eschoolString(map['id'] ?? map['varId']);
    final text = eschoolString(map['text']);
    if (id == null || text == null || text.isEmpty) return null;
    return EschoolHomeworkVariant(
      id: id,
      text: text,
      files: eschoolList(map['file'])
          .map(EschoolHomeworkFile.tryParse)
          .whereType<EschoolHomeworkFile>()
          .toList(growable: false),
    );
  }
}

class EschoolHomeworkFile {
  const EschoolHomeworkFile({required this.id, required this.name});

  final String id;
  final String name;

  static EschoolHomeworkFile? tryParse(Object? value) {
    final map = eschoolMap(value);
    if (map == null) return null;
    final id = eschoolString(map['id'] ?? map['fileId']);
    final name = eschoolString(map['fileName']);
    if (id == null || name == null) return null;
    return EschoolHomeworkFile(id: id, name: name);
  }
}

Map<String, dynamic>? eschoolMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return null;
}

List<Object?> eschoolList(Object? value) =>
    value is List ? value.cast<Object?>() : const [];

String? eschoolString(Object? value) {
  if (value == null) return null;
  final result = value.toString();
  return result == 'null' ? null : result;
}

int? eschoolInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

bool? eschoolBool(Object? value) {
  if (value is bool) return value;
  if (value is int) {
    if (value == 0) return false;
    if (value == 1) return true;
  }
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
    }
  }
  return null;
}

double? eschoolDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString().replaceAll(',', '.') ?? '');

DateTime? eschoolDateTime(Object? value) {
  if (value is num) {
    final milliseconds =
        value.abs() < 100000000000 ? value.toInt() * 1000 : value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  final text = eschoolString(value);
  if (text == null || text.isEmpty) return null;
  final numeric = int.tryParse(text);
  if (numeric != null) return eschoolDateTime(numeric);
  final dotted = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(text);
  if (dotted != null) {
    return DateTime(
      int.parse(dotted.group(3)!),
      int.parse(dotted.group(2)!),
      int.parse(dotted.group(1)!),
    );
  }
  return DateTime.tryParse(text);
}
