import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const HoroscopeContent(),
      const KundliInputContent(),
      ChatContent(key: _chatKey),
      const ProfileContent(),
    ];

    // Check Notification Permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkPermissions(context);
    });
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
                if (userProvider.profileImageBase64 != null) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryGold, width: 2),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(userProvider.profileImageBase64!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                    color: AppColors.surfaceColor,
                  ),
                  child: const Icon(Icons.person, color: AppColors.primaryGold, size: 20),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed, // Ensure items don't shift
          backgroundColor: const Color(0xFF05060A), // Match scaffold background or surface
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
