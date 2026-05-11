import 'package:calendar_app/models/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/module_selection_dialog.dart';

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
  bool isPersonal = true;
  late Uri uri;

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
      if (isPersonal) {
        uri = Uri.parse(
          'http://${Globals.ip_conf}:6767/complaints_personal?login=${widget.userName}&squad=${widget.userSquad}}'
        );
      } else {
        uri = Uri.parse(
          'http://${Globals.ip_conf}:6767/complaints?name=${widget.userName}&squad=${widget.userSquad}}'
        );
      }
      
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

  void toggleClaimsType(bool value) {
    setState(() {
      isPersonal = value;
    });
    fetchClaims();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Претензии'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _showModuleSelectionDialog();
          },
          tooltip: 'Вернуться в меню',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshClaims,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Row(
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
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPersonal ? Icons.person : Icons.people,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isPersonal ? 'Персональные' : 'Общие',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isPersonal,
                        onChanged: toggleClaimsType,
                        activeColor: Colors.orange,
                        activeTrackColor: Colors.orange.shade100,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                _buildInfoRow(Icons.location_on, 'Адрес:', claim['adress']),
                _buildInfoRow(Icons.phone, 'Телефон:', claim['telephone']),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClaimDetailsScreen(
                                claimId: claim['numerator'],
                                currentUser: widget.userName,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.info_outline),
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

// Экран детальной информации по претензии
class ClaimDetailsScreen extends StatefulWidget {
  final String claimId;
  final String currentUser;

  const ClaimDetailsScreen({
    Key? key,
    required this.claimId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  Map<String, dynamic>? claimData;
  List<dynamic> stages = [];
  bool isLoading = true;
  bool isLoadingStages = true;
  String? errorMessage;
  String? errorMessageStages;
  
  @override
  void initState() {
    super.initState();
    fetchClaimDetails();
    fetchStages();
  }

  Future<void> fetchClaimDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        'http://${Globals.ip_conf}:6767/complaint1/?url=${widget.claimId.toString().replaceAll(" ", "") }'
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          if (data is List && data.isNotEmpty) {
            claimData = data[0] as Map<String, dynamic>;
          } else if (data is Map<String, dynamic>) {
            claimData = data;
          }
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

  Future<void> fetchStages() async {
    setState(() {
      isLoadingStages = true;
      errorMessageStages = null;
    });

    try {
      final uri = Uri.parse(
        'http://${Globals.ip_conf}:6767/complaint2/?url=${widget.claimId.toString().replaceAll(" ", "") }'
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          stages = data;
          isLoadingStages = false;
        });
      } else {
        setState(() {
          errorMessageStages = 'Ошибка загрузки: ${response.statusCode}';
          isLoadingStages = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessageStages = 'Ошибка соединения: $e';
        isLoadingStages = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.claimId),
          backgroundColor: Colors.orange,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info), text: 'Информация'),
              Tab(icon: Icon(Icons.timeline), text: 'Этапы работы'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // Первая вкладка: Информация о претензии
            isLoading
                ? const Center(child: CircularProgressIndicator())
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
                              onPressed: fetchClaimDetails,
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : claimData == null
                        ? const Center(child: Text('Данные не найдены'))
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailSection('Основная информация', Icons.info_outline, [
                                  _buildDetailRow('Номер', claimData!['numerator']),
                                  _buildDetailRow('Дата создания', claimData!['date']),
                                  _buildDetailRow('Статус', claimData!['bigstatus']),
                                  _buildDetailRow('Клиент', claimData!['client']),
                                  _buildDetailRow('Телефон', claimData!['telephone']),
                                  _buildDetailRow('Адрес', claimData!['adress']),
                                ]),
                                SizedBox(height: 16),
                                _buildDetailSection('Информация о заказе', Icons.shopping_cart, [
                                  _buildDetailRow('Основание', claimData!['base']),
                                  _buildDetailRow('Тип двери', claimData!['doortipe']),
                                  _buildDetailRow('Склад', claimData!['werehouse']),
                                  _buildDetailRow('Организация', claimData!['organization']),
                                ]),
                                if (claimData!['text'] != null && claimData!['text'].toString().isNotEmpty)
                                  SizedBox(height: 16),
                                if (claimData!['text'] != null && claimData!['text'].toString().isNotEmpty)
                                  _buildDetailSection('Текст претензии', Icons.description, [
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Text(
                                        claimData!['text'],
                                        style: TextStyle(fontSize: 14, height: 1.5),
                                      ),
                                    ),
                                  ]),
                                SizedBox(height: 16),
                                _buildDetailSection('Ответственный', Icons.person, [
                                  _buildDetailRow('Менеджер', claimData!['name']),
                                ]),
                              ],
                            ),
                          ),
            // Вторая вкладка: Этапы работы
            isLoadingStages
                ? const Center(child: CircularProgressIndicator())
                : errorMessageStages != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(errorMessageStages!),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchStages,
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : stages.isEmpty
                        ? const Center(child: Text('Нет данных об этапах'))
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: stages.length,
                            itemBuilder: (context, index) {
                              final stage = stages[index];
                              final isEditable = stage['expert_user'] == widget.currentUser;
                              return _buildStageCard(stage, isEditable);
                            },
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.orange.shade700),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
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

  Widget _buildStageCard(Map<String, dynamic> stage, bool isEditable) {
    Color statusColor;
    switch (stage['status']) {
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
      elevation: 2,
      child: InkWell(
        onTap: isEditable ? () {
          _showEditStageDialog(stage);
        } : null,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          stage['type'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isEditable) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(stage['status']),
                    backgroundColor: statusColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (stage['expert'] != null && stage['expert'].toString().isNotEmpty)
                _buildStageInfoRow(Icons.person, 'Исполнитель', stage['expert']),
              _buildStageInfoRow(Icons.play_circle_outline, 'Дата начала', _formatDate(stage['dateon'])),
              _buildStageInfoRow(Icons.check_circle_outline, 'Дата завершения', _formatDate(stage['dateoff'])),
              if (stage['message'] != null && stage['message'].toString().isNotEmpty)
                _buildStageInfoRow(Icons.message, 'Сообщение', stage['message']),
              if (isEditable)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Нажмите для редактирования',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStageDialog(Map<String, dynamic> stage) {
    final TextEditingController expertController = TextEditingController(text: stage['expert'] ?? '');
    final TextEditingController dateonController = TextEditingController(text: stage['dateon'] ?? '');
    final TextEditingController dateoffController = TextEditingController(text: stage['dateoff'] ?? '');
    final TextEditingController messageController = TextEditingController(text: stage['message'] ?? '');
    String selectedStatus = stage['status'] ?? 'В работе';
    String selectedPerson = stage['expert'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange.shade700),
                  SizedBox(width: 8),
                  Text('Редактирование:'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPerson,
                      decoration: InputDecoration(
                        labelText: 'Исполнитель',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: ['Нелаев Виталий', 'Щенников Дмитрий', 'Не рассмотрено'].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedPerson = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: dateonController,
                      decoration: InputDecoration(
                        labelText: 'Дата начала',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.play_circle_outline),
                        hintText: 'Формат: 16.04.2026 0:00:00',
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: dateoffController,
                      decoration: InputDecoration(
                        labelText: 'Дата завершения',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                        hintText: 'Формат: 16.04.2026 0:00:00',
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Статус',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: ['В работе', 'Исполненно', 'Не рассмотрено'].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedStatus = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: 'Сообщение',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Отмена',style: TextStyle(color: Colors.grey.shade900),),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Пока ничего не делает
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Сохранение временно недоступно'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  label: Text('Сохранить',style: TextStyle(color: Colors.grey.shade900),),
                  style: ElevatedButton.styleFrom(
                    
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStageInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date == null || date.isEmpty) return 'Не указано';
    if (date.startsWith('01.01.0001')) return 'Не указано';
    return date;
  }
}