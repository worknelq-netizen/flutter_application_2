// screens/home_screen.dart
import 'package:calendar_app/screens/auth_screen.dart';
import 'package:calendar_app/widgets/module_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/calendar_screen.dart';
import '../screens/claims_screen.dart';
import '../screens/sales_screen.dart';
import '../models/globals.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userSquad;

  const HomeScreen({
    Key? key,
    required this.userName,
    required this.userSquad,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Инициализируем экраны с передачей данных пользователя
    _screens = [
      CalendarScreen(
        userName: widget.userName,
        userSquad: widget.userSquad,
      ),
      ClaimsScreen(
        userName: widget.userName,
        userSquad: widget.userSquad,
      ),
      SalesScreen(
        userName: widget.userName,
        userSquad: widget.userSquad,
      ),
    ];
              _showModuleSelectionDialog();

  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    // Показываем диалог подтверждения
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выход из системы'),
        content: Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Очищаем глобальные переменные
      Globals.userName = null;
      Globals.userSquad = null;
      Globals.token = null;
      
      if (mounted) {
        // Возвращаемся на экран авторизации и очищаем весь стек
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _screens[_selectedIndex],

    );
  }
  
  void _showModuleSelectionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ModuleSelectionDialog(
            userName: widget.userName,
            userSquad: widget.userSquad,
          );
        },
      );
    });
  }
}