import 'package:flutter/material.dart';

class SalesScreen extends StatelessWidget {
  final String userName;
  final String userSquad;

  const SalesScreen({
    Key? key,
    required this.userName,
    required this.userSquad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Продажи'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Модуль "Продажи"',
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