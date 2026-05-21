import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/globals.dart';
import '../widgets/module_selection_dialog.dart'; // Импорт диалога
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

// ...

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _squadController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSavedUser();


  }

  Future<void> _checkSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedName = prefs.getString('user_name');
    final savedSquad = prefs.getString('user_squad');
    Globals.userName = prefs.getString('user_name');
    Globals.userSquad = prefs.getString('user_squad'); 


      await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
final _firebase = FirebaseMessaging.instance;
await _firebase.requestPermission();
final token = await _firebase.getToken();
  Globals.token=token;
    try {
      final response = await http.get(
        Uri.parse('http://${Globals.ip_conf}:6767/token_ping?token=${token}&login=${Globals.userName}&squad=${Globals.userSquad}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Ошибка загрузки локальных событий: $e');
    }
    if (savedName != null && savedSquad != null) {
      _showModuleSelection(savedName, savedSquad);
    }
  }

  Future<void> _login() async {


    if (_nameController.text.isEmpty || _squadController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final response = await http.get(
        Uri.parse('http://${Globals.ip_conf}:6767/login/?login=${_nameController.text}&password=${_squadController.text}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      var data = json.decode(response.body);
      if (data["newdata"] == "not Got it"){
         _isLoading = false;
         print(data["newdata"]);
      }
      else{      
        await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_squad', data['squad']);
      Globals.userName = _nameController.text;
      Globals.userSquad = data['squad'];}

      
    try {
      final response = await http.get(
        Uri.parse('http://${Globals.ip_conf}:6767/token_ping?token=${Globals.token}&login=${Globals.userName}&squad=${Globals.userSquad}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Ошибка загрузки локальных событий: $e');
    }

    if (data["newdata"] == "Got it") {
      _showModuleSelection(_nameController.text, data['squad']);
    }



    } catch (e) {
      setState(() {
        _errorMessage = 'Неверный логин или пароль';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showModuleSelection(String userName, String userSquad) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ModuleSelectionDialog(
          userName: userName,
          userSquad: userSquad,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 80, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      textAlign: TextAlign.center,
                      'Менеджмент складского предприятия',
                      style: TextStyle(
                        fontSize: 24,
                          
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Войдите в систему',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 32),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Ваш логин',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _squadController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Ваш пароль',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.password),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Войти', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}