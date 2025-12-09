import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import 'login_screen.dart';

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
      // If user somehow got here in guest mode (e.g. direct nav), kick them out or show dialog
      // Since HomeScreen blocks it, this is just defensive.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0E1016),
            title: const Text("Access Denied", style: TextStyle(color: Color(0xFFD4AF37))),
            content: const Text("This feature is only available for logged-in users.", style: TextStyle(color: Colors.white)),
            actions: [
              ElevatedButton(
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
    // For now, if we don't have it, we pass a generic context.
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
      return const Center(child: CircularProgressIndicator()); // Waiting for redirect
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return ListTile(
                title: Align(
                  alignment: msg['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: msg['role'] == 'user' ? Colors.blue[900] : Colors.purple[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['content']!, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ask a question...",
                    hintStyle: TextStyle(color: Colors.grey),
                    fillColor: Color(0xFF0E1016),
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                )
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        )
      ],
    );
  }
}
