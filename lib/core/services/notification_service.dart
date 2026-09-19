import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _reminderChannelId = 'ecowell_reminders';
  static const _reminderChannelName = 'EcoWell Reminders';
  static const _dailyReminderId = 1001;
  static const _followUpReminderId = 1002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: 'Visit reminders and wellness nudges',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showNow({
    required String title,
    required String body,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _plugin.show(id: id, title: title, body: body, notificationDetails: _details);
  }

  Future<void> scheduleDailyReminder({
    int hour = 17,
    int minute = 0,
  }) async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Time for nature',
      body: 'Take a short break and visit a nearby green space to recharge.',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleFollowUp(Duration after) async {
    final scheduled = DateTime.now().add(after);
    await _plugin.zonedSchedule(
      id: _followUpReminderId,
      title: 'How was your nature visit?',
      body: 'A short visit to a green space helps reduce stress. Reflect on how you feel today.',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancel(id: _dailyReminderId);
    await _plugin.cancel(id: _followUpReminderId);
  }
}