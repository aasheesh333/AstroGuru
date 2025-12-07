import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    String userMsg = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMsg});
      _controller.clear();
    });

    // Mock Kundli Summary for now
    String kundliSummary = "Sun in Aries, Moon in Taurus, Ascendant Gemini.";
    String lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

    String response = await AIService.getChatResponse(userMsg, kundliSummary, lang);
    setState(() {
      _messages.add({'role': 'sage', 'content': response});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ask AI Sage")),
      body: Column(
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
                        color: msg['role'] == 'user' ? Colors.blue[100] : Colors.purple[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg['content']!),
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
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Ask a question..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
