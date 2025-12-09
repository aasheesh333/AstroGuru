import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'horoscope_screen.dart';
import 'kundli_input_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HoroscopeContent(),
    const KundliInputContent(),
    const ChatContent(),
    const ProfileContent(),
  ];

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
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGold, width: 2),
                color: AppColors.surfaceColor,
              ),
              child: const Icon(Icons.person, color: AppColors.primaryGold, size: 20),
            ),
          ),
        );
        titleWidget = const Text(
          "AstroPrerna",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)
        );
        centerTitle = true;
        actions = [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No new notifications")),
              );
            },
          ),
        ];
        break;
      case 1:
        titleWidget = const Text("Horoscope");
        break;
      case 2:
        titleWidget = const Text("Generate Kundli");
        break;
      case 3:
        titleWidget = const Text("Ask AI Sage");
        break;
      case 4:
        titleWidget = const Text("Profile");
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Horoscope',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'Kundli',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
