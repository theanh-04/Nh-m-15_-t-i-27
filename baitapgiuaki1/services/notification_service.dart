import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      await requestPermissions();
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    try {
      await Permission.notification.request();
      
      if (!kIsWeb) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      }
    } catch (e) {
      // Ignore errors on web
    }
  }

  // TEST: Gửi thông báo ngay lập tức để kiểm tra
  static Future<void> showTestNotification() async {
    if (kIsWeb) return;
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test',
        channelDescription: 'Kênh test thông báo',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(
        999,
        '🧪 Test Thông báo',
        'Nếu bạn thấy thông báo này, tức là thông báo đang hoạt động!',
        details,
      );
    } catch (e) {
      // Ignore test errors
    }
  }

  static Future<void> scheduleReminder(Task task) async {
    if (kIsWeb) return;
    if (!task.enableReminder) return;

    final now = DateTime.now();
    final reminderTime = task.dateTime.subtract(const Duration(minutes: 15));
    
    if (reminderTime.isBefore(now)) return;

    try {
      switch (task.reminderType) {
        case 'notification':
          await _scheduleNotification(task, reminderTime);
          break;
        case 'alarm':
          await _scheduleAlarm(task, reminderTime);
          break;
        case 'email':
          // Email reminder would require backend integration
          break;
      }
    } catch (e) {
      // Ignore scheduling errors
    }
  }

  static Future<void> _scheduleNotification(Task task, DateTime scheduledTime) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminder',
      'Nhắc việc',
      channelDescription: 'Thông báo nhắc việc',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      task.id.hashCode,
      'Nhắc việc: ${task.name}',
      'Thời gian: ${task.dateTime.hour}:${task.dateTime.minute.toString().padLeft(2, '0')} - Địa điểm: ${task.location}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> _scheduleAlarm(Task task, DateTime scheduledTime) async {
    const androidDetails = AndroidNotificationDetails(
      'task_alarm',
      'Chuông báo',
      channelDescription: 'Chuông báo nhắc việc',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm.aiff',
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      task.id.hashCode,
      '⏰ NHẮC VIỆC: ${task.name}',
      'Thời gian: ${task.dateTime.hour}:${task.dateTime.minute.toString().padLeft(2, '0')} - Địa điểm: ${task.location}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(String taskId) async {
    if (kIsWeb) return;
    await _notifications.cancel(taskId.hashCode);
  }

  static Future<void> sendEmailReminder(Task task) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: '',
      query: 'subject=Nhắc việc: ${task.name}&body=Thời gian: ${task.dateTime}\nĐịa điểm: ${task.location}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
