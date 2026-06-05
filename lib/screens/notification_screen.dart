import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final list = await NotificationService().getNotifications();
    final now = DateTime.now();

    // Filter out future notifications
    final visibleList = list.where((n) {
      DateTime ts = DateTime.tryParse(n['timestamp'] ?? "") ?? DateTime.now();
      return ts.isBefore(now) || ts.isAtSameMomentAs(now);
    }).toList();

    if (mounted) {
      setState(() {
        _notifications = visibleList;
        _isLoading = false;
      });
    }

    // REMOVE AUTO MARK-AS-READ
    // User wants unread items to stay highlighted until tapped/viewed explicitly
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notif) async {
    // 1. Mark as read
    String id = notif['id'];
    await NotificationService().markAsRead(id);

    // Refresh UI locally
    setState(() {
      int index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });

    // 2. Launch URL if present
    String? url = notif['launchUrl'];
    if (url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepPurple, AppColors.primaryPurple], // Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return _buildNotificationItem(notif);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold.withOpacity(0.1),
            ),
            child: const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.primaryGold),
          ),
          const SizedBox(height: 16),
          const Text(
            "No notifications yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll let you know when the stars align!",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    bool isRead = notif['read'] == true;
    bool isImportant = notif['importance'] == 'high' || notif['source'] == 'OneSignal';
    DateTime timestamp = DateTime.tryParse(notif['timestamp'] ?? "") ?? DateTime.now();
    String timeStr = DateFormat('MMM d, h:mm a').format(timestamp);
    String? imageUrl = notif['imageUrl'];

    // Visual Styling for Read vs Unread
    Color bgColor = isRead
        ? Colors.white.withOpacity(0.05) // Slight grey/transparent for read
        : AppColors.surfaceColor; // Darker surface for unread (highlighted)

    Color borderColor = isRead
        ? Colors.transparent
        : (isImportant ? AppColors.primaryGold : Colors.purpleAccent.withOpacity(0.5));

    Color textColor = isRead ? Colors.grey : Colors.white;
    FontWeight titleWeight = isRead ? FontWeight.normal : FontWeight.bold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notif),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRead ? Colors.grey.withOpacity(0.1) : (isImportant ? AppColors.primaryGold.withOpacity(0.2) : Colors.purple.withOpacity(0.2)),
                    image: imageUrl != null
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
                  ),
                  // If image fails or is default, we can add a child icon, but logo.png is safe
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title'] ?? "Notification",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: titleWeight,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif['body'] ?? "",
                        style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGold,
                                shape: BoxShape.circle,
                              ),
                            )
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
