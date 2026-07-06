import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';

class NotificationScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const NotificationScreen({super.key, required this.user});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;
  List<dynamic> _notifications = [];

  int _userId() {
    final dynamic userIdRaw = widget.user["user_id"];
    if (userIdRaw is int) return userIdRaw;
    if (userIdRaw is num) return userIdRaw.toInt();
    return int.parse(userIdRaw.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await ApiService.getNotifications(_userId());
      if (!mounted) return;
      setState(() => _notifications = notifications);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst("Exception: ", ""))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _unreadCount() {
    return _notifications.where((item) => item["status"] == "SENT").length;
  }

  String _formatSentTime(dynamic rawTime) {
    if (rawTime == null) return "";
    final String value = rawTime.toString();
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return "${parsed.day.toString().padLeft(2, "0")}/${parsed.month.toString().padLeft(2, "0")}/${parsed.year} ${parsed.hour.toString().padLeft(2, "0")}:${parsed.minute.toString().padLeft(2, "0")}";
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item["status"] == "READ") return;
    final int notificationId = (item["notification_id"] as num).toInt();
    try {
      await ApiService.markNotificationRead(notificationId);
      if (!mounted) return;
      setState(() => item["status"] = "READ");
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParkEasyBackdrop(
        maxWidth: 760,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFE0F2FE),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: ParkEasyTheme.primaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Notifications", style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            "${_notifications.length} total · ${_unreadCount()} unread",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: _notifications.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 56,
                                  color: ParkEasyTheme.textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "No notifications yet",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _notifications.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final item = _notifications[index] as Map<String, dynamic>;
                                final bool isUnread = item["status"] == "SENT";
                                return Card(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _markRead(item),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.only(top: 6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isUnread ? ParkEasyTheme.accent : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item["message"]?.toString() ?? "",
                                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                    color: ParkEasyTheme.textPrimary,
                                                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatSentTime(item["sent_time"]),
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isUnread
                                                  ? const Color(0xFFFFEDD5)
                                                  : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              item["status"]?.toString() ?? "",
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontSize: 11,
                                                color: isUnread ? ParkEasyTheme.accent : ParkEasyTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
