import 'package:flutter/material.dart';

import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';
import 'extend_screen.dart';

class SuccessScreen extends StatelessWidget {
  final int bookingId;

  const SuccessScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParkEasyBackdrop(
        maxWidth: 560,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            color: ParkEasyTheme.success.withValues(alpha: 0.34),
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 18),
                    Text("Payment Successful", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      "Your slot is confirmed and ready to use.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF0FDF4),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        "Booking ID: $bookingId",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ParkEasyTheme.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.timelapse_rounded),
                        label: const Text("Extend Parking"),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExtendScreen(bookingId: bookingId),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
