import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my__team/models/project.dart';

class ProjectDataSource extends CalendarDataSource {
  final List<Project> projects;

  ProjectDataSource(this.projects);

  @override
  DateTime getStartTime(int index) {
    // Fournir une date par défaut si startDate est nul
    return projects[index].startDate ?? DateTime.now();
  }

  @override
  DateTime getEndTime(int index) {
    // Fournir une date par défaut si endDate est nul
    return projects[index].endDate ?? DateTime.now();
  }

  @override
  String getSubject(int index) {
    // Retourner le nom du projet comme sujet
    return projects[index].name;
  }

  @override
  String getDetails(int index) {
    String details = '';
    if (projects[index].modules.isNotEmpty) {
      for (var module in projects[index].modules) {
        details += ' - ${module.moduleName}:\n';
        if (module.tasks.isNotEmpty) {
          for (var task in module.tasks) {
            details += '   * ${task.taskDescription}\n';
          }
        } else {
          details += '   No tasks\n';
        }
      }
    } else {
      details = 'No modules available';
    }
    return details;
  }
}
