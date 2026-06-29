import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final StreamController<String> notificationStream = StreamController<String>.broadcast();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) notificationStream.add(response.payload!);
      },
    );
  }

  static Future<void> showTimerNotification({required int secondsRemaining, required int totalSeconds, required bool isRunning, required String currentTag}) async {
    int m = secondsRemaining ~/ 60;
    int s = secondsRemaining % 60;
    String timeString = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_live_channel', 'Live Timer', channelDescription: 'Shows timer status',
      importance: Importance.low, priority: Priority.low, ongoing: true, onlyAlertOnce: true,
      showProgress: true, maxProgress: totalSeconds, progress: totalSeconds - secondsRemaining,
      actions: [
        isRunning ? const AndroidNotificationAction('pause_timer', 'PAUSE', showsUserInterface: false) : const AndroidNotificationAction('resume_timer', 'RESUME', showsUserInterface: false),
        const AndroidNotificationAction('stop_timer', 'STOP', showsUserInterface: false),
      ],
    );
    await _notifications.show(1, isRunning ? '$currentTag Mode 🍅' : '$currentTag (Paused) ☕', 'Time Left: $timeString', NotificationDetails(android: androidDetails));
  }

  static Future<void> showCompleteNotification(int duration, String tag) async {
    await cancelTimerNotification();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('pomodoro_alert_channel', 'Timer Alert', importance: Importance.max, priority: Priority.high, playSound: false, enableVibration: true);
    await _notifications.show(2, "Great Job! ($tag) 🏆", "$duration minute session completed.", const NotificationDetails(android: androidDetails));
  }

  static Future<void> cancelTimerNotification() async {
    await _notifications.cancel(1);
  }
}