// services/background_notification_service.dart
import 'package:calendar_app/models/globals.dart';
import 'package:flutter_websocket_manager_plugin/flutter_websocket_manager_plugin.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:async';
import 'dart:isolate';

class BackgroundNotificationService {
  static late final WebsocketManager _wsManager;
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'background_websocket_channel';
  static const String _channelName = 'Фоновые уведомления';
  
  static Timer? _reconnectTimer;
  static bool _isReconnecting = false;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      print("ℹ️ Сервис уже инициализирован");
      return;
    }
    
    // 1. Настройка каналов уведомлений
    await _setupNotificationChannels();
    
    // 2. Запуск foreground сервиса (асинхронно, не блокируя UI)
    unawaited(_startForegroundService());
    
    // 3. Инициализация WebSocket в фоне
    // Используем Future.microtask чтобы не блокировать текущий кадр
    Future.microtask(() => _initWebSocket());
    
    _isInitialized = true;
  }

  static Future<void> _setupNotificationChannels() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings: initSettings);
    
    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Уведомления о новых событиях в графике',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      
      await androidImpl.createNotificationChannel(channel);
      print("✅ Канал уведомлений создан: $_channelId");
    }
  }

  static Future<void> _initWebSocket() async {
    // Небольшая задержка чтобы не конфликтовать с инициализацией UI
    await Future.delayed(const Duration(milliseconds: 500));
    
    String wsUrl = 'ws://${Globals.ip_conf}:6767/ws/${Globals.userName ?? "12"}';
    _wsManager = WebsocketManager(wsUrl);
    
    print("🔌 WebSocket инициализирован: $wsUrl");

    _wsManager.onMessage((dynamic message) async {
      print("📨 Фоновое сообщение: $message");
      if (message.toString().contains(Globals.userSquad ?? "12")) {
        await _showLocalNotification(message.toString());
        
        // Обновляем уведомление foreground сервиса (не блокируем)
        unawaited(FlutterForegroundTask.updateService(
          notificationTitle: "Мониторинг графика",
          notificationText: "Последнее сообщение: ${DateTime.now().toString().substring(11, 19)}",
        ));
      }
    });

    _wsManager.onClose((_) {
      print("🔌 WebSocket закрыт, планируем переподключение через 60 секунд...");
      _scheduleReconnect();
    });
    
    _wsManager.onError((error) {
      print("❌ WebSocket ошибка: $error");
      _scheduleReconnect();
    });

    // Запускаем соединение
    _wsManager.connect();
  }

  static void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    if (_isReconnecting) return;
    
    _isReconnecting = true;
    print("⏰ Запланировано переподключение через 60 секунд");
    
    _reconnectTimer = Timer(const Duration(seconds: 180), () async {
      _isReconnecting = false;
      print("🔄 Выполняется переподключение WebSocket...");
      
      try {
        await _wsManager.close();
        await _initWebSocket();
        print("✅ WebSocket успешно переподключен");
      } catch (e) {
        print("❌ Ошибка при переподключении: $e");
        _scheduleReconnect();
      }
    });
  }

  static Future<void> _startForegroundService() async {
    // Проверяем в фоне
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (await FlutterForegroundTask.isRunningService) {
      print("ℹ️ Foreground сервис уже запущен");
      return;
    }
    
    final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    
     FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: 'Поддержание WebSocket соединения для получения уведомлений о сменах',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
    

  }
  
  @pragma('vm:entry-point')
  static void _startForegroundTask() {
    FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
  }

  static Future<void> _showLocalNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Уведомления о новых событиях в графике',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    
    try {
      await _notifications.show(
        id: notificationId,
        title: 'Новое событие в графике',
        body: message,
        notificationDetails: details,
      );
      print("✅ Уведомление показано, ID: $notificationId");
    } catch (e) {
      print("❌ Ошибка при показе уведомления: $e");
    }
  }
  
  static void dispose() {
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _isInitialized = false;
    _wsManager.close();
    FlutterForegroundTask.stopService();
  }
}

class ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("🚀 Foreground задача запущена");
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Легкая периодическая проверка - не блокируем
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print("🛑 Foreground задача остановлена");
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("🔘 Нажата кнопка уведомления: $id");
  }
}