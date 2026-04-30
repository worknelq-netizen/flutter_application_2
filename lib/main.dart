import 'package:flutter/material.dart';
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