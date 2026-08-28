import 'dart:convert';

import 'package:ecalculator/server/functions.dart';

class HomeworkItem {
  const HomeworkItem({
    required this.subject,
    required this.content,
    required this.preview,
    required this.date,
    required this.isLocal,
  });

  factory HomeworkItem.fromRaw(List<dynamic> raw) {
    final isLocal = raw[4] as bool;
    final rawContent = raw[3]?.toString() ?? '';
    if (isLocal) {
      return HomeworkItem(
        subject: raw[1].toString(),
        content: rawContent,
        preview: rawContent,
        date: DateTime.fromMillisecondsSinceEpoch(raw[2] as int),
        isLocal: true,
      );
    }

    final content = rawContent.isEmpty
        ? ''
        : deleteColors(utf8.decode(latin1.encode(rawContent)));
    return HomeworkItem(
      subject: utf8.decode(latin1.encode(raw[1].toString())),
      content: content,
      preview: content.isEmpty ? '' : extractText(content),
      date: DateTime.fromMillisecondsSinceEpoch(raw[2] as int),
      isLocal: false,
    );
  }

  final String subject;
  final String content;
  final String preview;
  final DateTime date;
  final bool isLocal;
}
