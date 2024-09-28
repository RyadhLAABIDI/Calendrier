import 'package:flutter/material.dart';
import 'package:my__team/screens/calendar_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Application',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      // Définir la route initiale comme la page du calendrier
      initialRoute: '/calendar',
      routes: {
        // Définir la route vers la page du calendrier
        '/calendar': (context) => CalendarScreen(),
      },
    );
  }
}
