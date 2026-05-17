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
  List<dynamic> filteredClaims = [];
  bool isLoading = true;
  String? errorMessage;
  bool isPersonal = true;
  late Uri uri;
  
  // Фильтр по статусу
  String selectedStatusFilter = 'Все';
  final List<String> statusFilters = ['Все', 'Исполненно', 'В работе', 'Не рассмотрено'];

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
          _applyFilter(); // Применяем фильтр после загрузки
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

  // Применение фильтра по статусу
  void _applyFilter() {
    if (selectedStatusFilter == 'Все') {
      filteredClaims = List.from(claims);
    } else {
      filteredClaims = claims.where((claim) {
        return claim['bigstatus'] == selectedStatusFilter;
      }).toList();
    }
    setState(() {});
  }

  // Изменение фильтра
  void _changeStatusFilter(String? newFilter) {
    if (newFilter != null && newFilter != selectedStatusFilter) {
      selectedStatusFilter = newFilter;
      _applyFilter();
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
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Пользователь: ${widget.userName}',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Подразделение: ${widget.userSquad}',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isLoading)
                      Text(
                        'Всего: ${claims.length} | Отфильтровано: ${filteredClaims.length}',
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
                  child: Column(
                    children: [
                      Row(
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
                      SizedBox(height: 12),
                      // Фильтр по статусу
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 20,
                              color: Colors.orange.shade700,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Фильтр по статусу:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedStatusFilter,
                                isExpanded: true,
                                underline: SizedBox(),
                                items: statusFilters.map((String status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Row(
                                      children: [
                                        _getStatusIcon(status),
                                        SizedBox(width: 8),
                                        Text(status),
                                        if (status != 'Все') ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusCount(status).toString(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: _changeStatusFilter,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    : filteredClaims.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  selectedStatusFilter == 'Все' 
                                    ? 'Нет претензий' 
                                    : 'Нет претензий со статусом "$selectedStatusFilter"',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                if (selectedStatusFilter != 'Все')
                                  TextButton.icon(
                                    onPressed: () => _changeStatusFilter('Все'),
                                    icon: Icon(Icons.clear),
                                    label: Text('Сбросить фильтр'),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: refreshClaims,
                            child: ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: filteredClaims.length,
                              itemBuilder: (context, index) {
                                final claim = filteredClaims[index];
                                return _buildClaimCard(claim);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // Получение иконки для статуса
  Widget _getStatusIcon(String status) {
    IconData iconData;
    switch (status) {
      case 'Исполненно':
        iconData = Icons.check_circle;
        break;
      case 'В работе':
        iconData = Icons.pending;
        break;
      case 'Не рассмотрено':
        iconData = Icons.error;
        break;
      default:
        iconData = Icons.filter_list;
    }
    return Icon(iconData, size: 18, color: _getStatusColor(status));
  }

  // Получение цвета для статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Исполненно':
        return Colors.green;
      case 'В работе':
        return Colors.orange;
      case 'Не рассмотрено':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Подсчет количества претензий с определенным статусом
  int _getStatusCount(String status) {
    return claims.where((claim) => claim['bigstatus'] == status).length;
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
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Клиент: ${claim['client']}',
              overflow: TextOverflow.ellipsis,
            ),
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
          Flexible(
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
        onTap: (isEditable || Globals.userName == "Dim") ? () {
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
                        if (isEditable || Globals.userName == "Dim") ...[
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
              if (isEditable || Globals.userName == "Dim") 
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

  Future<void> _saveAllStages() async {
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Собираем данные для запроса
      String cleanClaimId = widget.claimId.replaceAll(" ", "");
      
      // Разделители
      const String typeSeparator = "%";
      const String dateSeparator = '\$';
      
      // Собираем массивы значений
      List<String> types = [];
      List<String> experts = [];
      List<String> dateons = [];
      List<String> dateoffs = [];
      List<String> messages = [];
      List<String> statuses = [];
      
      for (var stage in stages) {
        types.add(stage['type']?.toString() ?? '');
        experts.add(stage['expert']?.toString() ?? '');
        dateons.add(stage['dateon']?.toString() ?? '');
        dateoffs.add(stage['dateoff']?.toString() ?? '');
        messages.add(stage['message']?.toString() ?? '');
        statuses.add(stage['status']?.toString() ?? '');
      }
      
      // Формируем строки с разделителями
      String typesStr = types.join(typeSeparator);
      String expertsStr = experts.join(typeSeparator);
      String dateonsStr = dateons.join(dateSeparator);
      String dateoffsStr = dateoffs.join(dateSeparator);
      String messagesStr = messages.join(typeSeparator);
      String statusesStr = statuses.join(typeSeparator);
      
      // Кодируем параметры для URL
      String encodedTypes = Uri.encodeComponent(typesStr);
      String encodedExperts = Uri.encodeComponent(expertsStr);
      String encodedDateons = Uri.encodeComponent(dateonsStr);
      String encodedDateoffs = Uri.encodeComponent(dateoffsStr);
      String encodedMessages = Uri.encodeComponent(messagesStr);
      String encodedStatuses = Uri.encodeComponent(statusesStr);
      String encodedClaimId = Uri.encodeComponent(cleanClaimId);
      
      // Формируем URL
      final uri = Uri.parse(
        'http://${Globals.ip_conf}:6767/complaint_edit/'
        '?urll=$encodedClaimId'
        '&typee=$encodedTypes'
        '&expert=$encodedExperts'
        '&dateon=$encodedDateons'
        '&dateoff=$encodedDateoffs'
        '&message=$encodedMessages'
        '&status=$encodedStatuses'
      );
      
      // Отправляем GET запрос
      final response = await http.post(uri);
      
      // Закрываем диалог загрузки
      Navigator.of(context).pop();
      
      if (response.statusCode == 200) {
        // Успешно сохранено
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );
        // Обновляем данные
        await fetchStages();
        await fetchClaimDetails();
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      // Закрываем диалог загрузки, если он открыт
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
void _showEditStageDialog(Map<String, dynamic> stage) {
  // Находим индекс текущего этапа
  final int stageIndex = stages.indexWhere((s) => s['type'] == stage['type']);
  
  if (stageIndex == -1) return;
  
  // Создаем контроллеры для каждого этапа
  List<TextEditingController> expertControllers = [];
  List<TextEditingController> dateonControllers = [];
  List<TextEditingController> dateoffControllers = [];
  List<TextEditingController> messageControllers = [];
  List<String> selectedStatuses = [];
  
  // Инициализируем контроллеры для всех этапов
  for (int i = 0; i < stages.length; i++) {
    final s = stages[i];
    expertControllers.add(TextEditingController(text: s['expert'] ?? ''));
    dateonControllers.add(TextEditingController(text: _formatDateForEditing(s['dateon'])));
    dateoffControllers.add(TextEditingController(text: _formatDateForEditing(s['dateoff'])));
    messageControllers.add(TextEditingController(text: s['message'] ?? ''));
    selectedStatuses.add(s['status'] ?? 'В работе');
  }
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Редактирование'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: DefaultTabController(
                length: stages.length,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: stages.map((s) => Tab(text: s['type'])).toList(),
                      labelColor: Colors.orange.shade700,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        children: List.generate(stages.length, (index) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedStatuses[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Статус',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.flag),
                                  ),
                                  items: const ['В работе', 'Исполненно', 'Не рассмотрено', 'Не требуется'].map((String status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setStateDialog(() {
                                      selectedStatuses[index] = newValue!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: expertControllers[index].text.isEmpty ? null : expertControllers[index].text,
                                  decoration: const InputDecoration(
                                    labelText: 'Исполнитель',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  items: const [
                                    'Нелаев Виталий',
                                    'Дмитрий Щенников',
                                    'Балаботкин Павел',
                                    'Заборонок Евгений',
                                    'Гончаров Павел',
                                    'Гончаров Виталий',
                                    ''
                                  ].map((String expert) {
                                    return DropdownMenuItem<String>(
                                      value: expert,
                                      child: Text(expert.isEmpty ? 'Не выбран' : expert),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setStateDialog(() {
                                      expertControllers[index].text = newValue ?? '';
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Дата начала
                                TextField(
                                  controller: dateonControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Дата начала',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.play_circle_outline),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (pickedDate != null) {
                                          String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.year}";
                                          setStateDialog(() {
                                            dateonControllers[index].text = formattedDate;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Дата завершения
                                TextField(
                                  controller: dateoffControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Дата завершения',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.check_circle_outline),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (pickedDate != null) {
                                          String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.year}";
                                          setStateDialog(() {
                                            dateoffControllers[index].text = formattedDate;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                TextField(
                                  controller: messageControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Сообщение',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.message),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Обновляем данные в массиве stages
                  for (int i = 0; i < stages.length; i++) {
                    stages[i]['expert'] = expertControllers[i].text;
                    stages[i]['dateon'] = dateonControllers[i].text;
                    stages[i]['dateoff'] = dateoffControllers[i].text;
                    stages[i]['message'] = messageControllers[i].text;
                    stages[i]['status'] = selectedStatuses[i];
                  }
                  
                  // Закрываем диалог редактирования
                  Navigator.of(context).pop();
                  
                  // Сохраняем все этапы
                  await _saveAllStages();
                  
                  // Обновляем UI
                  setState(() {});
                },
                icon: const Icon(Icons.save),
                label: const Text('Сохранить все'),
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

  // Метод для выбора даты и времени
  Future<void> _selectDateTime(BuildContext context, TextEditingController controller, StateSetter setStateDialog) async {
    // Сначала выбираем дату
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _parseDateFromString(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade900,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Затем выбираем время
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_parseDateFromString(controller.text) ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.orange.shade700,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // Форматируем для отображения
        String formattedDate = _formatDateTimeForDisplay(finalDateTime);
        
        setStateDialog(() {
          controller.text = formattedDate;
        });
      }
    }
  }

  // Парсинг даты из строки
  DateTime? _parseDateFromString(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      // Формат: "16.04.2026 13:19:52"
      List<String> parts = dateString.split(' ');
      if (parts.length >= 2) {
        List<String> dateParts = parts[0].split('.');
        List<String> timeParts = parts[1].split(':');
        
        if (dateParts.length == 3 && timeParts.length >= 2) {
          return DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
          );
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Форматирование для отображения в UI
  String _formatDateTimeForDisplay(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  // Форматирование для сервера (без изменений)
  String _formatDateForEditing(String? date) {
    if (date == null || date.isEmpty) return '';
    if (date.startsWith('01.01.0001')) return '';
    return date;
  }

  // Конвертация для отправки на сервер
  String _convertToServerFormat(String displayDate) {
    if (displayDate.isEmpty) return '';
    return displayDate;
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
    if (date.isEmpty) return 'Не указано';
    if (date.startsWith('01.01.0001')) return 'Не указано';
    return date;
  }
}