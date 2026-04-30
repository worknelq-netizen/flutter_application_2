import 'package:calendar_app/models/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClaimsScreen extends StatefulWidget {
  final String userName;
  final String userSquad;

  const ClaimsScreen({
    Key? key,
    required this.userName,
    required this.userSquad,
  }) : super(key: key);

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  List<dynamic> claims = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchClaims();
  }

  Future<void> fetchClaims() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Формируем URL с параметрами
      final uri = Uri.parse(
        'http://${Globals.ip_conf}/complaints?name=${widget.userName}&squad=${widget.userSquad}'
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          claims = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Ошибка загрузки: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка соединения: $e';
        isLoading = false;
      });
    }
  }

  Future<void> refreshClaims() async {
    await fetchClaims();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Претензии'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshClaims,
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о пользователе
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пользователь: ${widget.userName}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Подразделение: ${widget.userSquad}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (!isLoading)
                  Text(
                    'Всего: ${claims.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
              ],
            ),
          ),
          // Основной контент
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(errorMessage!),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchClaims,
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : claims.isEmpty
                        ? Center(
                            child: Text('Нет претензий'),
                          )
                        : RefreshIndicator(
                            onRefresh: refreshClaims,
                            child: ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: claims.length,
                              itemBuilder: (context, index) {
                                final claim = claims[index];
                                return _buildClaimCard(claim);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(dynamic claim) {
    // Определяем цвет статуса
    Color statusColor;
    switch (claim['bigstatus']) {
      case 'Исполненно':
        statusColor = Colors.green;
        break;
      case 'В работе':
        statusColor = Colors.orange;
        break;
      case 'Не рассмотрено':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            Icons.report_problem,
            color: statusColor,
          ),
        ),
        title: Text(
          claim['numerator'] ?? 'Претензия',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Клиент: ${claim['client']}'),
            SizedBox(height: 4),
            Chip(
              label: Text(claim['bigstatus'] ?? 'Неизвестно'),
              backgroundColor: statusColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               // _buildInfoRow(Icons.person, 'Ответственный:', claim['name']),
                _buildInfoRow(Icons.location_on, 'Адрес:', claim['adress']),
                _buildInfoRow(Icons.phone, 'Телефон:', claim['telephone']),
               // _buildInfoRow(Icons.door_front_door, 'Тип двери:', claim['doortipe']),
               // _buildInfoRow(Icons.description, 'Основание:', claim['base']),
                if (claim['text'].toString().isNotEmpty)
                  _buildInfoRow(Icons.comment, 'Текст претензии:', claim['text']),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статусы:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        claim['status'] ?? '',
                        style: TextStyle(fontSize: 12),
                      ),
                    OutlinedButton.icon(
                    onPressed: () {},
                    label: const Text('Подробнее'),
                  ), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Не указано',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}