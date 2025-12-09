import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

// ChatScreen wrapper
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ask AI Sage")),
      body: const ChatContent(),
    );
  }
}

class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('guest_mode') ?? false;
    });

    if (isGuest && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceColor,
            title: const Text("Access Denied", style: TextStyle(color: AppColors.primaryGold)),
            content: const Text("This feature is only available for logged-in users.", style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Text("Log in Now"),
              ),
            ],
          ),
        );
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    String userMsg = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMsg});
      _controller.clear();
    });

    String lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

    // In a real scenario, we would retrieve the stored Kundli summary here.
    String kundliSummary = "General Query (No specific Kundli context available).";

    try {
      String response = await AIService.getChatResponse(userMsg, kundliSummary, lang);
      setState(() {
        _messages.add({'role': 'sage', 'content': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'sage', 'content': "Sorry, I am having trouble connecting to the stars right now."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primaryPurple : AppColors.surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                      ),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.2),
                           blurRadius: 4,
                           offset: const Offset(0, 2),
                         )
                      ]
                    ),
                    child: Text(
                      msg['content']!,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: const BoxDecoration(
            color: AppColors.surfaceColor,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Ask AI Sage...",
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                )
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGold,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
