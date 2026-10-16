import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Schedules repeating local reminders for diet logs and workout logs.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get supported => !kIsWeb;

  Future<void> init() async {
    if (!supported || _ready) return;
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
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return (granted ?? iosGranted ?? true);
  }

  NotificationDetails _details(bool diet) => NotificationDetails(
        android: AndroidNotificationDetails(
          diet ? 'diet_logs' : 'workout_logs',
          diet ? 'Diet log reminders' : 'Workout log reminders',
          channelDescription: diet
              ? 'Reminders to log what you ate'
              : 'Reminders to log your workout',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> cancel(Reminder r) async {
    if (!_ready) return;
    for (var d = 0; d <= 7; d++) {
      await _plugin.cancel(r.id * 10 + d);
    }
  }

  Future<void> schedule(Reminder r) async {
    if (!supported) return;
    await init();
    await cancel(r);
    if (!r.enabled || r.days.isEmpty) return;

    final title = r.diet ? 'Time to log your meal 🍛' : 'Log your workout 💪';
    final body = r.label;

    if (r.days.length == 7) {
      await _plugin.zonedSchedule(
        r.id * 10,
        title,
        body,
        _next(r.hour, r.minute, null),
        _details(r.diet),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }
    for (final day in r.days) {
      await _plugin.zonedSchedule(
        r.id * 10 + day,
        title,
        body,
        _next(r.hour, r.minute, day),
        _details(r.diet),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Next occurrence of hh:mm, optionally on a given weekday (1 = Mon).
  tz.TZDateTime _next(int hour, int minute, int? weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (t.isBefore(now) || (weekday != null && t.weekday != weekday)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  Future<void> rescheduleAll(List<Reminder> all) async {
    for (final r in all) {
      await schedule(r);
    }
  }

  Future<void> showTest() async {
    if (!supported) return;
    await init();
    await _plugin.show(
      999999999,
      'DesiFit reminders are on ✨',
      'You\'ll get a nudge at your chosen times.',
      _details(true),
    );
  }
}
