import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/globals.dart';
import '../widgets/two_line_selector.dart';
import 'auth_screen.dart';
import 'package:smart_actions_text/smart_actions_text.dart';
import '../widgets/module_selection_dialog.dart'; // Добавьте эту строку

 WebSocketChannel channel = WebSocketChannel.connect(
      Uri.parse('ws://${Globals.ip_conf}:6767/ws/${Globals.userName}'),
    );

enum CalendarViewType {
  monthGrid,
  table,
}


class CalendarScreen extends StatefulWidget {
  final String userName;
  final String userSquad;

  CalendarScreen({
    required this.userName,
    required this.userSquad,
  });

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _currentYear = DateTime.now().year;
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  List<Event> _localEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedSquad;
  List<String> _availableSquads = [];
  
  CalendarViewType _currentViewType = CalendarViewType.table;
  
  DateTime _tableStartDate = DateTime.now();
  DateTime _tableEndDate = DateTime.now().add(Duration(days: 30));
  List<String> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _loadLocalEvents();
    _fetchEvents();
    _updateTableDatesFromCurrentMonth();
    _updateAvailableDates();
  }

  void _updateAvailableDates() {
    _availableDates.clear();
    for (int i = 0; i <= 30; i++) {
      _availableDates.add(
        '${_tableStartDate.add(Duration(days: i)).day.toString().padLeft(2, '0')}.${_tableStartDate.add(Duration(days: i)).month.toString().padLeft(2, '0')}.${(_tableStartDate.add(Duration(days: i)).year - 2000).toString().padLeft(2, '0')}'
      );
    }
    setState(() {});
  }

  Future<void> _loadLocalEvents() async {
    final prefs = await SharedPreferences.getInstance();
    String? eventsJson = prefs.getString('local_events');
    if (eventsJson != null) {
      try {
        List<dynamic> decoded = json.decode(eventsJson);
        setState(() {
          _localEvents = decoded.map((item) => Event.fromJson(item)).toList();
          _applyFilter();
        });
      } catch (e) {
        print('Ошибка загрузки локальных событий: $e');
      }
    }
  }

  Future<void> _saveLocalEvents() async {
    final prefs = await SharedPreferences.getInstance();
    String eventsJson = json.encode(_localEvents.map((e) => e.toJson()).toList());
    await prefs.setString('local_events', eventsJson);
  }

  Future<void> _login(Event event) async {
    try {
      final response = await http.put(
        Uri.parse('http://${Globals.ip_conf}:6767/grafik/?squad=${widget.userSquad}&date=${event.date.day.toString().padLeft(2, '0')}.${event.date.month.toString().padLeft(2, '0')}.${(event.date.year - 2000).toString().padLeft(2, '0')}&time=${event.time}&text=${event.text}&name=${widget.userName}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Ошибка загрузки локальных событий: $e');
    }
  }
  
  Future<bool> _sendEventToServerDel(Event event) async {
    try {
      final response = await http.delete(
        Uri.parse('http://${Globals.ip_conf}:6767/grafik/?squad=${event.squad}&date=${event.date.day.toString().padLeft(2, '0')}.${event.date.month.toString().padLeft(2, '0')}.${(event.date.year - 2000).toString().padLeft(2, '0')}&time=${event.time}&name=${widget.userName}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _sendEventToServer(Event event) async {
    try {
      final response = await http.put(
        Uri.parse('http://${Globals.ip_conf}:6767/grafik/?squad=${event.squad}&date=${event.date.day.toString().padLeft(2, '0')}.${event.date.month.toString().padLeft(2, '0')}.${(event.date.year - 2000).toString().padLeft(2, '0')}&time=${event.time}&text=${event.text}&name=${widget.userName}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _addEvent(Event event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    bool serverSuccess = await _sendEventToServer(event);
    
    Navigator.pop(context);

    if (serverSuccess) {
      setState(() {
        _applyFilter();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Событие успешно добавлено'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      _fetchEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Событие не сохранено! (нет соединения с сервером или неправильный запрос)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _updateEvent(Event oldEvent, Event newEvent) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    await _sendEventToServerDel(oldEvent);
    bool serverSuccess = await _sendEventToServer(newEvent);
    
    Navigator.pop(context);

    if (serverSuccess) {
      setState(() {
        _applyFilter();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Событие успешно изменено'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      _fetchEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Событие не сохранено! (нет соединения с сервером или неправильный запрос)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteEvent(Event event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    bool serverSuccess = await _sendEventToServerDel(event);
    
    Navigator.pop(context);

    if (serverSuccess) {
      setState(() {
        _applyFilter();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Событие успешно удалено'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      _fetchEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Событие не удалено! (нет соединения с сервером или неправильный запрос)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_squad');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  String _buildApiUrl() {
    int year = _currentMonth.year - 2000;
    int month = _currentMonth.month;
    return 'http://${Globals.ip_conf}:6767/calendar/$year/$month';
  }

  List<Event> _parseEvents(List<dynamic> data) {
    List<Event> events = [];
    Set<String> squadsSet = {};
    
    for (var item in data) {
      if (item.containsKey('name')) {
        continue;
      }
      
      if (item.containsKey('card')) {
        var card = item['card'];
        try {
          List<String> dateParts = card['date'].split('.');
          if (dateParts.length == 3) {
            int day = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int year = 2000 + int.parse(dateParts[2]);
            
            Event event = Event(
              date: DateTime(year, month, day),
              text: card['text'],
              squad: card['squad'],
              time: card['time'],
              isLocal: false,
            );
            events.add(event);
            squadsSet.add(card['squad']);
          }
        } catch (e) {
          print('Ошибка парсинга события: $e');
        }
      }
    }
    
    setState(() {
      _availableSquads = squadsSet.toList()..sort();
    });
    
    return events;
  }

  void _applyFilter() {
    setState(() {
      List<Event> allEvents = [..._events, ..._localEvents];
      
      if (_selectedSquad == null || _selectedSquad == 'Все') {
        _filteredEvents = List.from(allEvents);
      } else {
        _filteredEvents = allEvents.where((event) => 
          event.squad == _selectedSquad
        ).toList();
      }
    });
  }

  void _clearFilter() {
    setState(() {
      _selectedSquad = null;
      _applyFilter();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Фильтр по бригадам',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.all_inclusive),
                title: Text('Все бригады'),
                trailing: _selectedSquad == null ? Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  setState(() {
                    _selectedSquad = null;
                    _applyFilter();
                  });
                  Navigator.pop(context);
                },
              ),
              Divider(),
              ..._availableSquads.map((squad) {
                return ListTile(
                  leading: Icon(Icons.group),
                  title: Text(squad),
                  trailing: _selectedSquad == squad ? Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    setState(() {
                      _selectedSquad = squad;
                      _applyFilter();
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              if (_selectedSquad != null) ...[
                Divider(),
                ListTile(
                  leading: Icon(Icons.clear, color: Colors.red),
                  title: Text('Сбросить фильтр', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _clearFilter();
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDayEventsDialog(DateTime date) {
    List<Event> dayEvents = _getEventsForDay(date);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatEventDate(date),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEventDialog(date: date);
                        },
                        tooltip: 'Добавить событие',
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Всего событий: ${dayEvents.length}',
                        style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: dayEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              'Нет событий на этот день',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEventDialog(date: date);
                              },
                              icon: Icon(Icons.add),
                              label: Text('Добавить событие'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) {
                          final event = dayEvents[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: event.squad == Globals.userSquad
                                    ? Colors.green.shade100 
                                    : Colors.blue.shade100,
                                child: Icon(
                                  event.squad == Globals.userSquad ? Icons.edit : Icons.event,
                                  color: event.squad == Globals.userSquad ? Colors.green : Colors.blue,
                                ),
                              ),
                              title: Text(
                                event.text,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(event.time),
                                      SizedBox(width: 12),
                                      Icon(Icons.group, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(
                                            event.squad.length > 20
                                                ? '${event.squad.substring(0, 20)}...' 
                                                : event.squad,),
                                    ],
                                  ),
                                  if (event.squad == Globals.userSquad) ...[
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Мое событие',
                                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: event.squad == Globals.userSquad
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 20),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _showEventDialog(event: event, date: date);
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: event.squad == Globals.userSquad
                                  ? () {
                                      Navigator.pop(context);
                                      _showEventDialog(event: event, date: date);
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEventDialog({Event? event, required DateTime date, String? defaultSquad}) {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.text ?? '');
    final squadController = TextEditingController(text: event?.squad ?? defaultSquad ?? widget.userSquad);
    final timeController = TextEditingController(text: event?.time ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      isEditing ? 'Редактировать событие' : 'Добавить событие',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatEventDate(date),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Текст события',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLines: 10,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: squadController,
                      decoration: InputDecoration(
                        labelText: 'Бригада',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Время',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Выберите вариант', style: TextStyle(fontSize: 16)),
                            titlePadding: const EdgeInsets.all(12),
                            contentPadding: EdgeInsets.zero,
                            children: [
                              TwoLineSelector(timeController: timeController),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.isNotEmpty &&
                                  squadController.text.isNotEmpty &&
                                  timeController.text.isNotEmpty) {
                                final newEvent = Event(
                                  date: date,
                                  text: titleController.text,
                                  squad: squadController.text,
                                  time: timeController.text,
                                  isLocal: true,
                                );
                                
                                if (isEditing) {
                                  await _updateEvent(event!, newEvent);
                                } else {
                                  await _addEvent(newEvent);
                                }
                                Navigator.pop(context);
                              }
                            },
                            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
                          ),
                        ),
                        if (isEditing) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _deleteEvent(event!);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: Text('Удалить'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12),
                    if (!isEditing)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Отмена'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEmptyCalendarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Информация'),
            ],
          ),
          content: Text(
            'Календарь на ${_formatMonthYear(_currentMonth)} не заполнен',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String apiUrl = _buildApiUrl();
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _events = _parseEvents(data);
          _applyFilter();
          _isLoading = false;
        });
      } 
      else if (response.statusCode == 404) {
        setState(() {
          _events = [];
          _availableSquads = [];
          _applyFilter();
          _isLoading = false;
          _errorMessage = null;
        });
        _showEmptyCalendarDialog();
      }
      else {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка соединения: $e';
        _isLoading = false;
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _filteredEvents.where((event) =>
        event.date.year == day.year &&
        event.date.month == day.month &&
        event.date.day == day.day).toList();
  }

  String _formatMonthYear(DateTime date) {
    List<String> months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatEventDate(DateTime date) {
    List<String> months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMonthYearPicker() {
    int selectedYear = _currentMonth.year;
    int selectedMonth = _currentMonth.month;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Выберите месяц и год'),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Год', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setStateDialog(() {
                                    if (selectedYear > 2000) selectedYear--;
                                  });
                                },
                              ),
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: Text(selectedYear.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setStateDialog(() {
                                    if (selectedYear < 2100) selectedYear++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2,
                      children: List.generate(12, (index) {
                        int month = index + 1;
                        List<String> monthNames = [
                          'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
                          'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
                        ];
                        bool isSelected = selectedYear == _currentMonth.year && month == _currentMonth.month;
                        
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(selectedYear, month, 1);
                              _fetchEvents();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                            foregroundColor: isSelected ? Colors.white : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(monthNames[index]),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Text('', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTableView() {
    Set<String> squads = {};
    for (var event in _filteredEvents) {
      squads.add(event.squad);
    }
    List<String> squadList = squads.toList()..sort();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTableHeader(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: _buildDataTable(squadList),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                _updateTableDatesFromCurrentMonth();
                _fetchEvents();
              });
            },
          ),
          GestureDetector(
            onTap: () {
              _showMonthYearPickerForTable();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMonthYear(_currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.today),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                    _updateTableDatesFromCurrentMonth();
                    _selectedDate = DateTime.now();
                    _fetchEvents();
                  });
                },
                tooltip: 'Сегодня',
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                    _updateTableDatesFromCurrentMonth();
                    _fetchEvents();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateTableDatesFromCurrentMonth() {
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    DateTime lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    _tableStartDate = firstDayOfMonth;
    _tableEndDate = lastDayOfMonth;
    
    _updateAvailableDates();
  }

  void _showMonthYearPickerForTable() {
    int selectedYear = _currentMonth.year;
    int selectedMonth = _currentMonth.month;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Выберите месяц и год'),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Год', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setStateDialog(() {
                                    if (selectedYear > 2000) {
                                      selectedYear--;
                                    }
                                  });
                                },
                                tooltip: 'Предыдущий год',
                              ),
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: Text(
                                  selectedYear.toString(),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setStateDialog(() {
                                    if (selectedYear < 2100) {
                                      selectedYear++;
                                    }
                                  });
                                },
                                tooltip: 'Следующий год',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2,
                      children: List.generate(12, (index) {
                        int month = index + 1;
                        List<String> monthNames = [
                          'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
                          'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
                        ];
                        bool isSelected = selectedYear == _currentMonth.year && 
                                          month == _currentMonth.month;
                        
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(selectedYear, month, 1);
                              _updateTableDatesFromCurrentMonth();
                              _fetchEvents();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                            foregroundColor: isSelected ? Colors.white : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(monthNames[index]),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Диапазон годов: 2000 - 2100',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );
  }
    // Функция для копирования
  void _copyToClipboard(BuildContext context, String phoneNumber, String displayNumber) {
    
    Clipboard.setData(ClipboardData(text: phoneNumber));
    // Показываем всплывающее сообщение
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Номер $displayNumber скопирован')),
    );
  }
    void _makePhoneCall(phoneNumber) async {
    // Формируем URI для звонка
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Ошибка звонка: $e");
    }
  }
  // Показываем меню выбора
  void _showOptions(BuildContext context, phoneNumber) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                            ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Позвонить'),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(phoneNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать номер'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, phoneNumber, phoneNumber);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  void _showEventDetailsDialog(Event event, DateTime date) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(event.squad == Globals.userSquad ? Icons.edit : Icons.event, 
                   color: event.squad == Globals.userSquad ? Colors.green : Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: SmartActionsText(
                  text: event.text,
                  
                  style: TextStyle(fontSize: 16, color: Colors.black),
                   parse: [
                MatchText(
                  type: ParsedType.phone,
                  style: TextStyle(color: Colors.blue),
                  onTap: (phoneNumber) {
                  _showOptions(context, phoneNumber);
                },
                )
              ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.calendar_today, _formatFullDate(date)),
              SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, event.time),
              SizedBox(height: 8),
              _buildInfoRow(Icons.group, event.squad),
              if (event.squad == Globals.userSquad) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Мое событие',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Закрыть'),
            ),
            if (event.squad == Globals.userSquad)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEventDialog(event: event, date: date);
                },
                child: Text('Редактировать'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          text.length > 32
                                                ? '${text.substring(0, 32)}...' 
                                                : text,
          style: TextStyle(fontSize: 14)),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildDataTable(List<String> squadList) {
    double lenSquad = 120;
    int lenText = 15;
    if (squadList.length == 1){
      lenSquad = 300;
      lenText = 45;
    }
    
    List<DataColumn> columns = [
      DataColumn(
        label: Container(
          width: 75,
          child: Text(
            'Дата/время',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    ];
    
    for (var squad in squadList) {
      columns.add(
        DataColumn(
          label: Container(
            width: lenSquad,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 16, color: Colors.blue),
                SizedBox(height: 4),
                Text(squad.length > 40 
                                                ? '${squad.substring(0, 40)}...' 
                                                : 'Бригада: $squad',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    List<DataRow> rows = [];
    
    for (DateTime currentDate = _tableStartDate;
         currentDate.isBefore(_tableEndDate.add(Duration(days: 1)));
         currentDate = currentDate.add(Duration(days: 1))) {
      
      String dateKey = '${currentDate.day.toString().padLeft(2, '0')}.${currentDate.month.toString().padLeft(2, '0')}.${(currentDate.year - 2000).toString().padLeft(2, '0')}';
      
      List<DataCell> cells = [
        DataCell(
          GestureDetector(
            onTap: () {
              _showDayEventsDialog(currentDate);
            },
            onLongPress: () {
              _showEventDialog(date: currentDate);
            },
            child: Container(
              transformAlignment: Alignment.center,
              width: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateKey,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  if (currentDate.weekday == 1)
                    Text(
                      'Понедельник',
                      style: TextStyle(fontSize: 10),
                    ),
                  if (currentDate.weekday == 2)
                    Text(
                      'Вторник',
                      style: TextStyle(fontSize: 10),
                    ),
                  if (currentDate.weekday == 3)
                    Text(
                      'Среда',
                      style: TextStyle(fontSize: 10),
                    ),
                  if (currentDate.weekday == 4)
                    Text(
                      'Четверг',
                      style: TextStyle(fontSize: 10),
                    ),
                  if (currentDate.weekday == 5)
                    Text(
                      'Пятница',
                      style: TextStyle(fontSize: 10),
                    ),
                  if (currentDate.weekday == 6)
                    Text(
                      'Суббота',
                      style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                    ),
                  if (currentDate.weekday == 7)
                    Text(
                      'Воскресенье',
                      style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                    ), 
                ],
              ),
            ),
          ),
        ),
      ];
      
      for (var squad in squadList) {
        List<Event> squadEvents = _filteredEvents.where((event) =>
          event.date.year == currentDate.year &&
          event.date.month == currentDate.month &&
          event.date.day == currentDate.day &&
          event.squad == squad
        ).toList();
        
        cells.add(
          DataCell(
            GestureDetector(
              onTap: () {
                if (squadEvents.isEmpty) {
                  _showEventDialog(date: currentDate, defaultSquad: squad);
                } else {
                  _showDayEventsForSquadDialog(currentDate, squad, squadEvents);
                }
              },
              onLongPress: () {
                _showEventDialog(date: currentDate, defaultSquad: squad);
              },
              child: Container(
                width: lenSquad,
                constraints: BoxConstraints(minHeight: 70),
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: squadEvents.isEmpty
                        ? [
                            Icon(Icons.add_circle_outline, size: 24, color: Colors.blue.shade300),
                            SizedBox(height: 4),
                            Text(
                              '',
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade400),
                            ),
                          ]
                        : squadEvents.map((event) {
                            return GestureDetector(
                              onTap: () => _showEventDetailsDialog(event, currentDate),
                              onLongPress: event.squad == Globals.userSquad
                                  ? () => _showEventDialog(event: event, date: currentDate)
                                  : null,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 4),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event.squad == Globals.userSquad ? Colors.green.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: event.squad == Globals.userSquad ? Colors.green.shade200 : Colors.blue.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      event.squad == Globals.userSquad? Icons.edit : Icons.event,
                                      size: 12,
                                      color: event.squad == Globals.userSquad ? Colors.green : Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            event.time,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          Text(
                                            event.text.length > lenText 
                                                ? '${event.text.substring(0, lenText)}...' 
                                                : event.text,
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      rows.add(DataRow(cells: cells));
    }
    
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.grey.shade200,
      ),
      child: DataTable(
        columnSpacing: 8,
        horizontalMargin: 3,
        headingRowHeight: 80,
        dataRowHeight: 100,
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
        columns: columns,
        rows: rows,
      ),
    );
  }

  void _showDayEventsForSquadDialog(DateTime date, String squad, List<Event> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatEventDate(date),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('Бригада: $squad'.length > 40 
                                                ? '${'Бригада: $squad'.substring(0, 40)}...' 
                                                : 'Бригада: $squad',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEventDialog(date: date, defaultSquad: squad);
                        },
                        tooltip: 'Добавить событие',
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Всего событий: ${events.length}',
                        style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              'Нет событий на этот день',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEventDialog(date: date, defaultSquad: squad);
                              },
                              icon: Icon(Icons.add),
                              label: Text('Добавить событие'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: event.squad == Globals.userSquad
                                    ? Colors.green.shade100 
                                    : Colors.blue.shade100,
                                child: Icon(
                                  event.squad == Globals.userSquad ? Icons.edit : Icons.event,
                                  color: event.squad == Globals.userSquad ? Colors.green : Colors.blue,
                                ),
                              ),
                              title: Text(
                                event.text,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(event.time),
                                    ],
                                  ),
                                  if (event.squad == Globals.userSquad) ...[
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Мое событие',
                                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: event.squad == Globals.userSquad
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 20),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _showEventDialog(event: event, date: date);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20, color: Colors.green),
                                          onPressed: () {
                                            _deleteEvent(event);
                                            Navigator.pop(context);
                                            _showDayEventsForSquadDialog(date, squad, 
                                              _filteredEvents.where((e) =>
                                                e.date.year == date.year &&
                                                e.date.month == date.month &&
                                                e.date.day == date.day &&
                                                e.squad == squad
                                              ).toList()
                                            );
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: event.squad == Globals.userSquad
                                  ? () {
                                      Navigator.pop(context);
                                      _showEventDialog(event: event, date: date);
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                    _fetchEvents();
                  });
                },
              ),
              GestureDetector(
                onTap: _showMonthYearPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 2),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMonthYear(_currentMonth),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.today),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                        _selectedDate = DateTime.now();
                        _fetchEvents();
                      });
                    },
                    tooltip: 'Сегодня',
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                        _fetchEvents();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {

    
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    int firstWeekday = firstDayOfMonth.weekday;
    
    int offset = firstWeekday - 1;
    
    List<Widget> calendarRows = [];
    List<DateTime> daysInMonthList = [];

    for (int i = 0; i < offset; i++) {
      daysInMonthList.add(DateTime(_currentMonth.year, _currentMonth.month, 0 - (offset - i - 1)));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      daysInMonthList.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    for (int i = 0; i < daysInMonthList.length; i += 7) {
      List<Widget> weekRow = [];
      for (int j = i; j < i + 7 && j < daysInMonthList.length; j++) {
        DateTime day = daysInMonthList[j];
        List<Event> dayEvents = _getEventsForDay(day);
        
        weekRow.add(
          Container(
            width: MediaQuery.of(context).size.width / 7.29,
            child: _buildDayCell(day, dayEvents),
          ),
        );
      }
      calendarRows.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: weekRow),
        ),
      );
    }

    return ListView(children: [_buildWeekDaysHeader(), ...calendarRows]);
  }

  Widget _buildWeekDaysHeader() {
    List<String> weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: weekDays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: day == 'СБ' || day == 'ВС' ? Colors.red.shade400 : Colors.grey.shade700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, List<Event> events) {
    bool isCurrentMonth = date.month == _currentMonth.month;
    bool isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    bool isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        _showDayEventsDialog(date);
      },
      onLongPress: () => _showEventDialog(date: date),
      child: Container(
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade200 : isToday ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: events.isNotEmpty ? Colors.blue.shade300 : Colors.grey.shade200,
            width: events.isNotEmpty ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentMonth ? Colors.black : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            if (events.isNotEmpty) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text('${events.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              ),
            ] else ...[
              SizedBox(height: 25),
            ],
          ],
        ),
      ),
    );
  }
void _show_alert(context){

  ScaffoldMessenger.of(context).showSnackBar(Asd(context)); 
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

SnackBar Asd(context){
  return SnackBar(
  content: Row(
    children: const [
      SizedBox(width: 12),
      Expanded(
        child: Text(
          'Добавлена новая заявка в график!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  ),
  backgroundColor: Colors.green[700],
  behavior: SnackBarBehavior.floating,
  margin: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: MediaQuery.of(context).size.height - 90), // Отступ только сверху
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  duration: const Duration(seconds: 3),
);}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text('График'),
        centerTitle: true,
        elevation: 2,
           leading: IconButton(  // Добавьте эту секцию
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          _showModuleSelectionDialog();
        },
        tooltip: 'Вернуться в меню',
      ),
        actions: [
          PopupMenuButton<CalendarViewType>(
            icon: Icon(Icons.view_agenda),
            tooltip: 'Выбрать вид календаря',
            onSelected: (value) {
              setState(() {
                _currentViewType = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarViewType.monthGrid,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Месячная сетка'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarViewType.table,
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Табличный вид (бригады)'),
                  ],
                ),
              ),
            ],
          ),
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
            icon: Stack(
              children: [
                Icon(Icons.filter_list),
                if (_selectedSquad != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтр по бригадам',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {_fetchEvents();}
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchEvents, child: Text('Повторить')),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedSquad != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text('Фильтр: бригада "$_selectedSquad"'.length > 40 
                                                ? '${'Фильтр: бригада "$_selectedSquad"'.substring(0, 40)}...' 
                                                : 'Фильтр: бригада "$_selectedSquad"',
                                                 style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                Spacer(),
                GestureDetector(
                  onTap: _clearFilter,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14),
                        SizedBox(width: 4),
                        Text('Сбросить', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _currentViewType == CalendarViewType.monthGrid
              ? _buildMonthGridView()
              : _buildTableView(),
        ),
      ],
    );
  }

  Widget _buildMonthGridView() {
    return Column(
      children: [
        _buildCalendarHeader(),
        Expanded(child: _buildCalendar()),
      ],
    );
  }
}