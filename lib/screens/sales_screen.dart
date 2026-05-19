import 'package:calendar_app/screens/auth_screen.dart';
import 'package:calendar_app/widgets/module_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesScreen extends StatefulWidget {
  final String userName;
  final String userSquad;

  const SalesScreen({
    Key? key,
    required this.userName,
    required this.userSquad,
  }) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Фильтры по датам
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(2024, 6, 1),
    end: DateTime(2024, 6, 30),
  );
  
  String _selectedPeriod = 'month';
  String _selectedManager = 'all';
  String _selectedTeam = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика продаж'),
        backgroundColor: Colors.green,
        elevation: 0,
                  leading: IconButton(  // Добавьте эту секцию
        icon: Icon(Icons.apps_rounded),
        onPressed: () {
          _showModuleSelectionDialog();
        },
        tooltip: 'Вернуться в меню',
      ),




        actions: [
                    PopupMenuButton<String>(
            icon: Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Бригада: ${widget.userSquad}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о пользователе и фильтрах
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.userName} • ${widget.userSquad}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFilterDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.date_range, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('dd.MM.yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange.end)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 14, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Объем продаж (кликабельно)
            GestureDetector(
              onTap: () => _showSalesDetailWithFilters(),
              child: _buildSalesVolumeSection(),
            ),
            const SizedBox(height: 24),

            // 2. Динамика продаж (кликабельные элементы)
            _buildSalesDynamicsSection(),
            const SizedBox(height: 24),

            // 3. Структура продаж по категориям (кликабельно)
            GestureDetector(
              onTap: () => _showCategoryDetailWithFilters(),
              child: _buildSalesStructureSection(),
            ),
            const SizedBox(height: 24),

            // 4. Эффективность менеджеров (с фильтром)
            _buildManagersEfficiencySection(),
            const SizedBox(height: 24),

            // 5. Эффективность бригад монтажников
            // _buildTeamsEfficiencySection(),
            // const SizedBox(height: 24),

            // 6. Статусы заказов (кликабельно) - ОБНОВЛЕНО
            GestureDetector(
              onTap: () => _showOrderStatusDetail(),
              child: _buildOrderStatusSection(),
            ),
          ],
        ),
      ),
    );
  }

  // Секция объема продаж
  Widget _buildSalesVolumeSection() {
    final filteredData = _getFilteredSalesData();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Объём продаж',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVolumeCard(
                  'Денежное выражение',
                  '${NumberFormat('#,###').format(filteredData['amount'])} ₽',
                  Icons.trending_up,
                  filteredData['amountChange'],
                ),
                Container(height: 50, width: 1, color: Colors.grey[300]),
                _buildVolumeCard(
                  'Количественное выражение',
                  '${filteredData['quantity']} шт.',
                  Icons.inventory,
                  filteredData['quantityChange'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeCard(String title, String value, IconData icon, double change) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.green),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: change >= 0 ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% к прошлому периоду',
            style: TextStyle(
              fontSize: 10,
              color: change >= 0 ? Colors.green[800] : Colors.red[800],
            ),
          ),
        ),
      ],
    );
  }

  // Секция динамики продаж
  Widget _buildSalesDynamicsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Динамика продаж',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    onTap: (index) {
                      setState(() {
                        if (index == 0) _selectedPeriod = 'month';
                        if (index == 1) _selectedPeriod = 'week';
                        if (index == 2) _selectedPeriod = 'day';
                      });
                    },
                    tabs: const [
                      Tab(text: 'По месяцам'),
                      Tab(text: 'По неделям'),
                      Tab(text: 'По дням'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildMonthlyDynamics(),
                        _buildWeeklyDynamics(),
                        _buildDailyDynamics(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyDynamics() {
    final monthlyData = _getFilteredMonthlyData();
    return ListView.builder(
      itemCount: monthlyData.length,
      itemBuilder: (context, index) {
        final data = monthlyData[index];
        return GestureDetector(
          onTap: () => _showPeriodDetail(data['month'], data['sales'], data['quantity']),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['month'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${NumberFormat('#,###').format(data['sales'])} ₽'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: data['sales'] / 1500000,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyDynamics() {
    final weeklyData = _getFilteredWeeklyData();
    return ListView.builder(
      itemCount: weeklyData.length,
      itemBuilder: (context, index) {
        final data = weeklyData[index];
        return GestureDetector(
          onTap: () => _showWeekOrdersDetail(data['week'], data['startDate'], data['endDate']),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['week'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${data['days']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${NumberFormat('#,###').format(data['sales'])} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Text('${data['quantity']} шт.', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyDynamics() {
    final dailyData = _getFilteredDailyData();
    return ListView.builder(
      itemCount: dailyData.length,
      itemBuilder: (context, index) {
        final data = dailyData[index];
        return GestureDetector(
          onTap: () => _showPeriodDetail(data['day'], data['sales'], data['quantity']),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 50,
                  child: Text(data['day'], style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: data['sales'] / 150000,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${NumberFormat('#,###').format(data['sales'])} ₽',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Секция структуры продаж
  Widget _buildSalesStructureSection() {
    final categories = _getFilteredCategoriesData();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Структура продаж по категориям',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...categories.map((category) {
              return GestureDetector(
                onTap: () => _showCategoryDetail(category['name']),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: category['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(category['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text('${NumberFormat('#,###').format(category['sales'])} ₽',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: category['percentage'] / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(category['color']),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${category['quantity']} шт.',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('${category['percentage']}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Секция эффективности менеджеров
  Widget _buildManagersEfficiencySection() {
    final managers = _getFilteredManagersData();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.green, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Менеджеры',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: _selectedManager,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Все')),
                    const DropdownMenuItem(value: 'Анна К.', child: Text('Анна К.')),
                    const DropdownMenuItem(value: 'Дмитрий В.', child: Text('Дмитрий В.')),
                    const DropdownMenuItem(value: 'Елена М.', child: Text('Елена М.')),
                    const DropdownMenuItem(value: 'Сергей П.', child: Text('Сергей П.')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedManager = value!;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Менеджер', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Продажи', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Заказов', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Выполнено', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Эффект.', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: managers.map((manager) {
                  return DataRow(
                    onSelectChanged: (_) => _showManagerDetail(manager),
                    cells: [
                      DataCell(Text(manager['name'])),
                      DataCell(Text('${NumberFormat('#,###').format(manager['sales'])} ₽')),
                      DataCell(Text('${manager['orders']}')),
                      DataCell(Text('${manager['completed']}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: manager['efficiency'] >= 85 ? Colors.green[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${manager['efficiency']}%',
                              style: TextStyle(
                                color: manager['efficiency'] >= 85 ? Colors.green[800] : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Секция эффективности бригад
  Widget _buildTeamsEfficiencySection() {
    final teams = _getFilteredTeamsData();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Row(
            //       children: [
            //         Icon(Icons.build, color: Colors.green, size: 28),
            //         const SizedBox(width: 8),
            //         const Text(
            //           'Бригады',
            //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //         ),
            //       ],
            //     ),
            //     DropdownButton<String>(
            //       value: _selectedTeam,
            //       items: [
            //         const DropdownMenuItem(value: 'all', child: Text('Все')),
            //         const DropdownMenuItem(value: 'Бригада №1 (Иванов)', child: Text('Бригада №1')),
            //         const DropdownMenuItem(value: 'Бригада №2 (Петров)', child: Text('Бригада №2')),
            //         const DropdownMenuItem(value: 'Бригада №3 (Сидоров)', child: Text('Бригада №3')),
            //         const DropdownMenuItem(value: 'Бригада №4 (Козлов)', child: Text('Бригада №4')),
            //       ],
            //       onChanged: (value) {
            //         setState(() {
            //           _selectedTeam = value!;
            //         });
            //       },
            //     ),
            //   ],
            // ),
            // const Divider(height: 24),
            // ...teams.map((team) {
            //   return GestureDetector(
            //     onTap: () => _showTeamDetail(team),
            //     child: Padding(
            //       padding: const EdgeInsets.only(bottom: 16),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: [
            //               Text(team['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            //             ],
            //           ),
            //           const SizedBox(height: 8),
            //           LinearProgressIndicator(
            //             value: team['efficiency'] / 100,
            //             backgroundColor: Colors.grey[200],
            //             valueColor: const AlwaysStoppedAnimation(Colors.green),
            //           ),
            //           const SizedBox(height: 4),
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: [
            //               Text('Выполнено: ${team['completed']} из ${team['total']}',
            //                   style: const TextStyle(fontSize: 12)),
            //               Text('${team['efficiency']}%',
            //                   style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   );
            // }),
          ],
        ),
      ),
    );
  }

  // Секция статусов заказов - ОБНОВЛЕНА (4 статуса)
  Widget _buildOrderStatusSection() {
    final statuses = _getFilteredOrderStatusData();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Статусы заказов',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildStatusCard(
                  'Открытый',
                  statuses['new']!,
                  Colors.blue,
                  Icons.lens_rounded,
                ),
                _buildStatusCard(
                  'В обработке',
                  statuses['processing']!,
                  Colors.orange,
                  Icons.settings,
                ),
                _buildStatusCard(
                  'Выполнено',
                  statuses['completed']!,
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatusCard(
                  'Отменено',
                  statuses['canceled']!,
                  Colors.red,
                  Icons.cancel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: statuses['completed']! / statuses['total']!,
              backgroundColor: Colors.red[100],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Процент выполнения: ${((statuses['completed']! / statuses['total']!) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // НОВЫЙ МЕТОД: Показ детализации заказов по неделе
  void _showWeekOrdersDetail(String weekName, String startDate, String endDate) {
    final orders = _getOrdersForWeek(weekName);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заказы за $weekName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$startDate - $endDate',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order['number'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                _buildStatusChip(order['status']),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  order['date'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.person, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  order['manager'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Сумма документа',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '${NumberFormat('#,###').format(order['documentAmount'])} ₽',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Сумма оплаты',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '${NumberFormat('#,###').format(order['paidAmount'])} ₽',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: order['paidAmount'] >= order['documentAmount'] 
                                          ? Colors.green 
                                          : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Всего заказов: ${orders.length}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch(status) {
      case 'Закрыто':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Этап отгрузки':
        color = Colors.orange;
        icon = Icons.local_shipping;
        break;
      case 'Открыто':
        color = Colors.blue;
        icon = Icons.pending;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ДАННЫЕ ЗАКАЗОВ ПО НЕДЕЛЯМ
  List<Map<String, dynamic>> _getOrdersForWeek(String weekName) {
    // Данные для 1-й недели июня
    if (weekName == '1-я неделя июня') {
      return [
        {
          'number': 'ЩД26-000123',
          'date': '01.06.2024',
          'documentAmount': 28000,
          'paidAmount': 28000,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
        {
          'number': 'ЩД26-000124',
          'date': '02.06.2024',
          'documentAmount': 4000,
          'paidAmount': 4000,
          'status': 'Этап отгрузки',
          'manager': 'Дмитрий В.',
        },
      ];
    }
    // Данные для 2-й недели июня
    else if (weekName == '2-я неделя июня') {
      return [
        {
          'number': 'ЩД26-000128',
          'date': '08.06.2024',
          'documentAmount': 67200,
          'paidAmount': 67200,
          'status': 'Закрыто',
          'manager': 'Дмитрий В.',
        },
        {
          'number': 'ЩД26-000129',
          'date': '09.06.2024',
          'documentAmount': 89100,
          'paidAmount': 89100,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
        {
          'number': 'ЩД26-000130',
          'date': '10.06.2024',
          'documentAmount': 56700,
          'paidAmount': 40000,
          'status': 'Этап отгрузки',
          'manager': 'Елена М.',
        },
        {
          'number': 'ЩД26-000131',
          'date': '12.06.2024',
          'documentAmount': 234500,
          'paidAmount': 234500,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
      ];
    }
    // Данные для 3-й недели июня
    else if (weekName == '3-я неделя июня') {
      return [
        {
          'number': 'ЩД26-000132',
          'date': '15.06.2024',
          'documentAmount': 98700,
          'paidAmount': 98700,
          'status': 'Закрыто',
          'manager': 'Дмитрий В.',
        },
        {
          'number': 'ЩД26-000133',
          'date': '16.06.2024',
          'documentAmount': 45600,
          'paidAmount': 45600,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
        {
          'number': 'ЩД26-000134',
          'date': '17.06.2024',
          'documentAmount': 123400,
          'paidAmount': 100000,
          'status': 'Этап отгрузки',
          'manager': 'Сергей П.',
        },
        {
          'number': 'ЩД26-000135',
          'date': '19.06.2024',
          'documentAmount': 78900,
          'paidAmount': 78900,
          'status': 'Закрыто',
          'manager': 'Елена М.',
        },
        {
          'number': 'ЩД26-000136',
          'date': '21.06.2024',
          'documentAmount': 34500,
          'paidAmount': 34500,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
      ];
    }
    // Данные для 4-й недели июня
    else if (weekName == '4-я неделя июня') {
      return [
        {
          'number': 'ЩД26-000137',
          'date': '22.06.2024',
          'documentAmount': 56700,
          'paidAmount': 30000,
          'status': 'Открыто',
          'manager': 'Дмитрий В.',
        },
        {
          'number': 'ЩД26-000138',
          'date': '23.06.2024',
          'documentAmount': 123400,
          'paidAmount': 123400,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
        {
          'number': 'ЩД26-000139',
          'date': '25.06.2024',
          'documentAmount': 89200,
          'paidAmount': 89200,
          'status': 'Закрыто',
          'manager': 'Елена М.',
        },
        {
          'number': 'ЩД26-000140',
          'date': '28.06.2024',
          'documentAmount': 45600,
          'paidAmount': 45600,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
      ];
    }
    // Данные для недель мая
    else {
      return [
        {
          'number': 'ЩД26-000100',
          'date': '01.05.2024',
          'documentAmount': 34500,
          'paidAmount': 34500,
          'status': 'Закрыто',
          'manager': 'Анна К.',
        },
        {
          'number': 'ЩД26-000101',
          'date': '03.05.2024',
          'documentAmount': 67800,
          'paidAmount': 50000,
          'status': 'Этап отгрузки',
          'manager': 'Дмитрий В.',
        },
        {
          'number': 'ЩД26-000102',
          'date': '05.05.2024',
          'documentAmount': 123400,
          'paidAmount': 123400,
          'status': 'Закрыто',
          'manager': 'Елена М.',
        },
        {
          'number': 'ЩД26-000103',
          'date': '07.05.2024',
          'documentAmount': 23400,
          'paidAmount': 0,
          'status': 'Открыто',
          'manager': 'Сергей П.',
        },
      ];
    }
  }

  // ДИАЛОГИ С ДЕТАЛИЗАЦИЕЙ

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбор периода'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Текущий месяц'),
              onTap: () {
                setState(() {
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(2024, 6, 1),
                    end: DateTime(2024, 6, 30),
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Прошлый месяц'),
              onTap: () {
                setState(() {
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(2024, 5, 1),
                    end: DateTime(2024, 5, 31),
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Квартал'),
              onTap: () {
                setState(() {
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(2024, 4, 1),
                    end: DateTime(2024, 6, 30),
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Выбрать даты'),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime(2024, 12, 31),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() {
                    _selectedDateRange = picked;
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSalesDetailWithFilters() {
    final data = _getFilteredSalesData();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детализация продаж'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogDetailRow('Период:', 
                '${DateFormat('dd.MM.yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange.end)}'),
              _buildDialogDetailRow('Общая выручка:', '${NumberFormat('#,###').format(data['amount'])} ₽'),
              _buildDialogDetailRow('Количество заказов:', '${data['quantity']} шт.'),
              _buildDialogDetailRow('Средний чек:', '${NumberFormat('#,###').format(data['amount'] ~/ data['quantity'])} ₽'),
              const Divider(),
              _buildDialogDetailRow('Лучший день:', _getBestDay()),
              _buildDialogDetailRow('Лучшая неделя:', _getBestWeek()),
              _buildDialogDetailRow('Лучший месяц:', _getBestMonth()),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showPeriodDetail(String period, int sales, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Детализация: $period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogDetailRow('Выручка:', '${NumberFormat('#,###').format(sales)} ₽'),
            _buildDialogDetailRow('Количество заказов:', '$quantity шт.'),
            _buildDialogDetailRow('Средний чек:', '${NumberFormat('#,###').format(sales ~/ quantity)} ₽'),
            const Divider(),
            _buildDialogDetailRow('Топ товары:', ''),
            const SizedBox(height: 4),
             Text('• Дверь входная - ${(sales * 0.3).toInt()} шт.'),
             Text('• Стол обеденный - ${(sales * 0.2).toInt()} шт.'),
             Text('• Шкаф-купе - ${(sales * 0.15).toInt()} шт.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showCategoryDetail(String category) {
    final data = _getFilteredCategoriesData().firstWhere((c) => c['name'] == category);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Детализация: ${data['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogDetailRow('Выручка:', '${NumberFormat('#,###').format(data['sales'])} ₽'),
            _buildDialogDetailRow('Количество:', '${data['quantity']} шт.'),
            _buildDialogDetailRow('Доля:', '${data['percentage']}%'),
            const Divider(),
            _buildDialogDetailRow('Топ товары:', ''),
            if (data['name'] == 'Мебель')
              const Text('• Стол обеденный - 45 шт.\n• Шкаф-купе - 23 шт.\n• Стулья - 21 шт.'),
            if (data['name'] == 'Двери')
              const Text('• Дверь входная - 78 шт.\n• Дверь межкомнатная - 54 шт.\n• Дверь балконная - 24 шт.'),
            if (data['name'] == 'Фурнитура')
              const Text('• Ручки - 234 шт.\n• Петли - 156 шт.\n• Замки - 89 шт.'),
            if (data['name'] == 'Услуги монтажа')
              const Text('• Установка дверей - 28 шт.\n• Сборка мебели - 19 шт.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showCategoryDetailWithFilters() {
    final categories = _getFilteredCategoriesData();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Детализация по категориям', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...categories.map((cat) {
                return ListTile(
                  title: Text(cat['name']),
                  subtitle: Text('${cat['quantity']} шт. • ${cat['percentage']}%'),
                  trailing: Text('${NumberFormat('#,###').format(cat['sales'])} ₽'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCategoryDetail(cat['name']);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagerDetail(Map<String, dynamic> manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(manager['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogDetailRow('Продажи за период:', '${NumberFormat('#,###').format(manager['sales'])} ₽'),
            _buildDialogDetailRow('Всего заказов:', '${manager['orders']}'),
            _buildDialogDetailRow('Выполнено:', '${manager['completed']}'),
            _buildDialogDetailRow('Отменено:', '${manager['orders'] - manager['completed']}'),
            _buildDialogDetailRow('Эффективность:', '${manager['efficiency']}%'),
            const Divider(),
            _buildDialogDetailRow('Лучший товар:', _getManagerBestProduct(manager['name'])),
            _buildDialogDetailRow('Средний чек:', '${NumberFormat('#,###').format(manager['sales'] ~/ manager['orders'])} ₽'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showTeamDetail(Map<String, dynamic> team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(team['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogDetailRow('Выполнено заказов:', '${team['completed']}/${team['total']}'),
            _buildDialogDetailRow('Эффективность:', '${team['efficiency']}%'),
            _buildDialogDetailRow('Среднее время:', '${team['avgTime']} ч.'),
            _buildDialogDetailRow('Рейтинг:', '${team['rating']}★'),
            const Divider(),
            _buildDialogDetailRow('Быстрый монтаж:', '${team['avgTime'] - 1} ч. (среднее)'),
            _buildDialogDetailRow('Сложные объекты:', '${(team['total'] * 0.3).toInt()} шт.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showOrderStatusDetail() {
    final statuses = _getFilteredOrderStatusData();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детализация статусов заказов'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogDetailRow('Открытые:', '${statuses['new']} (${((statuses['new']! / statuses['total']!) * 100).toStringAsFixed(1)}%)'),
              _buildDialogDetailRow('В обработке:', '${statuses['processing']} (${((statuses['processing']! / statuses['total']!) * 100).toStringAsFixed(1)}%)'),
              _buildDialogDetailRow('Выполнено:', '${statuses['completed']} (${((statuses['completed']! / statuses['total']!) * 100).toStringAsFixed(1)}%)'),
              _buildDialogDetailRow('Отменено:', '${statuses['canceled']} (${((statuses['canceled']! / statuses['total']!) * 100).toStringAsFixed(1)}%)'),
              const Divider(),
              const Text('Причины отмен:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Изменение решения клиента - ${(statuses['canceled']! * 0.4).toInt()}'),
              Text('• Не подошёл товар - ${(statuses['canceled']! * 0.25).toInt()}'),
              Text('• Долгая доставка - ${(statuses['canceled']! * 0.2).toInt()}'),
              Text('• Финансовые причины - ${(statuses['canceled']! * 0.15).toInt()}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value, {bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : null)),
        ],
      ),
    );
  }

  // МЕТОДЫ ФИЛЬТРАЦИИ ДАННЫХ

  Map<String, dynamic> _getFilteredSalesData() {
    // Фильтруем данные в зависимости от выбранного периода
    if (_selectedDateRange.start.month == 6) {
      return {
        'amount': 125000,
        'amountChange': 15.5,
        'quantity': 34,
        'quantityChange': 8.2,
      };
    } else if (_selectedDateRange.start.month == 5) {
      return {
        'amount': 1100000,
        'amountChange': -5.2,
        'quantity': 310,
        'quantityChange': -3.1,
      };
    } else {
      return {
        'amount': 3350000,
        'amountChange': 22.8,
        'quantity': 935,
        'quantityChange': 18.5,
      };
    }
  }

  List<Map<String, dynamic>> _getFilteredMonthlyData() {
    if (_selectedDateRange.start.month == 6) {
      return [
        {'month': 'Июнь', 'sales': 1250000, 'quantity': 347},
      ];
    } else if (_selectedDateRange.start.month == 5) {
      return [
        {'month': 'Май', 'sales': 1100000, 'quantity': 310},
      ];
    } else {
      return [
        {'month': 'Апрель', 'sales': 980000, 'quantity': 278},
        {'month': 'Май', 'sales': 1100000, 'quantity': 310},
        {'month': 'Июнь', 'sales': 1250000, 'quantity': 347},
      ];
    }
  }

  List<Map<String, dynamic>> _getFilteredWeeklyData() {
    if (_selectedDateRange.start.month == 6) {
      return [
        {'week': '1-я неделя июня', 'days': '1-7 июня', 'sales': 32000, 'quantity': 2, 'startDate': '01.06.2024', 'endDate': '07.06.2024'},
        {'week': '2-я неделя июня', 'days': '8-14 июня', 'sales': 38000, 'quantity': 3, 'startDate': '08.06.2024', 'endDate': '14.06.2024'},
        {'week': '3-я неделя июня', 'days': '15-21 июня', 'sales': 41000, 'quantity': 3, 'startDate': '15.06.2024', 'endDate': '21.06.2024'},
        {'week': '4-я неделя июня', 'days': '22-28 июня', 'sales': 31000, 'quantity': 1, 'startDate': '22.06.2024', 'endDate': '28.06.2024'},
      ];
    } else {
      return [
        {'week': '1-я неделя мая', 'days': '1-7 мая', 'sales': 280000, 'quantity': 78, 'startDate': '01.05.2024', 'endDate': '07.05.2024'},
        {'week': '2-я неделя мая', 'days': '8-14 мая', 'sales': 310000, 'quantity': 85, 'startDate': '08.05.2024', 'endDate': '14.05.2024'},
        {'week': '3-я неделя мая', 'days': '15-21 мая', 'sales': 350000, 'quantity': 95, 'startDate': '15.05.2024', 'endDate': '21.05.2024'},
        {'week': '4-я неделя мая', 'days': '22-28 мая', 'sales': 290000, 'quantity': 80, 'startDate': '22.05.2024', 'endDate': '28.05.2024'},
      ];
    }
  }

  List<Map<String, dynamic>> _getFilteredDailyData() {
    if (_selectedDateRange.start.month == 6) {
      return [
        {'day': 'Пн', 'sales': 145000, 'quantity': 40},
        {'day': 'Вт', 'sales': 162000, 'quantity': 45},
        {'day': 'Ср', 'sales': 178000, 'quantity': 49},
        {'day': 'Чт', 'sales': 191000, 'quantity': 53},
        {'day': 'Пт', 'sales': 210000, 'quantity': 58},
        {'day': 'Сб', 'sales': 168000, 'quantity': 46},
        {'day': 'Вс', 'sales': 96000, 'quantity': 27},
      ];
    } else {
      return [
        {'day': 'Пн', 'sales': 125000, 'quantity': 35},
        {'day': 'Вт', 'sales': 142000, 'quantity': 39},
        {'day': 'Ср', 'sales': 158000, 'quantity': 44},
        {'day': 'Чт', 'sales': 171000, 'quantity': 47},
        {'day': 'Пт', 'sales': 190000, 'quantity': 52},
        {'day': 'Сб', 'sales': 148000, 'quantity': 41},
        {'day': 'Вс', 'sales': 86000, 'quantity': 24},
      ];
    }
  }

  List<Map<String, dynamic>> _getFilteredCategoriesData() {
    if (_selectedDateRange.start.month == 6) {
      return [
        {'name': 'Мебель', 'sales': 625000, 'quantity': 3, 'percentage': 9, 'color': Colors.blue},
        {'name': 'Двери', 'sales': 312500, 'quantity': 19, 'percentage': 56, 'color': Colors.orange},
        {'name': 'Фурнитура', 'sales': 187500, 'quantity': 8, 'percentage': 23, 'color': Colors.purple},
        {'name': 'Услуги монтажа', 'sales': 125000, 'quantity': 4, 'percentage': 12, 'color': Colors.teal},
      ];
    } else {
      return [
        {'name': 'Мебель', 'sales': 550000, 'quantity': 78, 'percentage': 50, 'color': Colors.blue},
        {'name': 'Двери', 'sales': 275000, 'quantity': 137, 'percentage': 25, 'color': Colors.orange},
        {'name': 'Фурнитура', 'sales': 165000, 'quantity': 206, 'percentage': 15, 'color': Colors.purple},
        {'name': 'Услуги монтажа', 'sales': 110000, 'quantity': 41, 'percentage': 10, 'color': Colors.teal},
      ];
    }
  }

  List<Map<String, dynamic>> _getFilteredManagersData() {
    List<Map<String, dynamic>> managers = [
      {'name': 'Анна К.', 'sales': 45000, 'orders': 4, 'completed': 4, 'efficiency': 100},
      {'name': 'Дмитрий В.', 'sales': 38000, 'orders': 12, 'completed': 10, 'efficiency': 83},
      {'name': 'Елена М.', 'sales': 29000, 'orders': 10, 'completed': 4, 'efficiency': 40},
      {'name': 'Сергей П.', 'sales': 13000, 'orders': 32, 'completed': 16, 'efficiency': 50},
    ];

    if (_selectedManager != 'all') {
      managers = managers.where((m) => m['name'] == _selectedManager).toList();
    }

    return managers;
  }

  List<Map<String, dynamic>> _getFilteredTeamsData() {
    List<Map<String, dynamic>> teams = [
      {'name': 'Бригада №1 (Иванов)', 'completed': 42, 'total': 45, 'efficiency': 93, 'avgTime': 4.2, 'rating': 4.8},
      {'name': 'Бригада №2 (Петров)', 'completed': 38, 'total': 42, 'efficiency': 90, 'avgTime': 5.1, 'rating': 4.5},
      {'name': 'Бригада №3 (Сидоров)', 'completed': 35, 'total': 41, 'efficiency': 85, 'avgTime': 5.8, 'rating': 4.2},
      {'name': 'Бригада №4 (Козлов)', 'completed': 28, 'total': 37, 'efficiency': 76, 'avgTime': 6.5, 'rating': 3.9},
    ];

    if (_selectedTeam != 'all') {
      teams = teams.where((t) => t['name'] == _selectedTeam).toList();
    }

    return teams;
  }

  Map<String, int> _getFilteredOrderStatusData() {
    if (_selectedDateRange.start.month == 6) {
      return {
        'new': 0,
        'processing': 2,
        'completed': 34,
        'canceled': 16+6+2,
        'total': 16+6+2+34,
      };
    } else {
      return {
        'new': 18,
        'processing': 35,
        'completed': 138,
        'canceled': 28,
        'total': 219,
      };
    }
  }

  String _getBestDay() {
    final days = _getFilteredDailyData();
    final bestDay = days.reduce((curr, next) => curr['sales'] > next['sales'] ? curr : next);
    return '${bestDay['day']} (${NumberFormat('#,###').format(bestDay['sales'])} ₽)';
  }

  String _getBestWeek() {
    final weeks = _getFilteredWeeklyData();
    final bestWeek = weeks.reduce((curr, next) => curr['sales'] > next['sales'] ? curr : next);
    return '${bestWeek['week']} (${NumberFormat('#,###').format(bestWeek['sales'])} ₽)';
  }

  String _getBestMonth() {
    final months = _getFilteredMonthlyData();
    final bestMonth = months.reduce((curr, next) => curr['sales'] > next['sales'] ? curr : next);
    return '${bestMonth['month']} (${NumberFormat('#,###').format(bestMonth['sales'])} ₽)';
  }

  String _getManagerBestProduct(String managerName) {
    if (managerName == 'Анна К.') return 'Дверь входная (32 шт.)';
    if (managerName == 'Дмитрий В.') return 'Стол обеденный (28 шт.)';
    if (managerName == 'Елена М.') return 'Шкаф-купе (21 шт.)';
    return 'Фурнитура (156 шт.)';
  }
  
void _showModuleSelectionDialog() {
  // Очищаем navigation stack и показываем диалог
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

    Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_squad');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }}