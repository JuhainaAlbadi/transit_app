import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static int _notificationId = 0;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'transit_delays',
        'Transit Delays',
        importance: Importance.max,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showDelayNotification({
    required String station,
    required String destination,
    required int delayMinutes,
  }) async {
    try {
      debugPrint('>>> Sending notification: $station - $destination - $delayMinutes min');
      await _plugin.show(
        _notificationId++,
        '🚌 Delay at $station',
        '$destination delayed by $delayMinutes min',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'transit_delays',
            'Transit Delays',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
      );
      debugPrint('>>> Notification sent successfully');
    } catch (e) {
      debugPrint('>>> Notification error: $e');
    }
  }
}
