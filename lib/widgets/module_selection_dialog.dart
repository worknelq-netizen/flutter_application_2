import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/calendar_screen.dart';
import '../screens/claims_screen.dart';
import '../screens/sales_screen.dart';

class ModuleSelectionDialog extends StatelessWidget {
  final String userName;
  final String userSquad;

  const ModuleSelectionDialog({
    Key? key,
    required this.userName,
    required this.userSquad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps, size: 60, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Выберите модуль',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Добро пожаловать, $userName!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            _buildModuleButton(
              context,
              icon: Icons.calendar_today,
              title: 'График',
              description: 'Просмотр и управление расписанием',
              color: Colors.blue,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(
                      userName: userName,
                      userSquad: userSquad,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            _buildModuleButton(
              context,
              icon: Icons.report_problem,
              title: 'Претензии',
              description: 'Работа с претензиями и жалобами',
              color: Colors.orange,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClaimsScreen(
                      userName: userName,
                      userSquad: userSquad,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            _buildModuleButton(
              context,
              icon: Icons.trending_up,
              title: 'Продажи',
              description: 'Аналитика продаж',
              color: Colors.green,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesScreen(
                      userName: userName,
                      userSquad: userSquad,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _logout(context);
              },
              child: Text(
                'Выйти из аккаунта',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.shade100),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.shade400),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    Navigator.pop(context); // Закрыть диалог
    Navigator.pop(context); // Вернуться на экран авторизации
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Вы вышли из системы'),
        backgroundColor: Colors.green,
      ),
    );
  }
}