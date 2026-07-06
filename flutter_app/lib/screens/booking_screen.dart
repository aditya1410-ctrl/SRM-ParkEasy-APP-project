import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/parkeasy_theme.dart';
import '../widgets/parkeasy_backdrop.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> slot;
  final Map<String, dynamic> user;

  const BookingScreen({super.key, required this.slot, required this.user});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isLoading = false;
  List<dynamic> _vehicles = [];
  int? _selectedVehicleId;

  int _userId() {
    final dynamic userIdRaw = widget.user["user_id"];
    if (userIdRaw is int) return userIdRaw;
    if (userIdRaw is num) return userIdRaw.toInt();
    return int.parse(userIdRaw.toString());
  }

  int _parseVehicleId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await ApiService.getVehiclesForUser(_userId());
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        if (_vehicles.isNotEmpty) {
          _selectedVehicleId = _parseVehicleId(_vehicles.first["vehicle_id"]);
        }
      });
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

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStart
        ? (_startDateTime ?? now)
        : (_endDateTime ?? _startDateTime ?? now.add(const Duration(hours: 1)));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = selected;
      } else {
        _endDateTime = selected;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final String twoDigitMonth = dt.month.toString().padLeft(2, "0");
    final String twoDigitDay = dt.day.toString().padLeft(2, "0");
    final String twoDigitHour = dt.hour.toString().padLeft(2, "0");
    final String twoDigitMinute = dt.minute.toString().padLeft(2, "0");
    return "${dt.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute:00";
  }

  double _calculateAmount(DateTime start, DateTime end) {
    final int minutes = end.difference(start).inMinutes;
    final double hours = minutes <= 0 ? 0 : (minutes / 60);
    const double ratePerHour = 20.0;
    return (hours * ratePerHour).clamp(20, double.infinity);
  }

  Future<void> _book() async {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register a vehicle before booking")));
      return;
    }
    if (_startDateTime == null || _endDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select start and end time")));
      return;
    }
    if (_endDateTime!.isBefore(_startDateTime!) || _endDateTime == _startDateTime) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("End time must be after start time")));
      return;
    }

    final String startValue = _formatDateTime(_startDateTime!);
    final String endValue = _formatDateTime(_endDateTime!);
    final double amount = _calculateAmount(_startDateTime!, _endDateTime!);

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.bookSlot({
        "user_id": _userId(),
        "vehicle_id": _selectedVehicleId,
        "slot_id": widget.slot["slot_id"],
        "start_time": startValue,
        "end_time": endValue,
      });

      final int bookingId = response["booking_id"] as int;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(bookingId: bookingId, amount: amount),
        ),
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

  String _displayDateTime(DateTime? value) {
    if (value == null) return "Not selected";
    return "${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, "0")}:${value.minute.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final slotNumber = widget.slot["slot_number"];
    final bool hasTimeRange = _startDateTime != null && _endDateTime != null;
    final double estimate = hasTimeRange ? _calculateAmount(_startDateTime!, _endDateTime!) : 0;

    return Scaffold(
      body: ParkEasyBackdrop(
        maxWidth: 760,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFE6FFFA),
                            ),
                            child: const Icon(Icons.local_parking_rounded, color: ParkEasyTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Book Slot $slotNumber",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${widget.slot["zone_name"]} · ${widget.slot["location"]}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Booking Details", style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 14),
                          if (_vehicles.isEmpty)
                            const Text("No vehicles found for this user")
                          else
                            DropdownButtonFormField<int>(
                              initialValue: _selectedVehicleId,
                              decoration: const InputDecoration(
                                labelText: "Select Vehicle",
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              items: _vehicles.map((vehicle) {
                                return DropdownMenuItem<int>(
                                  value: _parseVehicleId(vehicle["vehicle_id"]),
                                  child: Text(
                                    "${vehicle["plate_number"]} (${vehicle["vehicle_type"]})",
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedVehicleId = value),
                            ),
                          const SizedBox(height: 14),
                          _timeTile(
                            title: "Start Time",
                            value: _displayDateTime(_startDateTime),
                            icon: Icons.schedule_rounded,
                            onTap: () => _pickDateTime(isStart: true),
                          ),
                          const SizedBox(height: 10),
                          _timeTile(
                            title: "End Time",
                            value: _displayDateTime(_endDateTime),
                            icon: Icons.event_available_rounded,
                            onTap: () => _pickDateTime(isStart: false),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              hasTimeRange
                                  ? "Estimated Amount: ₹${estimate.toStringAsFixed(2)}"
                                  : "Select start and end time to see fare estimate",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: ParkEasyTheme.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _book,
                              icon: const Icon(Icons.lock_clock_outlined),
                              label: const Text("Confirm Booking"),
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

  Widget _timeTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD7E2F0)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: ParkEasyTheme.primaryDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
