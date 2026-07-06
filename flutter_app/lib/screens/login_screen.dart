import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  bool _isLoading = false;

  Future<void> login() async {
    final userEmail = email.text.trim();
    if (userEmail.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter your email")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ApiService.login(userEmail);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(user: user)),
      );
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

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParkEasyBackdrop(
        maxWidth: 560,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF14B8A6), Color(0xFF0E7490)],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    color: ParkEasyTheme.primary.withValues(alpha: 0.28),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              "ParkEasy Login",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 10),
            Text(
              "Sign in to manage your slot bookings and extensions.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "SRM Email",
                        hintText: "aditya@srm.edu",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      onSubmitted: (_) {
                        if (!_isLoading) {
                          login();
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Continue"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Use one of the seeded users from your SQL setup.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
