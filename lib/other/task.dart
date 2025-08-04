class Task {
  final int? id;
  final String subject;
  final String info;
  final int time;

  Task({
    this.id,
    required this.subject,
    required this.info,
    required this.time
  });

  factory Task.fromMap(Map<String, dynamic> json) => Task(
      id: json['id'],
      subject: json['subject'],
      info: json['info'],
      time: json['time']
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'info': info,
      'time': time
    };
  }
}