import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../logic/user_session.dart';
import '../logic/hindu_festivals.dart';
import '../logic/interest_tracker.dart';
import 'ai_service.dart';

/// Bundles the localized strings that [NotificationService] needs to schedule
/// static notifications (daily horoscope, evening reflection, re-engagement,
/// and festival greetings). The caller builds this from `AppLocalizations`
/// so the service itself stays free of any `BuildContext` dependency.
class LocalizedNotificationStrings {
  final String dailyTitle;
  final String dailyBody;
  final String eveningTitle;
  final String eveningBody;
  final String reengageTitle;
  final String reengageBody;
  final String reengage2Title;
  final String reengage2Body;
  final String Function(String festival) festivalTitleFor;
  final String Function(String festival) festivalBodyFor;

  const LocalizedNotificationStrings({
    required this.dailyTitle,
    required this.dailyBody,
    required this.eveningTitle,
    required this.eveningBody,
    required this.reengageTitle,
    required this.reengageBody,
    required this.reengage2Title,
    required this.reengage2Body,
    required this.festivalTitleFor,
    required this.festivalBodyFor,
  });
}

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _kLastDynamicSchedule = 'last_notification_schedule_time';
  static const int _dynamicScheduleThrottleMs = 3 * 24 * 60 * 60 * 1000;

  bool _initialized = false;
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<void> init() async {
    await _updateUnreadCount();

    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);

    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
        }
      },
    );

    final String oneSignalAppId = AppConfig.oneSignalAppId;
    if (oneSignalAppId.isNotEmpty) {
      OneSignal.initialize(oneSignalAppId);

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        _saveOneSignalNotification(event.notification);
      });

      OneSignal.Notifications.addClickListener((event) {
        _saveOneSignalNotification(event.notification);
      });
    }

    await _syncActiveNotifications();

    _initialized = true;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncActiveNotifications();
    }
  }

  Future<void> _syncActiveNotifications() async {
    try {
      final List<ActiveNotification> activeNotifications =
          await flutterLocalNotificationsPlugin.getActiveNotifications();

      for (var active in activeNotifications) {
        String? title = active.title;
        String? body = active.body;
        String? payload = active.payload;

        if (title != null && body != null) {
           await _saveNotificationToStorage(
             title,
             body,
             "Sync",
             true,
             scheduledTime: DateTime.now(),
             launchUrl: payload,
           );
        }
      }
    } catch (e) {
    }
  }

  // --- Permission API ---

  Future<bool> hasPermission() async {
    try {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.areNotificationsEnabled();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  // --- Bootstrap (called from main.dart before runApp) ---

  Future<void> bootstrapStatic({
    String language = 'en',
    LocalizedNotificationStrings? localized,
  }) async {
    if (!await hasPermission()) return;
    await scheduleDailyNotifications(localized: localized);
    await _scheduleFestivals(language: language, localized: localized);
    await _scheduleReengagementNotifications(localized: localized);
  }

  Future<void> bootstrapDynamic({String? zodiac, String language = 'en'}) async {
    if (!await hasPermission()) return;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastDynamicSchedule) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - last < _dynamicScheduleThrottleMs) return;

    if (zodiac == null) {
      await prefs.setInt(_kLastDynamicSchedule, nowMs);
      return;
    }

    try {
      final interests = await InterestTracker.getInterests();
      final jsonResponse = await AIService.getNotificationSchedule(
        zodiac,
        language,
        5,
        startDate: DateTime.now(),
        interests: interests,
      );
      final data = jsonDecode(jsonResponse) as Map<String, dynamic>;

      final morning = (data['morning'] as List? ?? []).map((e) => e.toString()).toList();
      final evening = (data['evening'] as List? ?? []).map((e) => e.toString()).toList();
      final afternoon = (data['afternoon'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      await scheduleDynamicNotifications(
        morning: morning,
        evening: evening,
        afternoonAI: afternoon,
      );
      await prefs.setInt(_kLastDynamicSchedule, nowMs);
    } catch (e) {
      if (kDebugMode) debugPrint('bootstrapDynamic failed: $e');
    }
  }

  // --- Permission Dialog (UI layer) ---

  Future<void> checkPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool? asked = prefs.getBool('notification_permission_asked');

    bool enabled = await hasPermission();
    if (enabled) {
      await scheduleDailyNotifications();
      return;
    }

    if (asked == true) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceColor,
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
                final granted = await requestPermission();
                if (granted) {
                  await scheduleDailyNotifications();
                }
              },
              child: const Text("Yes, Enable"),
            ),
          ],
        ),
      );
    }
  }

  // --- Scheduling ---

  Future<void> scheduleDailyNotifications({
    LocalizedNotificationStrings? localized,
  }) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    bool guestMode = prefs.getBool('guest_mode') ?? false;

    final String dTitle = localized?.dailyTitle ?? "🌞 Aaj ka rashifal ready hai";
    final String dBody = localized?.dailyBody ?? "Jaaniye aaj ka shubh samay aur din ka haal.";

    tz.TZDateTime dailyDate = _nextInstanceOfTime(7, 30);
    await _scheduleDaily(
      id: 101,
      title: dTitle,
      body: dBody,
      scheduledDate: dailyDate,
    );

    await _saveNotificationToStorage(
      dTitle,
      dBody,
      "Local",
      true,
      scheduledTime: dailyDate,
    );

    if (guestMode) return;

    final String eTitle = localized?.eveningTitle ?? "✨ Aaj ki shaam ka vishesh sandesh";
    final String eBody = localized?.eveningBody ?? "Aapke rishton aur bhavnao ke liye kya kehte hain sitare?";

    // Schedule 4 weeks of evening notifications (Mon/Wed/Fri/Sat at 20:30)
    // as one-time events to avoid matchDateTimeComponents.dayOfWeekAndTime bug.
    List<int> eveningDays = [DateTime.monday, DateTime.wednesday, DateTime.friday, DateTime.saturday];
    int weekCount = 4;
    int idBase = 2000;

    for (int week = 0; week < weekCount; week++) {
      for (int dayIdx = 0; dayIdx < eveningDays.length; dayIdx++) {
        int day = eveningDays[dayIdx];
        tz.TZDateTime eveningDate = _nextInstanceOfDayTime(day, 20, 30);
        // Add 7 days for each subsequent week
        eveningDate = eveningDate.add(Duration(days: week * 7));

        int id = idBase + week * 4 + dayIdx;
        await _scheduleEveningOneTime(
          id: id,
          title: eTitle,
          body: eBody,
          scheduledDate: eveningDate,
        );

        await _saveNotificationToStorage(
          eTitle,
          eBody,
          "Local",
          false,
          scheduledTime: eveningDate,
        );
      }
    }
  }

  Future<void> scheduleDynamicNotifications({
    required List<String> morning,
    required List<String> evening,
    required List<Map<String, dynamic>> afternoonAI,
  }) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    int count = morning.length < evening.length ? morning.length : evening.length;

    for (int i = 0; i < count; i++) {
      tz.TZDateTime morningDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0)
          .add(Duration(days: i + 1));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1000 + i,
        "🌞 AstroPrerna Insight",
        morning[i],
        morningDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel',
            'Daily Horoscope',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_launcher',
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      await _saveNotificationToStorage(
        "🌞 AstroPrerna Insight",
        morning[i],
        "AI",
        true,
        scheduledTime: morningDate,
      );

      tz.TZDateTime eveningDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0)
          .add(Duration(days: i + 1));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        2000 + i,
        "🌙 Evening Reflection",
        evening[i],
        eveningDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'evening_channel',
            'Evening Guidance',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'ic_launcher',
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      await _saveNotificationToStorage(
        "🌙 Evening Reflection",
        evening[i],
        "AI",
        false,
        scheduledTime: eveningDate,
      );
    }

    for (int i = 0; i < afternoonAI.length; i++) {
       var item = afternoonAI[i];
       String msg = item['message']?.toString() ?? "✨ Check your horoscope";
       int offset = (item['day_offset'] is int) ? item['day_offset'] : 0;
       int hour = (item['hour'] is int) ? item['hour'] : 14;

       tz.TZDateTime festivalDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0)
          .add(Duration(days: offset));

       if (festivalDate.isBefore(now)) continue;

       await flutterLocalNotificationsPlugin.zonedSchedule(
        3000 + i,
        "🎉 Special Update",
        msg,
        festivalDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'festival_channel',
            'Festival Alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_launcher',
            color: Colors.redAccent,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

       await _saveNotificationToStorage(
        "🎉 Special Update",
        msg,
        "AI-Festival",
        true,
        scheduledTime: festivalDate,
      );
    }
  }

  Future<void> _scheduleFestivals({
    int daysAhead = 14,
    String language = 'en',
    LocalizedNotificationStrings? localized,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final upcoming = HinduFestivals.upcomingFrom(
      now.toLocal(),
      days: daysAhead,
    );

    int id = 4000;
    for (final entry in upcoming) {
      final f = entry.festival;
      final d = entry.date;
      final tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local, d.year, d.month, d.day, f.hour, 0,
      );
      if (scheduled.isBefore(now)) continue;

      // Use the localized festival name; if the caller provided localized
      // title/body builders, use them, otherwise fall back to the festival's
      // hardcoded English title/body.
      final festName = f.nameFor(language);
      final String title;
      final String body;
      if (localized != null) {
        title = localized.festivalTitleFor(festName);
        body = localized.festivalBodyFor(festName);
      } else {
        title = f.title;
        body = f.body;
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id++,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'festival_channel',
            'Festival Alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_launcher',
            color: Colors.redAccent,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      await _saveNotificationToStorage(
        title,
        body,
        "Festival",
        true,
        scheduledTime: scheduled,
      );
    }
  }

  /// Schedules two re-engagement notifications that fire even if the app is
  /// killed: one 1 day from now and another 3 days from now. They use the
  /// user's selected language so the message feels personal. The IDs
  /// (5000/5001) are fixed so re-scheduling replaces the previous ones
  /// rather than stacking duplicates.
  Future<void> _scheduleReengagementNotifications({
    LocalizedNotificationStrings? localized,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool guestMode = prefs.getBool('guest_mode') ?? false;
    if (guestMode) return;

    final String r1Title = localized?.reengageTitle ?? "🌙 The stars missed you";
    final String r1Body = localized?.reengageBody ?? "Your daily horoscope is ready.";
    final String r2Title = localized?.reengage2Title ?? "💫 Don't miss your sign";
    final String r2Body = localized?.reengage2Body ?? "Your Kundli insights are waiting.";

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // First re-engagement: 1 day from now at 11:00 AM.
    tz.TZDateTime r1Date = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 11, 0,
    ).add(const Duration(days: 1));
    if (r1Date.isBefore(now)) {
      r1Date = r1Date.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      5000,
      r1Title,
      r1Body,
      r1Date,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reengage_channel',
          'Re-engagement',
          channelDescription: 'Reminders to bring you back to the stars',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_launcher',
          color: AppColors.primaryPurple,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    await _saveNotificationToStorage(
      r1Title,
      r1Body,
      "Re-engage",
      false,
      scheduledTime: r1Date,
    );

    // Second re-engagement: 3 days from now at 6:00 PM.
    tz.TZDateTime r2Date = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 18, 0,
    ).add(const Duration(days: 3));
    if (r2Date.isBefore(now)) {
      r2Date = r2Date.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      5001,
      r2Title,
      r2Body,
      r2Date,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reengage_channel',
          'Re-engagement',
          channelDescription: 'Reminders to bring you back to the stars',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_launcher',
          color: AppColors.primaryPurple,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    await _saveNotificationToStorage(
      r2Title,
      r2Body,
      "Re-engage",
      false,
      scheduledTime: r2Date,
    );
  }

  Future<void> _scheduleDaily({required int id, required String title, required String body, required tz.TZDateTime scheduledDate}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Horoscope',
          channelDescription: 'Daily updates for your zodiac',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_launcher',
          color: AppColors.primaryGold,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEveningOneTime({required int id, required String title, required String body, required tz.TZDateTime scheduledDate}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_channel',
          'Evening Guidance',
          channelDescription: 'Evening astrological insights',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_launcher',
          color: AppColors.primaryPurple,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
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
          icon: 'ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    await prefs.setString('last_triggered_notif_date', today);
    await _saveNotificationToStorage(title, body, "Local", false, scheduledTime: scheduledDate);
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
    String title = notification.title ?? "New Notification";
    String body = notification.body ?? "";

    String? launchUrl = notification.launchUrl;
    if (launchUrl == null && notification.additionalData != null) {
      if (notification.additionalData!.containsKey('launchUrl')) {
        launchUrl = notification.additionalData!['launchUrl'] as String?;
      }
    }

    String? imageUrl = notification.bigPicture;
    if (imageUrl == null && notification.largeIcon != null) {
      if (notification.largeIcon!.startsWith("http")) {
        imageUrl = notification.largeIcon;
      }
    }

    await _saveNotificationToStorage(
      title,
      body,
      "OneSignal",
      true,
      scheduledTime: DateTime.now(),
      launchUrl: launchUrl,
      imageUrl: imageUrl,
    );
  }

  Future<void> _saveNotificationToStorage(
    String title,
    String body,
    String source,
    bool isImportant,
    {DateTime? scheduledTime, String? launchUrl, String? imageUrl}
  ) async {
    List<Map<String, dynamic>> notifications = await getNotifications();

    DateTime timestamp = scheduledTime ?? DateTime.now();
    String timeStr = timestamp.toIso8601String();

    bool isDuplicate = notifications.any((n) {
      if (n['title'] != title || n['body'] != body) return false;
      DateTime? existingTime;
      try {
        existingTime = DateTime.parse(n['timestamp']);
      } catch (e) {
        return false;
      }
      return existingTime.year == timestamp.year &&
             existingTime.month == timestamp.month &&
             existingTime.day == timestamp.day;
    });

    if (isDuplicate) {
      return;
    }

    notifications.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString() + (scheduledTime?.minute.toString() ?? ""),
      'title': title,
      'body': body,
      'timestamp': timeStr,
      'read': false,
      'source': source,
      'importance': isImportant ? 'high' : 'normal',
      'launchUrl': launchUrl,
      'imageUrl': imageUrl,
    });

    notifications.sort((a, b) {
      DateTime ta = DateTime.parse(a['timestamp']);
      DateTime tb = DateTime.parse(b['timestamp']);
      return tb.compareTo(ta);
    });

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

  Future<void> markAsRead(String id) async {
    List<Map<String, dynamic>> notifications = await getNotifications();
    int index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notifications[index]['read'] = true;
      String jsonStr = jsonEncode(notifications);
      await UserSession.setString('notifications_list', jsonStr);
      await _updateUnreadCount();
    }
  }

  Future<void> markAllAsRead() async {
    List<Map<String, dynamic>> notifications = await getNotifications();
    bool changed = false;
    final now = DateTime.now();

    for (var n in notifications) {
      DateTime ts = DateTime.parse(n['timestamp']);
      if (ts.isBefore(now) && n['read'] == false) {
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
    final now = DateTime.now();

    int count = notifications.where((n) {
      bool isUnread = n['read'] == false;
      DateTime ts = DateTime.parse(n['timestamp']);
      bool isVisible = ts.isBefore(now) || ts.isAtSameMomentAs(now);
      return isUnread && isVisible;
    }).length;

    unreadCount.value = count;
  }
}
