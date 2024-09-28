import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my__team/models/module.dart';
import 'package:my__team/models/task.dart';
import 'package:my__team/models/project.dart';

enum ProjectFilter { all, complete, incomplete }

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarView _currentView = CalendarView.month;
  List<Project> _projects = [];
  Project? _selectedProject;
  List<Project> completeProjects = [];
  List<Project> incompleteProjects = [];
  ProjectFilter _filter = ProjectFilter.all;
  bool _isLoading = false;

  Widget build3DTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 20.0),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(
              3, 2, 0.005) // Augmentez la profondeur de la transformation
          ..rotateX(
              0.2), // Augmentez l'angle de rotation pour un effet plus prononcé
        alignment: FractionalOffset.center,
        child: Container(
          padding: EdgeInsets.all(
              12), // Augmentez la taille du padding pour un effet plus prononcé
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    0.7), // Assombrissez légèrement la boîte d'ombre
                offset: Offset(
                    8, 8), // Augmentez l'offset pour un effet plus prononcé
                blurRadius:
                    15, // Augmentez le rayon de flou pour un effet plus prononcé
              ),
            ],
          ),
          child: Text(
            'List of Projects',
            style: TextStyle(
              fontSize:
                  22, // Augmentez la taille de la police pour un effet plus prononcé
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects({String? email}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Construction de l'URL avec ou sans paramètre email
      String baseUrl = 'http://192.168.1.116:3000/planning/getbyemail';
      Uri url = Uri.parse(email != null ? '$baseUrl?email=$email' : baseUrl);

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('Response Body: $responseBody');

        // Réinitialiser les listes avant de les remplir à nouveau
        final List<Project> completedProjects = [];
        final List<Project> incompleteProjects = [];

        final List<dynamic>? completedProjectsJson =
            responseBody['completedProjects'];
        final List<dynamic>? incompleteProjectsJson =
            responseBody['incompleteProjects'];

        print('Completed Projects JSON: $completedProjectsJson');
        print('Incomplete Projects JSON: $incompleteProjectsJson');

        if (completedProjectsJson != null) {
          completedProjects.addAll(completedProjectsJson
              .map((projectJson) => Project.fromJson(projectJson))
              .toList());
        }

        if (incompleteProjectsJson != null) {
          incompleteProjects.addAll(incompleteProjectsJson
              .map((projectJson) => Project.fromJson(projectJson))
              .toList());
        }

        setState(() {
          _isLoading = false;
          _projects = [...completedProjects, ...incompleteProjects];
          this.completeProjects = completedProjects;
          this.incompleteProjects = incompleteProjects;
        });
      } else {
        print(
            'Failed to load projects. Status code: ${response.statusCode}, Response body: ${response.body}');
        throw FormatException(
            'Unexpected status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (error) {
      print('Error fetching projects: $error');
      setState(() {
        _isLoading = false;
        // You might want to set some state variable to show an error message or retry option.
      });
    }
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });
    fetchProjects();
  }

  void _showErrorSnackBar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () {
            _refreshData();
          },
        ),
      ),
    );
  }

  Future<void> predictAndCompleteProject(String projectId) async {
    try {
      final Uri url = Uri.parse(
          'http://192.168.1.116:3000/planning/predict_task_duration/$projectId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response Data: $data"); // Log the full response data

        int index = _projects.indexWhere((p) => p.id == projectId);
        if (index != -1) {
          Project project = _projects[index];
          project.isComplete =
              true; // Supposons que la prédiction marque le projet comme complet

          final DateFormat formatter = DateFormat('yyyy-MM-dd');
          if (data.containsKey('project_info')) {
            var projectInfo = data['project_info'];
            if (projectInfo.containsKey('startDate')) {
              project.startDate = formatter.parse(projectInfo['startDate']);
            }
            if (data.containsKey('project_info')) {
              var projectInfo = data['project_info'];
              if (projectInfo.containsKey('endDate')) {
                project.endDate = formatter.parse(projectInfo['endDate']);
              }

              if (data.containsKey('project_info') &&
                  data['project_info'].containsKey('total_duration')) {
                project.total_duration = int.tryParse(
                    data['project_info']['total_duration'].toString());
                print(
                    "Updated Project Total Duration: ${project.total_duration}");
              } else {
                print("Total duration not found in response");
              }
            }
          }

          // Traitement des modules et tâches
          if (data.containsKey('modules')) {
            project.modules.clear();
            List<dynamic> modulesData = data['modules'];
            for (var moduleData in modulesData) {
              Module module = Module.fromJson(moduleData);
              if (moduleData.containsKey('module_start_date')) {
                module.moduleStartDate =
                    formatter.parse(moduleData['module_start_date']);
              }
              if (moduleData.containsKey('module_end_date')) {
                module.moduleEndDate =
                    formatter.parse(moduleData['module_end_date']);
              }
              module.tasks.clear();
              List<dynamic> tasksData = moduleData['tasks'];
              for (var taskData in tasksData) {
                Task task = Task.fromJson(taskData);
                if (taskData.containsKey('start_date')) {
                  task.startDate = formatter.parse(taskData['start_date']);
                }
                if (taskData.containsKey('end_date')) {
                  task.endDate = formatter.parse(taskData['end_date']);
                }
                module.tasks.add(task);
              }
              project.modules.add(module);
            }
          }

          setState(() {
            _projects[index] = project;
            completeProjects.add(project);
            incompleteProjects.removeWhere((p) =>
                p.id ==
                projectId); // S'assure que le projet est retiré des incomplets
          });

          print("Project after update: $project");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Project ${project.name} updated and marked as Complete"),
            duration: Duration(seconds: 2),
          ));
        }
      } else {
        print("HTTP error with status code: ${response.statusCode}");
        throw Exception('Failed to predict task durations');
      }
    } catch (e, stackTrace) {
      print('Error predicting task durations: $e');
      print('StackTrace: $stackTrace');
      _showErrorSnackBar("Failed to predict task durations: $e");
    }
  }

  List<Project> get filteredProjects {
    switch (_filter) {
      case ProjectFilter.complete:
        return completeProjects;
      case ProjectFilter.incomplete:
        return incompleteProjects;
      case ProjectFilter.all:
      default:
        return _projects;
    }
  }

  Widget buildFilterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: buildAnimatedButton(
            icon: Icons.list,
            label: 'All',
            color: Colors.blue,
            onPressed: () {
              _refreshData();
              setState(() => _filter = ProjectFilter.all);
            },
          ),
        ),
        SizedBox(width: 8), // Gardez un peu d'espace entre les boutons
        Expanded(
          child: buildAnimatedButton(
            icon: Icons.check_circle_outline,
            label: 'Schedule',
            color: Colors.green,
            onPressed: () {
              _refreshData();
              setState(() => _filter = ProjectFilter.complete);
            },
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: buildAnimatedButton(
            icon: Icons.remove_circle_outline,
            label: 'Not yet',
            color: Colors.red,
            onPressed: () {
              _refreshData();
              setState(() => _filter = ProjectFilter.incomplete);
            },
          ),
        ),
      ],
    );
  }

  Widget buildAnimatedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(fontSize: 14),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8, // Élévation par défaut
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        shadowColor: color.withOpacity(0.9),
        side: BorderSide(
          color: Colors.black,
          width: 2,
        ),
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed))
              return color.withOpacity(0.9);
            return color;
          },
        ),
        shadowColor: MaterialStateProperty.all(Colors.black),
        elevation: MaterialStateProperty.resolveWith<double>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) return 12;
            return 8;
          },
        ),
      ),
    );
  }

  Widget buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Chargement des données...',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget buildProjectDetailsCard() {
    if (_selectedProject == null) return SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProject = null;
        });
      },
      child: Card(
        color: Colors.white,
        elevation: 5,
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détails du Projet Sélectionné',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 10),
              Text('Description : ${_selectedProject!.description}',
                  style: TextStyle(fontSize: 16)),
              Text(
                'Date de Début : ${formatDate(_selectedProject!.startDate)}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Date de Fin : ${formatDate(_selectedProject!.endDate)}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Durée Totale : ${_selectedProject!.total_duration} jours',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Chef de Projet : ${_selectedProject!.teamLeader}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Mots Clés : ${_selectedProject!.keywords.join(", ")}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Membres : ${_selectedProject!.members.join(", ")}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              Text(
                'Modules:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              ..._selectedProject!.modules.map((module) => Card(
                    color: Colors.black,
                    margin: EdgeInsets.only(top: 10, bottom: 10),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nom du Module : ${module.moduleName}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                          Text(
                            'Durée : ${module.totalDuration} jours',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                          Text(
                            'Date de Début : ${formatDate(module.moduleStartDate)}',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            'Date de Fin : ${formatDate(module.moduleEndDate)}',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            'Équipe du Module : ${module.teamM.join(", ")}',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text('Tâches:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                          ...module.tasks.map((task) => ListTile(
                                title: Text(task.taskDescription,
                                    style: TextStyle(color: Colors.white)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Description : ${task.taskDescription} ',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text('Durée : ${task.duration} jours',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text('chef : ${task.team} jours',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text(
                                        'Date de Début : ${formatDate(task.startDate)}',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text(
                                        'Date de Fin : ${formatDate(task.endDate)}',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    Text(
                                        'Complétée : ${task.completed ? "Oui" : "Non"}',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProjectList() {
    if (_isLoading) {
      return buildLoadingIndicator();
    }

    List<Project> projectsToShow =
        filteredProjects; // Utilisez les projets filtrés

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black), // Ajout d'une bordure noire
        borderRadius:
            BorderRadius.circular(12), // Bords arrondis avec un rayon de 12
      ),
      margin: EdgeInsets.all(12),
      child: Card(
        color: Colors.grey[300],
        elevation: 8,
        child: ListView.builder(
          itemCount: projectsToShow.length,
          itemBuilder: (context, index) {
            final project = projectsToShow[index];

            // Définissez une couleur par défaut en cas où la couleur spécifique est null
            Color greenColor = Colors.green[400] ??
                Colors.green; // Utiliser Colors.green comme fallback
            Color redColor = Colors.red[400] ??
                Colors.red; // Utiliser Colors.red comme fallback

            // Ensuite, utilisez ces couleurs dans votre condition
            Color cardColor = project.isComplete ? greenColor : redColor;

            return Container(
              margin: EdgeInsets.only(
                  bottom: 10), // Ajoute un espace entre les projets
              child: ExpansionTile(
                key: PageStorageKey<Project>(project),
                initiallyExpanded: project == _selectedProject,
                backgroundColor: cardColor,
                collapsedBackgroundColor: cardColor.withOpacity(0.7),
                title: Text(
                  project.name,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Start Date: ${formatDate(project.startDate)}',
                  style: TextStyle(color: Colors.white70),
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Icon(project.isComplete ? Icons.check : Icons.build,
                      color: Colors.white),
                ),
                children: project.modules.map<Widget>((module) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20.0, bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Module: ${module.moduleName}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        ...module.tasks.map((task) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Text(
                              'Task: ${task.taskDescription} - ${task.duration} days',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    if (expanded) {
                      _selectedProject = project;
                    } else if (_selectedProject == project) {
                      _selectedProject = null;
                    }
                  });
                },
                trailing: project.isComplete
                    ? null
                    : IconButton(
                        icon: Icon(Icons.analytics, color: Colors.white),
                        onPressed: () {
                          predictAndCompleteProject(project.id);
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildCalendar() {
    return Card(
      color: Colors.white, // Fond blanc
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black, width: 4.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // Fond blanc
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange,
            width: 4.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SfCalendar(
          view: CalendarView.schedule, // Utilisation de la vue Agenda
          scheduleViewSettings: ScheduleViewSettings(
            appointmentItemHeight: 70,
            dayHeaderSettings: DayHeaderSettings(
              dayTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black), // Chiffres en noir
              dateTextStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black), // Chiffres en noir
            ),
            monthHeaderSettings: MonthHeaderSettings(
              monthTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
              backgroundColor: Colors.lightBlue.shade100,
            ),
          ),
          showNavigationArrow: true,
          dataSource: ProjectDataSource(
              _selectedProject != null ? [_selectedProject!] : []),
          onTap: (CalendarTapDetails details) =>
              _showEventDetails(details, context),
        ),
      ),
    );
  }

  void _showEventDetails(CalendarTapDetails details, BuildContext context) {
    final Appointment? tappedAppointment =
        details.appointments?.isNotEmpty == true
            ? details.appointments!.first
            : null;
    DateTime selectedDate = tappedAppointment?.startTime ?? DateTime.now();
    List<Widget> eventWidgets = [];

    Widget animatedEventDetails() {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 1000),
        child: Column(children: eventWidgets),
      );
    }

    if (_selectedProject != null && tappedAppointment != null) {
      for (var module in _selectedProject!.modules) {
        if (module.moduleStartDate != null &&
            module.moduleEndDate != null &&
            module.moduleName == tappedAppointment.subject) {
          List<Widget> moduleDetails = [
            Transform.scale(
              scale: 1.1,
              child: ListTile(
                leading: Transform.rotate(
                  angle: 0.1,
                  child: Icon(Icons.date_range, color: Colors.deepPurple),
                ),
                title: Text('Module: ${module.moduleName}'),
                subtitle: Text(
                    'From: ${formatDate(module.moduleStartDate!)} - To: ${formatDate(module.moduleEndDate!)}'),
              ),
            ),
            Divider(),
          ];
          eventWidgets.addAll(moduleDetails);
        }
      }
    }

    if (eventWidgets.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No events on ${formatDate(selectedDate)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: Colors.orange, width: 2.0),
          ),
          backgroundColor: Colors.black,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Text(
                    'Events on ${formatDate(selectedDate)}',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: animatedEventDetails(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Project Calendar',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              buildFilterControls(),
              SizedBox(height: 20),
              buildProjectDetailsCard(),
              SizedBox(height: 20),
              build3DTitle(),
              SizedBox(height: 20),
              Container(
                height: 200,
                child: buildProjectList(),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTapDown: (_) => setState(() {}),
                onTapUp: (_) => setState(() {}),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: buildCalendar(),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey[300]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                            0.8), // Plus foncée pour un effet 3D plus marqué
                        spreadRadius: 0,
                        blurRadius:
                            50, // Flou plus important pour une ombre plus dramatique
                        offset: Offset(0,
                            25), // Ombre décalée plus bas pour un effet de profondeur
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectDataSource extends CalendarDataSource {
  ProjectDataSource(List<Project> source) {
    List<Appointment> appointments = [];
    for (var project in source) {
      // Utilisation de MaterialColor pour une apparence plus moderne
      Color projectColor = Colors.teal;
      Color taskColor = Colors.purple;
      Color moduleColor = Colors.orange;

      // Ajouter l'événement de début de projet avec icône
      if (project.startDate != null) {
        appointments.add(Appointment(
          startTime: project.startDate!,
          endTime: project.startDate!,
          isAllDay: true,
          subject: '🚀 Début du projet: ${project.name}',
          color: projectColor,
          notes: 'icons/launch.png', // Chemin vers une icône représentative
        ));
      }

      for (var module in project.modules) {
        for (var task in module.tasks) {
          if (task.startDate != null) {
            DateTime taskDate = task.startDate!;
            appointments.add(Appointment(
              startTime: taskDate,
              endTime: taskDate,
              isAllDay: true,
              subject: '🔧 Début de tâche: ${task.taskDescription}',
              color: taskColor,
              notes: 'icons/task.png',
            ));
            if (task.endDate != null) {
              DateTime taskEndDate = task.endDate!;
              appointments.add(Appointment(
                startTime: taskEndDate,
                endTime: taskEndDate,
                isAllDay: true,
                subject: '✅ Fin de tâche: ${task.taskDescription}',
                color: Colors.red,
                notes: 'icons/check.png',
              ));
            }
          }
        }

        // Gestion des débuts et fins de module avec icônes
        if (module.moduleEndDate != null && module.moduleStartDate != null) {
          DateTime endDate = module.moduleEndDate!;
          DateTime startDate = module.moduleStartDate!;
          appointments.add(Appointment(
            startTime: endDate,
            endTime: endDate,
            isAllDay: true,
            subject: '🏁 Fin de module: ${module.moduleName}',
            color: Colors.red,
            notes: 'icons/end.png',
          ));

          appointments.add(Appointment(
            startTime: startDate,
            endTime: startDate,
            isAllDay: true,
            subject: '🌟 Début de module: ${module.moduleName}',
            color: moduleColor,
            notes: 'icons/start.png',
          ));
        }
      }

      // Ajouter l'événement de fin de projet avec icône
      if (project.endDate != null) {
        appointments.add(Appointment(
          startTime: project.endDate!,
          endTime: project.endDate!,
          isAllDay: true,
          subject: '🏆 Fin du projet: ${project.name}',
          color: Colors.red,
          notes: 'icons/finish.png',
        ));
      }
    }
    this.appointments = appointments;
  }
}

// Fonction helper pour formater les dates
String formatDate(DateTime? date) {
  if (date == null) return 'Pas encore défini';
  return DateFormat('yyyy-MM-dd')
      .format(date); // Formate la date en "Année-Mois-Jour"
}
