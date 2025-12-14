import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/app_colors.dart';
import '../logic/user_session.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<void> init() async {
    // 1. Initial Load of Unread Count from Storage
    await _updateUnreadCount();

    if (_initialized) return;

    // Initialize Timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle local notification tap if needed
      },
    );

    // Initialize OneSignal
    String? oneSignalAppId = dotenv.env['APP_ONESIGNAL_APP_ID'];
    if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) {
      OneSignal.initialize(oneSignalAppId);

      // Listener 1: Foreground
      // Fires when app is open and notification arrives
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        _saveOneSignalNotification(event.notification);
        // event.notification.display(); // Default is to display
      });

      // Listener 2: Click (Opened via Notification)
      // This effectively captures the "last received" notification that the user interacted with
      OneSignal.Notifications.addClickListener((event) {
        _saveOneSignalNotification(event.notification);
      });
    }

    _initialized = true;
  }

  // --- Permission Flow ---

  Future<void> checkPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool? asked = prefs.getBool('notification_permission_asked');

    bool enabled = await _isSystemPermissionGranted();
    if (enabled) {
      scheduleDailyNotifications();
      return;
    }

    if (asked == true) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0E1016),
          title: const Text("Stay Connected", style: TextStyle(color: AppColors.primaryGold)),
          content: const Text(
            "Notifications are important to receive your daily horoscope, important astrological alerts, and guidance related to your account.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await prefs.setBool('notification_permission_asked', true);
              },
              child: const Text("Not Now", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(ctx);
                await prefs.setBool('notification_permission_asked', true);
                _requestSystemPermission();
              },
              child: const Text("Yes, Enable"),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _isSystemPermissionGranted() async {
    return OneSignal.Notifications.permission;
  }

  Future<void> _requestSystemPermission() async {
    await OneSignal.Notifications.requestPermission(true);
    if (await _isSystemPermissionGranted()) {
      scheduleDailyNotifications();
    }
  }

  // --- Scheduling Logic ---

  Future<void> scheduleDailyNotifications({
    String? dailyTitle,
    String? dailyBody,
    String? eveningTitle,
    String? eveningBody,
  }) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    bool guestMode = prefs.getBool('guest_mode') ?? false;

    final String dTitle = dailyTitle ?? "🌞 Aaj ka rashifal ready hai";
    final String dBody = dailyBody ?? "Jaaniye aaj ka shubh samay aur din ka haal.";

    await _scheduleDaily(
      id: 101,
      title: dTitle,
      body: dBody,
      hour: 7,
      minute: 30,
    );

    if (guestMode) return;

    final String eTitle = eveningTitle ?? "✨ Aaj ki shaam ka vishesh sandesh";
    final String eBody = eveningBody ?? "Aapke rishton aur bhavnao ke liye kya kehte hain sitare?";

    List<int> eveningDays = [DateTime.monday, DateTime.wednesday, DateTime.friday, DateTime.saturday];
    for (int day in eveningDays) {
      await _scheduleWeekly(
        id: 200 + day,
        title: eTitle,
        body: eBody,
        day: day,
        hour: 20,
        minute: 30,
      );
    }
  }

  Future<void> scheduleDynamicNotifications(List<String> messages) async {
    await flutterLocalNotificationsPlugin.cancel(101);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < messages.length; i++) {
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 30)
          .add(Duration(days: i + 1));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1000 + i,
        "✨ AstroPrerna Insight",
        messages[i],
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel',
            'Daily Horoscope',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _scheduleDaily({required int id, required String title, required String body, required int hour, required int minute}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Horoscope',
          channelDescription: 'Daily updates for your zodiac',
          importance: Importance.max,
          priority: Priority.high,
          color: AppColors.primaryGold,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({required int id, required String title, required String body, required int day, required int hour, required int minute}) async {
     await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayTime(day, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_channel',
          'Evening Guidance',
          channelDescription: 'Evening astrological insights',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: AppColors.primaryPurple,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayTime(int day, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- Triggered Notifications ---

  Future<void> triggerNotification({required String title, required String body, required int idOffset}) async {
    final prefs = await SharedPreferences.getInstance();
    bool guestMode = prefs.getBool('guest_mode') ?? false;
    if (guestMode) return;

    String today = DateTime.now().toIso8601String().split('T')[0];
    String lastTrigger = prefs.getString('last_triggered_notif_date') ?? "";
    if (lastTrigger == today) return;

    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      300 + idOffset,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trigger_channel',
          'Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    await prefs.setString('last_triggered_notif_date', today);
    await _saveNotificationToStorage(title, body, "Local", false);
  }

  Future<void> onKundliGenerated() async {
     await triggerNotification(
       title: "🔔 Kundli Insight",
       body: "Aaj aapki Kundli ka ek important yog active hai.",
       idOffset: 1
     );
  }

  Future<void> onLoveMatchGenerated() async {
     await triggerNotification(
       title: "❤️ Love Match Update",
       body: "Aaj relationship ke liye shubh prabhav ban raha hai.",
       idOffset: 2
     );
  }

  // --- Storage Logic ---

  Future<void> _saveOneSignalNotification(OSNotification notification) async {
    // Check duplication (simple check by ID or Title+Body)
    String title = notification.title ?? "New Notification";
    String body = notification.body ?? "";

    // Prevent duplicates if click listener fires after foreground listener
    List<Map<String, dynamic>> existing = await getNotifications();
    bool exists = existing.any((n) => n['title'] == title && n['body'] == body && n['timestamp'] != null && DateTime.now().difference(DateTime.parse(n['timestamp'])).inMinutes < 1);

    if (!exists) {
      await _saveNotificationToStorage(
        title,
        body,
        "OneSignal",
        true // Important
      );
    }
  }

  Future<void> _saveNotificationToStorage(String title, String body, String source, bool isImportant) async {
    List<Map<String, dynamic>> notifications = await getNotifications();

    notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      'source': source,
      'importance': isImportant ? 'high' : 'normal',
    });

    // Limit storage to last 50
    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }

    String jsonStr = jsonEncode(notifications);
    await UserSession.setString('notifications_list', jsonStr);

    await _updateUnreadCount();
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    String? jsonStr = await UserSession.getString('notifications_list');
    if (jsonStr == null) return [];
    try {
      List<dynamic> list = jsonDecode(jsonStr);
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAllAsRead() async {
    List<Map<String, dynamic>> notifications = await getNotifications();
    bool changed = false;
    for (var n in notifications) {
      if (n['read'] == false) {
        n['read'] = true;
        changed = true;
      }
    }

    if (changed) {
      String jsonStr = jsonEncode(notifications);
      await UserSession.setString('notifications_list', jsonStr);
      await _updateUnreadCount();
    }
  }

  Future<void> _updateUnreadCount() async {
    List<Map<String, dynamic>> notifications = await getNotifications();
    int count = notifications.where((n) => n['read'] == false).length;

    // Force UI update
    unreadCount.value = count;
  }
}
