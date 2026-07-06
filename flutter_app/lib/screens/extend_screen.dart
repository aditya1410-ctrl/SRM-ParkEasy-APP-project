import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';

class ExtendScreen extends StatefulWidget {
  final int bookingId;

  const ExtendScreen({super.key, required this.bookingId});

  @override
  State<ExtendScreen> createState() => _ExtendScreenState();
}

class _ExtendScreenState extends State<ExtendScreen> {
  DateTime? _extendedUntil;
  final TextEditingController _extraAmount = TextEditingController(text: "20");
  bool _isLoading = false;

  String _formatDateTime(DateTime dt) {
    final String twoDigitMonth = dt.month.toString().padLeft(2, "0");
    final String twoDigitDay = dt.day.toString().padLeft(2, "0");
    final String twoDigitHour = dt.hour.toString().padLeft(2, "0");
    final String twoDigitMinute = dt.minute.toString().padLeft(2, "0");
    return "${dt.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute:00";
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _extendedUntil ?? now.add(const Duration(hours: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _extendedUntil = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _extendBooking() async {
    if (_extendedUntil == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select new end time")));
      return;
    }

    final double? extraAmount = double.tryParse(_extraAmount.text.trim());
    if (extraAmount == null || extraAmount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid extra amount")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.extend({
        "booking_id": widget.bookingId,
        "extended_until": _formatDateTime(_extendedUntil!),
        "extra_amount": extraAmount,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Booking extended successfully")));
      Navigator.pop(context);
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

  String _displayDateTime(DateTime? value) {
    if (value == null) return "Not selected";
    return "${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, "0")}:${value.minute.toString().padLeft(2, "0")}";
  }

  @override
  void dispose() {
    _extraAmount.dispose();
    super.dispose();
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
                    Text("Extend Parking", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      "Booking #${widget.bookingId}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD7E2F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: ParkEasyTheme.primaryDark),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Extended Until", style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    _displayDateTime(_extendedUntil),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _extraAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Extra Amount",
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _extendBooking,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.update_rounded),
                        label: Text(_isLoading ? "Extending..." : "Confirm Extension"),
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
