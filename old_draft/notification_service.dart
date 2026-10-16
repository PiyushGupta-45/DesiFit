import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (!_supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      }
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
          const InitializationSettings(android: android, iOS: ios));
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  static Future<bool> requestPermission() async {
    if (!_supported || !_ready) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await impl?.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'desi_fit_reminders',
      'Log reminders',
      channelDescription: 'Daily reminders to log your meals and workouts',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static String _body(Reminder r) => r.type == 'diet'
      ? 'Time to log what you ate. Keep your calorie and protein targets on track!'
      : 'Log your workout, or mark today as a rest day.';

  static Future<void> schedule(Reminder r) async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancel(r.id);
      if (!r.enabled) return;
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, r.hour, r.minute);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        r.id,
        r.label,
        _body(r),
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule failed: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> syncAll(List<Reminder> list) async {
    for (final r in list) {
      await schedule(r);
    }
  }

  static Future<void> showTest() async {
    if (!_supported || !_ready) return;
    try {
      await _plugin.show(0, 'DesiFit', 'Reminders are working 🎉', _details);
    } catch (_) {}
  }
}
