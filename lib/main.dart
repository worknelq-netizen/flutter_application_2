import 'package:calendar_app/firebase_options.dart';
import 'package:calendar_app/models/globals.dart';
import 'package:calendar_app/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/auth_screen.dart';
// main.dart
import 'services/background_notification_service.dart';
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Обработка, когда приложение закрыто
  print("Фоновое сообщение: ${message.data}");
}
// Это должно работать даже с warnings
void _handleMessage(RemoteMessage message) {
  final requestId = message.data['request_id'];
  print("✅  ${message.toString()}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await BackgroundNotificationService.initialize(); // <-- Запуск сервиса


  runApp(MyApp());
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// Добавьте логи для проверки
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print("✅ Уведомление получено: ${message.data.toString()}");
  // Должно выводиться даже с warnings
});

FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print("✅ Нажато на уведомление");
  _handleMessage(message); // Ваш переход на заявку
}
);
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    if (Globals.userName != null && Globals.userSquad != null){
    return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: HomeScreen(userName: Globals.userName!, userSquad: Globals.userSquad!),
    );
 
  }
  else{
       return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: AuthScreen(),
    ); 
  }}
}