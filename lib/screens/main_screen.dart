import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../logic/user_provider.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'horoscope_screen.dart';
import 'kundli_input_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

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
      _bootstrapDynamicNotifications();
      // Load user data immediately on app launch
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  Future<void> _bootstrapDynamicNotifications() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final zodiac = userProvider.zodiac;
    final language = AppLocalizations.of(context)?.localeName ?? 'en';
    await NotificationService().bootstrapDynamic(
      zodiac: zodiac,
      language: language,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      final currentLocale = localizations.localeName;
      if (_lastLocale != currentLocale) {
        _lastLocale = currentLocale;
        Future.microtask(() async {
           final prefs = await SharedPreferences.getInstance();
           await prefs.remove('last_notification_schedule_time');
           _bootstrapDynamicNotifications();
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
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.surfaceColor, width: 1),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryGold),
            onSelected: (value) {
              if (value == 'reset') {
                _chatKey.currentState?.resetHistory();
              } else if (value == 'export') {
                _chatKey.currentState?.exportChat();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.share, size: 20),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.chatExportHistory),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.mainResetHistoryTooltip),
                  ],
                ),
              ),
            ],
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
      bottomNavigationBar: Container(
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
