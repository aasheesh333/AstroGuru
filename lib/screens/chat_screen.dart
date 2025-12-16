import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../logic/language_provider.dart';
import '../logic/user_session.dart';
import '../logic/user_provider.dart';
import '../services/ai_service.dart';
import '../services/ad_service.dart';
import '../theme/app_colors.dart';
import '../widgets/astro_text_parser.dart';
import '../widgets/baba_avatar.dart';
import 'login_screen.dart';

// ChatScreen wrapper
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatContent();
  }
}

class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => ChatContentState();
}

class ChatContentState extends State<ChatContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool isGuest = false;
  // String? _profileImagePath; // Removed local state for Provider
  // String? _profileImageBase64; // Removed local state for Provider

  // Moderation State
  int _spamStrikes = 0;
  int _nudityCount = 0;
  bool _isBanned = false;
  String? _lastMessageContent;
  bool _isTextTooLong = false;

  // Limits
  int _totalCharsSent = 0;
  int _charLimit = 5000;

  // Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller.addListener(_checkLength);
    _checkAccess();
  }

  void _checkLength() {
    final tooLong = _controller.text.trim().length > 1000;
    if (tooLong != _isTextTooLong) {
      setState(() {
        _isTextTooLong = tooLong;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkLength);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();

    bool guest = prefs.getBool('guest_mode') ?? false;
    // Provider handles user data now

    // Load moderation state via session
    int spam = await UserSession.getInt('spam_strikes') ?? 0;
    int nudity = await UserSession.getInt('nudity_count') ?? 0;
    bool banned = await UserSession.getBool('is_banned') ?? false;

    // Load Limits
    int chars = await UserSession.getInt('total_chars_sent') ?? 0;
    int limit = await UserSession.getInt('char_limit') ?? 5000;

    // Track Opens for Interstitial Ad (Every 5th open)
    int openCount = await UserSession.getInt('sage_open_count') ?? 0;
    openCount++;
    await UserSession.setInt('sage_open_count', openCount);

    if (mounted) {
      setState(() {
        isGuest = guest;
        _spamStrikes = spam;
        _nudityCount = nudity;
        _isBanned = banned;
        _totalCharsSent = chars;
        _charLimit = limit;
      });

      if (openCount % 5 == 0) {
        // Show Interstitial Ad
        AdService().showInterstitialAd();
      }
    }

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
    } else if (_isBanned && mounted) {
       _showBanDialog();
    } else {
      _loadHistory();
    }
  }

  void _loadHistory() async {
    final String? historyJson = await UserSession.getString('chat_history'); // Session based

    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      setState(() {
        _messages = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }

    // Add default greeting if empty
    if (_messages.isEmpty) {
      setState(() {
        _messages.add({
          'role': 'sage',
          'content': "Namaste! I am your AI Sage. Ask me anything about your destiny."
        });
      });
    }

    // Check history length warning (40k chars ~= approx 4000 words)
    int totalLength = _messages.fold(0, (sum, msg) => sum + (msg['content']?.length ?? 0));
    if (totalLength > 40000) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: const Text("Chat history is very long. Please Reset History for better responses."),
             action: SnackBarAction(label: "Reset", onPressed: resetHistory),
             duration: const Duration(seconds: 5),
           )
        );
      });
    }

    _scrollToBottom();
  }

  void _saveHistory() async {
    await UserSession.setString('chat_history', jsonEncode(_messages));
  }

  void resetHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text("Reset History?", style: TextStyle(color: AppColors.primaryGold)),
        content: const Text("This will clear your conversation memory with the Sage.", style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reset", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
        _messages.add({
          'role': 'sage',
          'content': "Namaste! I am your AI Sage. Ask me anything about your destiny."
        });
      });
      _saveHistory();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_isBanned) {
      _showBanDialog();
      return;
    }

    if (_isTextTooLong) return; // UI should prevent this, but safety check.

    if (_controller.text.trim().isEmpty) return;
    String userMsg = _controller.text.trim();

    // --- Limit Check ---
    if (_totalCharsSent + userMsg.length > _charLimit) {
      _showLimitReachedDialog();
      return;
    }

    // --- Spam & Moderation Checks ---
    bool isViolation = false;
    String violationReason = "";

    // Repetition Check
    if (_lastMessageContent == userMsg) {
      isViolation = true;
      violationReason = "Repeated message detected.";
    }

    // 3. Nudity/Inappropriate Content Check
    final badWords = ["nude", "naked", "sex", "porn", "xxx", "nudity"]; // Basic list
    bool hasBadWord = badWords.any((word) => userMsg.toLowerCase().contains(word));
    if (hasBadWord) {
      _nudityCount++;
      if (_nudityCount > 5) {
         isViolation = true;
         violationReason = "Inappropriate content limit exceeded.";
      }
    }

    if (isViolation) {
      _handleStrike(violationReason);
      return;
    }

    // Update last message
    _lastMessageContent = userMsg;
    // -------------------------------

    // Update usage
    _totalCharsSent += userMsg.length;
    await UserSession.setInt('total_chars_sent', _totalCharsSent);

    setState(() {
      _messages.add({'role': 'user', 'content': userMsg});
      _controller.clear();
    });
    _saveHistory();
    _scrollToBottom();

    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    final provider = Provider.of<UserProvider>(context, listen: false);

    // Build context with latest user details
    String kundliSummary = "User Name: ${provider.name}. ";
    if (provider.dob.isNotEmpty) {
      kundliSummary += "DOB: ${provider.dob}. Zodiac: ${provider.zodiac}. ";
    }
    kundliSummary += "General Query.";

    try {
      // Pass history (excluding the message we just added effectively, handled by logic but passing all for context)
      // Actually, we pass the current list including the user's new message
      String response = await AIService.getChatResponse(userMsg, kundliSummary, lang, _messages);

      if (mounted) {
        setState(() {
          _messages.add({'role': 'sage', 'content': response});
        });
        _saveHistory();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'sage', 'content': "Sorry, I am having trouble connecting to the stars right now."});
        });
        _scrollToBottom();
      }
    }
  }

  void _handleStrike(String reason) async {
    setState(() {
      _spamStrikes++;
    });

    // Persist state
    await UserSession.setInt('spam_strikes', _spamStrikes);
    await UserSession.setInt('nudity_count', _nudityCount);

    if (_spamStrikes >= 4) {
      setState(() {
        _isBanned = true;
      });
      await UserSession.setBool('is_banned', true);
      _enforceBan();
    } else {
      _showWarningDialog(reason, 4 - _spamStrikes);
    }
  }

  void _enforceBan() async {
    // 1. Log to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'banned': true,
          'ban_reason': "Repeated violations (Spam/Inappropriate Content)",
          'timestamp': FieldValue.serverTimestamp(),
          'email': user.email,
        }, SetOptions(merge: true));

        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Fallback if network fails, local ban is already set
        print("Error logging ban to Firebase: $e");
      }
    }

    // 2. Clear Local Session
    await UserSession.clearSession(); // Handled by prefix logic
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_in', false);
    // We don't need to manually clear user_email/name as UserSession handles the data pointer

    // 3. Show Dialog then Navigate
    if (mounted) {
       _showBanDialog(navigateAfter: true);
    }
  }

  void _showWarningDialog(String reason, int attemptsLeft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text("Warning", style: TextStyle(color: Colors.red)),
        content: Text(
          "$reason\nYou have $attemptsLeft attempt(s) left before being banned.",
          style: const TextStyle(color: AppColors.textPrimary)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I Understand", style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text("Usage Limit Reached", style: TextStyle(color: AppColors.primaryGold)),
        content: const Text(
          "You have reached the free message limit. Watch a short ad to unlock 5000 more characters.",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              AdService().showRewardedAd(
                onUserEarnedReward: (reward) async {
                  setState(() {
                    _charLimit += 5000;
                  });
                  await UserSession.setInt('char_limit', _charLimit);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Limit extended by 5000 characters!")),
                  );
                },
                onAdFailed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to load ad. Please try again.")),
                  );
                }
              );
            },
            child: const Text("Watch Ad"),
          ),
        ],
      ),
    );
  }

  void _showBanDialog({bool navigateAfter = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text("Account Banned", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You have been banned due to repeated violations of our community guidelines.",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            SizedBox(height: 16),
            Text(
              "If you think this is a mistake, contact support:",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            SelectableText(
              "Aasheeshkatheriya@gmail.com",
              style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (navigateAfter)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text("Log Out & Exit", style: TextStyle(color: Colors.white)),
            )
        ],
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;

      bool available = await _speech.initialize(
        onStatus: (status) {
           if (status == 'notListening') {
             setState(() => _isListening = false);
           }
        },
        onError: (error) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
              // If final, maybe auto-send? User prefers confirm usually.
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Container(
        color: AppColors.scaffoldBackgroundColor,
        child: const Center(child: CircularProgressIndicator())
      );
    }

    return Container(
      color: AppColors.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8), // More breathing room
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        const SizedBox(width: 4), // Small offset
                         // Baba Avatar at bottom left of bubble
                         const Padding(
                           padding: EdgeInsets.only(bottom: 4),
                           child: BabaAvatar(size: 32),
                         ),
                        const SizedBox(width: 8),
                      ],

                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.primaryPurple : AppColors.surfaceColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                            ),
                            border: isUser ? null : Border.all(color: Colors.white10),
                          ),
                          child: isUser
                            ? Text(
                                msg['content']!,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              )
                            : AstroTextParser(text: msg['content']!), // Solves the '#' issue
                        ),
                      ),

                      if (isUser) ...[
                        const SizedBox(width: 8),
                        Consumer<UserProvider>(
                          builder: (context, provider, child) {
                             ImageProvider? img;
                             if (provider.profileImageBase64 != null) {
                               img = MemoryImage(base64Decode(provider.profileImageBase64!));
                             }
                             return CircleAvatar(
                               radius: 16,
                               backgroundColor: Colors.white24,
                               backgroundImage: img,
                               child: img == null
                                 ? const Icon(Icons.person, color: Colors.white, size: 20)
                                 : null,
                             );
                          }
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceColor, // Slightly distinct from scaffold to frame it
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                // Voice Icon
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.redAccent : AppColors.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    color: _isListening ? Colors.white : AppColors.primaryGold,
                    onPressed: _listen,
                  ),
                ),
                const SizedBox(width: 12),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type your question...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.scaffoldBackgroundColor, // Matches screen bg as requested
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),

                // Send Icon
                Container(
                  decoration: BoxDecoration(
                    color: _isTextTooLong ? Colors.grey : AppColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _isTextTooLong ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          if (_isTextTooLong)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Message too long (${_controller.text.trim().length}/1000)",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
