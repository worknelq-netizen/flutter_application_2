import 'package:flutter/material.dart';

class ClaimsScreen extends StatelessWidget {
  final String userName;
  final String userSquad;

  const ClaimsScreen({
    Key? key,
    required this.userName,
    required this.userSquad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text('Претензии'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Модуль "Претензии"',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Пользователь: $userName',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Подразделение: $userSquad',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}