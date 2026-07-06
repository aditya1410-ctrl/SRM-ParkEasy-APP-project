import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';
import 'success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;

  const PaymentScreen({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  Future<void> pay(String method) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.pay({
        "booking_id": widget.bookingId,
        "amount": widget.amount,
        "method": method,
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SuccessScreen(bookingId: widget.bookingId)),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParkEasyBackdrop(
        maxWidth: 640,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Payment", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      "Complete your booking securely",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFE0F2FE),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: ParkEasyTheme.primaryDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Booking #${widget.bookingId}",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            "₹${widget.amount.toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ParkEasyTheme.primaryDark,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _methodButton(
              title: "Pay with UPI",
              subtitle: "Fastest payment route",
              icon: Icons.qr_code_2_rounded,
              method: "UPI",
              tint: const Color(0xFFECFEFF),
            ),
            const SizedBox(height: 10),
            _methodButton(
              title: "Pay with Card",
              subtitle: "Credit or debit cards",
              icon: Icons.credit_card_rounded,
              method: "CARD",
              tint: const Color(0xFFFFF7ED),
            ),
            const SizedBox(height: 10),
            _methodButton(
              title: "Pay with Wallet",
              subtitle: "Campus wallet balance",
              icon: Icons.account_balance_wallet_rounded,
              method: "WALLET",
              tint: const Color(0xFFF0FDF4),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 18),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required String method,
    required Color tint,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isLoading ? null : () => pay(method),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: tint,
                ),
                child: Icon(icon, color: ParkEasyTheme.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
