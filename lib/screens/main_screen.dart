import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../logic/user_provider.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import 'home_screen.dart';
import 'horoscope_screen.dart';
import 'kundli_input_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../widgets/banner_ad_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ChatContentState> _chatKey = GlobalKey<ChatContentState>();
  late final List<Widget> _screens;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onTabChange: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const HoroscopeContent(),
      const KundliInputContent(),
      ChatContent(key: _chatKey),
      const ProfileContent(),
    ];

    // Check Notification Permissions and Schedule Dynamic Content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkPermissions(context);
      _checkAndScheduleDynamicNotifications();
      // Load user data immediately on app launch
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  Future<void> _checkAndScheduleDynamicNotifications() async {
    // 1. Check last scheduled time to avoid API spam
    final prefs = await SharedPreferences.getInstance();
    final lastScheduled = prefs.getInt('last_notification_schedule_time');
    final now = DateTime.now().millisecondsSinceEpoch;
    final threeDays = 3 * 24 * 60 * 60 * 1000;

    if (lastScheduled != null && (now - lastScheduled) < threeDays) {
      return; // Already scheduled recently
    }

    // 2. Prepare Context (Zodiac & Language)
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final zodiac = userProvider.zodiac; // Nullable (if not logged in or not set)

    // Use stored language or default to en
    final language = AppLocalizations.of(context)?.localeName ?? 'en';

    // 3. Fetch from AI in Background
    try {
       // Generate 5 days of content
       final jsonResponse = await AIService.getNotificationSchedule(
         zodiac,
         language,
         5,
         startDate: DateTime.now(),
       );
       final data = jsonDecode(jsonResponse);

       if (data is Map) {
         List<String> morning = [];
         List<String> evening = [];
         List<Map<String, dynamic>> afternoon = [];

         if (data.containsKey('morning')) {
            morning = (data['morning'] as List).map((e) => e.toString()).toList();
         }
         if (data.containsKey('evening')) {
            evening = (data['evening'] as List).map((e) => e.toString()).toList();
         }
         if (data.containsKey('afternoon')) {
            afternoon = (data['afternoon'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
         }

         if (morning.isNotEmpty && evening.isNotEmpty) {
            // 4. Schedule
            await NotificationService().scheduleDynamicNotifications(morning, evening, afternoon);

            // 5. Update timestamp
            await prefs.setInt('last_notification_schedule_time', now);
         }
       }
    } catch (e) {
      // Silently fail or fallback to static is handled by NotificationService's daily recurring default
      // if we haven't cancelled it yet. But since we use static as fallback, it's fine.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      final currentLocale = localizations.localeName;
      if (_lastLocale != currentLocale) {
        _lastLocale = currentLocale;
        // Trigger rescheduling logic when language changes
        // Force update regardless of time limit to ensure language matches
        Future.microtask(() async {
           final prefs = await SharedPreferences.getInstance();
           await prefs.remove('last_notification_schedule_time'); // Force refresh
           _checkAndScheduleDynamicNotifications();
        });
      }
    }
  }

  PreferredSizeWidget? _buildAppBar() {
    Widget? titleWidget;
    List<Widget>? actions;
    bool centerTitle = false;
    Widget? leading;

    switch (_currentIndex) {
      case 0: // Home
        leading = GestureDetector(
          onTap: () {
            setState(() => _currentIndex = 4);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final url = userProvider.profileImageUrl;
                final b64 = userProvider.profileImageBase64;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                    color: AppColors.surfaceColor,
                  ),
                  child: ClipOval(
                    child: _buildMainAvatar(url: url, base64: b64),
                  ),
                );
              },
            ),
          ),
        );
        titleWidget = Text(
          AppLocalizations.of(context)!.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)
        );
        centerTitle = true;
        actions = [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService().unreadCount,
            builder: (context, count, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen())
                  );
                },
              );
            }
          ),
        ];
        break;
      case 1:
        titleWidget = Text(AppLocalizations.of(context)!.dailyHoroscopeTitle);
        break;
      case 2:
        titleWidget = Text(AppLocalizations.of(context)!.generateKundliBtn);
        break;
      case 3:
        titleWidget = Text(AppLocalizations.of(context)!.aiChat);
        actions = [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset History",
            onPressed: () => _chatKey.currentState?.resetHistory(),
          ),
        ];
        break;
      case 4:
        titleWidget = Text(AppLocalizations.of(context)!.profile);
        break;
      default:
        return null;
    }

    return AppBar(
      title: titleWidget,
      centerTitle: centerTitle,
      actions: actions,
      leading: leading, // Add leading widget
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceColor, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed, // Ensure items don't shift
              backgroundColor: AppColors.scaffoldBackgroundColor, // Match scaffold background or surface
              selectedItemColor: AppColors.primaryGold,
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_filled),
                  label: AppLocalizations.of(context)!.navHome,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.star),
                  label: AppLocalizations.of(context)!.navHoroscope,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.auto_awesome),
                  label: AppLocalizations.of(context)!.navKundli,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat_bubble),
                  label: AppLocalizations.of(context)!.navChat,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: AppLocalizations.of(context)!.navProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMainAvatar({String? url, String? base64}) {
  if (url != null && url.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _mainAvatarFallback(base64),
    );
  }
  return _mainAvatarFallback(base64);
}

Widget _mainAvatarFallback(String? base64) {
  if (base64 != null && base64.isNotEmpty) {
    try {
      return Image.memory(
        base64Decode(base64),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } catch (_) {
      // fall through
    }
  }
  return Container(
    width: 40,
    height: 40,
    color: AppColors.surfaceColor,
    child: const Icon(Icons.person, color: AppColors.primaryGold, size: 20),
  );
}
