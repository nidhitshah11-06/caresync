import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
    );
  }

  static Future<void> scheduleReminder({
    required int id,
    required String medicineName,
    required String timing,
    required int hour,
    required int minute,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Reminders to take your medicines',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id,
      '💊 Medicine Reminder',
      'Time to take $medicineName - $timing',
      details,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
}