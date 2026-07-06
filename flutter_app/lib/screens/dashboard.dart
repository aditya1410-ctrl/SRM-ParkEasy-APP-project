import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<dynamic> slots = [];
  int unreadCount = 0;
  String selectedFilter = "ALL";
  bool isLoading = false;

  Future<void> loadSlots() async {
    setState(() => isLoading = true);
    try {
      final loadedSlots = await ApiService.getSlots(status: selectedFilter);
      if (!mounted) return;
      setState(() => slots = loadedSlots);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst("Exception: ", ""))));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  int _countByStatus(String status) {
    return slots.where((slot) => slot["slot_status"] == status).length;
  }

  Color _statusColor(String status) {
    if (status == "AVAILABLE") return ParkEasyTheme.success;
    if (status == "OCCUPIED") return ParkEasyTheme.error;
    return ParkEasyTheme.textSecondary;
  }

  String _nameFromUser() {
    final String fullName = (widget.user["name"] ?? "").toString();
    if (fullName.trim().isEmpty) return "User";
    return fullName.split(" ").first;
  }

  int _userId() {
    final dynamic userIdRaw = widget.user["user_id"];
    if (userIdRaw is int) return userIdRaw;
    if (userIdRaw is num) return userIdRaw.toInt();
    return int.parse(userIdRaw.toString());
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await ApiService.getNotifications(_userId());
      final int count = notifications.where((item) => item["status"] == "SENT").length;
      if (!mounted) return;
      setState(() => unreadCount = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationScreen(user: widget.user)),
    );
    if (!mounted) return;
    _loadUnreadCount();
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
    );
    if (!mounted) return;
    _loadUnreadCount();
  }

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ParkEasyTheme.error),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    loadSlots();
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParkEasyBackdrop(
        maxWidth: 1100,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E7490), Color(0xFF155E75)],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    color: ParkEasyTheme.primary.withValues(alpha: 0.26),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.directions_car_filled_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, ${_nameFromUser()}",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Select and reserve your parking slot",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openProfile,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.person_outline_rounded),
                    tooltip: "Profile",
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _openNotifications,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_rounded),
                        if (unreadCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: ParkEasyTheme.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              child: Text(
                                unreadCount > 9 ? "9+" : unreadCount.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: "Notifications",
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: loadSlots,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: "Refresh slots",
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _logout,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: "Logout",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ["ALL", "AVAILABLE", "OCCUPIED"].map((filterLabel) {
                return ChoiceChip(
                  selected: selectedFilter == filterLabel,
                  label: Text(filterLabel),
                  selectedColor: const Color(0xFFCCFBF1),
                  side: BorderSide(
                    color: selectedFilter == filterLabel
                        ? ParkEasyTheme.primary
                        : const Color(0xFFC9D8EA),
                  ),
                  onSelected: (_) {
                    if (selectedFilter == filterLabel) return;
                    setState(() => selectedFilter = filterLabel);
                    loadSlots();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard(
                  title: "Shown",
                  value: slots.length.toString(),
                  color: ParkEasyTheme.primaryDark,
                ),
                const SizedBox(width: 8),
                _statCard(
                  title: "Available",
                  value: _countByStatus("AVAILABLE").toString(),
                  color: ParkEasyTheme.success,
                ),
                const SizedBox(width: 8),
                _statCard(
                  title: "Occupied",
                  value: _countByStatus("OCCUPIED").toString(),
                  color: ParkEasyTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: loadSlots,
                      child: slots.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.local_parking_outlined,
                                  size: 54,
                                  color: ParkEasyTheme.textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No slots found for $selectedFilter",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: slots.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final slot = slots[i] as Map<String, dynamic>;
                                final String status = slot["slot_status"].toString();
                                final bool isAvailable = status == "AVAILABLE";
                                return _slotCard(
                                  context: context,
                                  slot: slot,
                                  status: status,
                                  isAvailable: isAvailable,
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

  Widget _statCard({required String title, required String value, required Color color}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ParkEasyTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: color, fontSize: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotCard({
    required BuildContext context,
    required Map<String, dynamic> slot,
    required String status,
    required bool isAvailable,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isAvailable
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingScreen(slot: slot, user: widget.user),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAvailable ? Icons.local_parking_rounded : Icons.block_rounded,
                  color: _statusColor(status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Slot ${slot["slot_number"]}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${slot["zone_name"]} · ${slot["location"]}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _statusColor(status), fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isAvailable ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
                size: 18,
                color: ParkEasyTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
