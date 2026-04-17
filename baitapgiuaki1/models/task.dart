class Task {
  String id;
  String name;
  DateTime dateTime;
  String location;
  bool enableReminder;
  String reminderType; // 'notification', 'alarm', 'email'
  bool isCompleted;

  Task({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.location,
    this.enableReminder = false,
    this.reminderType = 'notification',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'enableReminder': enableReminder,
      'reminderType': reminderType,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      name: json['name'],
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'],
      enableReminder: json['enableReminder'] ?? false,
      reminderType: json['reminderType'] ?? 'notification',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
