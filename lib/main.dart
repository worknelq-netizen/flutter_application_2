import 'package:calendar_app/firebase_options.dart';
import 'package:calendar_app/models/globals.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/auth_screen.dart';

// main.dart
import 'services/background_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await BackgroundNotificationService.initialize(); // <-- Запуск сервиса


  runApp(MyApp());
  
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: AuthScreen(),
    );
 
  }
}