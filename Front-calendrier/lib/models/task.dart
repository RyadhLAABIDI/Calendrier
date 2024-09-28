// task.dart
class Task {
  String id;

  String taskDescription;
  final List<String> team;
  int? duration;
  DateTime? startDate;
  DateTime? endDate;
  String moduleID; // Ajout du champ moduleID
  final bool completed;

  Task({
    required this.id,
    required this.taskDescription,
    required this.team,
    this.duration,
    this.startDate,
    this.endDate,
    required this.completed,
    required this.moduleID, // Modification
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'module_id': id,
      'projectID': id,
      'task_description': taskDescription,
      'team': team,
      'completed': completed,
      'Duration': Duration,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  // In Task.fromJson
  factory Task.fromJson(Map<String, dynamic> json) {
    // print("Debug Task - ID: ${json['_id']}");
    return Task(
      id: json['_id'] ?? 'default-task-id',
      taskDescription: json['task_description'] ?? 'No description provided',
      team: List<String>.from(json['team']),
      duration: json['duration'],
      completed: json['completed'],
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      moduleID: json['module_id'] ?? 'default-module-id',
    );
  }

  void updateWithPredictedData(Map<String, dynamic> data) {
    print(
        'Updating task with data: $data'); // Affiche les données de mise à jour reçues

    if (data.containsKey('duration')) {
      print('Updating duration from ${this.duration} to ${data['duration']}');
      this.duration = data['duration'];
    }
    if (data.containsKey('start_date')) {
      print(
          'Updating start_date from ${this.startDate} to ${data['start_date']}');
      this.startDate = DateTime.parse(data['start_date']);
    }
    if (data.containsKey('end_date')) {
      print('Updating end_date from ${this.endDate} to ${data['end_date']}');
      this.endDate = DateTime.parse(data['end_date']);
    }
  }
}
