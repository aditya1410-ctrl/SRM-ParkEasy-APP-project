import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  late Map<String, dynamic> _profile;

  int _userId() {
    final dynamic userIdRaw = _profile["user_id"] ?? widget.user["user_id"];
    if (userIdRaw is int) return userIdRaw;
    if (userIdRaw is num) return userIdRaw.toInt();
    return int.parse(userIdRaw.toString());
  }

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.user);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile(_userId());
      if (!mounted) return;
      setState(() => _profile = profile);
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

  String _createdAtText() {
    final dynamic raw = _profile["created_at"];
    if (raw == null) return "-";
    final DateTime? dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return "${dt.day.toString().padLeft(2, "0")}/${dt.month.toString().padLeft(2, "0")}/${dt.year}";
  }

  String _value(String key) {
    final dynamic value = _profile[key];
    if (value == null || value.toString().trim().isEmpty) return "-";
    return value.toString();
  }

  String _initials() {
    final String name = _value("name");
    if (name == "-") return "U";
    final parts = name.split(" ");
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return "${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}".toUpperCase();
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
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFD1FAE5),
                      child: Text(
                        _initials(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ParkEasyTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User Profile", style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            "SRM ParkEasy account details",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: "Refresh profile",
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
                  : ListView(
                      children: [
                        _infoCard("Name", _value("name"), Icons.person_outline_rounded),
                        const SizedBox(height: 10),
                        _infoCard("Email", _value("email"), Icons.email_outlined),
                        const SizedBox(height: 10),
                        _infoCard("Phone", _value("phone"), Icons.phone_outlined),
                        const SizedBox(height: 10),
                        _infoCard("SRM ID", _value("srm_id"), Icons.badge_outlined),
                        const SizedBox(height: 10),
                        _infoCard("Role", _value("role"), Icons.admin_panel_settings_outlined),
                        const SizedBox(height: 10),
                        _infoCard(
                          "Joined",
                          _createdAtText(),
                          Icons.calendar_month_outlined,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ParkEasyTheme.error,
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text("Logout"),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ParkEasyTheme.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ParkEasyTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
