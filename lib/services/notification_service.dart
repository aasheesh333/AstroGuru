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
    _updateUnreadCount();
    if (_initialized) return;

    // Initialize Timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Note: iOS settings omitted as per context (focus on Android/General logic)
    // but good practice to include empty iOS settings if needed later.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        // In a real app, navigate to specific screen
      },
    );

    // Initialize OneSignal
    String? oneSignalAppId = dotenv.env['APP_ONESIGNAL_APP_ID'];
    if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) {
      OneSignal.initialize(oneSignalAppId);

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        // Save notification to local storage when received in foreground
        // event.notification.display(); // Depending on requirement, might suppress
        _saveOneSignalNotification(event.notification);
      });

      OneSignal.Notifications.addClickListener((event) {
         // Handle OneSignal tap
      });
    }

    _initialized = true;

    // Schedule recurring notifications if permissions granted
    // We check permission status first to avoid errors
    // scheduleDailyNotifications(); // Called separately or after checks
  }

  // --- Permission Flow ---

  Future<void> checkPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool? asked = prefs.getBool('notification_permission_asked');

    // If we haven't asked politely yet, do so.
    // Or if we asked but they said "Not Now" (we might want to ask again after some time,
    // but for now let's strict to "asked" flag or just check system status).
    // The requirement says: "dismiss and ask again later (not repeatedly)".

    // Check actual system permission
    bool enabled = await _isSystemPermissionGranted();
    if (enabled) {
      // Already enabled, ensure scheduling is active
      scheduleDailyNotifications();
      return;
    }

    if (asked == true) {
      // Already asked politely. Maybe check if enough time passed?
      // For now, let's respect the user's decision or reliance on system settings.
      return;
    }

    // Show Polite Popup
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
                // "Not Now" behavior
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
    // Check OneSignal or Local status
    // Local:
    final platform = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (platform != null) {
       // Android 13+ needs explicit check, simpler to just rely on request return or OneSignal
    }
    return OneSignal.Notifications.permission;
  }

  Future<void> _requestSystemPermission() async {
    // Use OneSignal to request permission as it handles both
    await OneSignal.Notifications.requestPermission(true);
    // After request, schedule if granted
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
    // Clear existing to avoid duplicates
    await flutterLocalNotificationsPlugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    bool guestMode = prefs.getBool('guest_mode') ?? false;

    // Defaults if not provided (fallback or initial run before l10n)
    final String dTitle = dailyTitle ?? "🌞 Aaj ka rashifal ready hai";
    final String dBody = dailyBody ?? "Jaaniye aaj ka shubh samay aur din ka haal.";

    // 1. Daily Morning Horoscope (Every Day, 6:30 - 8:30 AM)
    // We'll pick 7:30 AM fixed
    await _scheduleDaily(
      id: 101,
      title: dTitle,
      body: dBody,
      hour: 7,
      minute: 30,
    );

    if (guestMode) return; // Guests only get Morning

    // Defaults for evening
    final String eTitle = eveningTitle ?? "✨ Aaj ki shaam ka vishesh sandesh";
    final String eBody = eveningBody ?? "Aapke rishton aur bhavnao ke liye kya kehte hain sitare?";

    // 2. Evening Engagement (Limited: 3-4 times/week, 7:30 - 10:00 PM)
    // We'll pick Mon, Wed, Fri, Sat at 8:30 PM
    List<int> eveningDays = [DateTime.monday, DateTime.wednesday, DateTime.friday, DateTime.saturday];
    for (int day in eveningDays) {
      await _scheduleWeekly(
        id: 200 + day, // Unique ID per day
        title: eTitle,
        body: eBody,
        day: day,
        hour: 20, // 8 PM
        minute: 30,
      );
    }

    // Festival/User-triggered are event based, not recurring schedules here
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

    // Cap check: Max 1 user-triggered per day
    String today = DateTime.now().toIso8601String().split('T')[0];
    String lastTrigger = prefs.getString('last_triggered_notif_date') ?? "";
    if (lastTrigger == today) {
      // Already triggered one today
      return;
    }

    // Schedule for 2 hours later
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      300 + idOffset, // dynamic ID
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
    await _saveNotificationToStorage(
      notification.title ?? "New Notification",
      notification.body ?? "",
      "OneSignal",
      true
    );
  }

  Future<void> _saveNotificationToStorage(String title, String body, String source, bool isImportant) async {
    // Loading existing
    List<Map<String, dynamic>> notifications = await getNotifications();

    // Add new
    notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false, // Unread by default
      'source': source,
      'importance': isImportant ? 'high' : 'normal',
    });

    // Save
    String jsonStr = jsonEncode(notifications);
    await UserSession.setString('notifications_list', jsonStr);

    _updateUnreadCount();
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
    for (var n in notifications) {
      n['read'] = true;
    }
    String jsonStr = jsonEncode(notifications);
    await UserSession.setString('notifications_list', jsonStr);
    _updateUnreadCount();
  }

  Future<void> _updateUnreadCount() async {
    List<Map<String, dynamic>> notifications = await getNotifications();
    unreadCount.value = notifications.where((n) => n['read'] == false).length;
  }
}
