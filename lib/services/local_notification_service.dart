import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._internal();

  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  static const int _dailyReminderNotificationId = 2001;
  static const String _dailyReminderChannelId = 'daily_reminder';
  static const String _dailyReminderChannelName = 'Daily reminders';
  static const String _dailyReminderChannelDescription =
      'Daily reminder notifications for app engagement';
  static const TimeOfDay defaultReminderTime = TimeOfDay(hour: 20, minute: 0);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezoneInitialized = false;
  String _languageCode = 'es';

  Future<void> initialize({String? languageCode}) async {
    if (languageCode != null && languageCode.isNotEmpty) {
      _languageCode = languageCode;
    }

    await _initializeTimezone();

    if (_initialized) {
      await _requestPermissions();
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        description: _dailyReminderChannelDescription,
        importance: Importance.high,
      ),
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> scheduleDailyReminder({
    TimeOfDay time = defaultReminderTime,
    bool skipToday = false,
    String? languageCode,
  }) async {
    await initialize(languageCode: languageCode);
    await cancelDailyReminder();

    final content = _buildDailyReminderContent();
    await _plugin.zonedSchedule(
      _dailyReminderNotificationId,
      content.title,
      content.body,
      _nextInstance(time, skipToday: skipToday),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderNotificationId);
  }

  Future<void> showImmediateNotification({
    String? title,
    String? body,
    String? languageCode,
  }) async {
    await initialize(languageCode: languageCode);

    final content = title != null || body != null
        ? _NotificationContent(
            title: title ?? _defaultReminderTitle(),
            body: body ?? _defaultReminderBody(),
          )
        : _buildDailyReminderContent();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      content.title,
      content.body,
      _notificationDetails(),
      payload: 'foreground_notification',
    );
  }

  Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;

    tz_data.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo));
    } catch (e) {
      debugPrint('Error al inicializar la zona horaria local: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _timezoneInitialized = true;
  }

  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error al solicitar permisos de notificación local: $e');
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        channelDescription: _dailyReminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstance(TimeOfDay time, {bool skipToday = false}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (skipToday || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  _NotificationContent _buildDailyReminderContent() {
    return _NotificationContent(
      title: _defaultReminderTitle(),
      body: _defaultReminderBody(),
    );
  }

  String _defaultReminderTitle() {
    if (_languageCode == 'en') {
      return 'Daily 5-minute reminder';
    }
    return 'Recordatorio diario de 5 minutos';
  }

  String _defaultReminderBody() {
    if (_languageCode == 'en') {
      return 'You still need 5 minutes in Bolómetro today.';
    }
    return 'Todavía te faltan 5 minutos en Bolómetro hoy.';
  }
}

class _NotificationContent {
  const _NotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
