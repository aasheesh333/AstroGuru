import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/baba_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Namaste! I am your AI Sage. Ask me anything about your destiny.',
      'isUser': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Sage'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['text'], msg['isUser']);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) const BabaAvatar(size: 40),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryPurple : AppColors.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isUser ? AppColors.primaryPurple : AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
             const CircleAvatar(
               radius: 20,
               backgroundColor: AppColors.surfaceColor,
               child: Icon(Icons.person, color: AppColors.textSecondary),
             ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(top: BorderSide(color: AppColors.textSecondary, width: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buttonGradient,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.surfaceColor),
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  setState(() {
                    _messages.add({'text': _textController.text, 'isUser': true});
                    // Simulate AI typing delay
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _messages.add({
                            'text': 'The stars suggest a time of reflection. Patience is key.',
                            'isUser': false,
                          });
                        });
                      }
                    });
                    _textController.clear();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
           // Voice Input Placeholder
           Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceColor,
              border: Border.all(color: AppColors.primaryGold),
            ),
            child: IconButton(
              icon: const Icon(Icons.mic, color: AppColors.primaryGold),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
