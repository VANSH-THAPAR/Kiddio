import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme.dart';
import '../../auth/models/user_model.dart';
import '../../bookings/providers/bookings_provider.dart';
import '../../auth/providers/auth_controller.dart'; // Import Auth

import 'package:go_router/go_router.dart'; // Import GoRouter

class SitterDetailsScreen extends ConsumerStatefulWidget {

  final UserModel sitter;

  const SitterDetailsScreen({super.key, required this.sitter});


  @override
  ConsumerState<SitterDetailsScreen> createState() => _SitterDetailsScreenState();
}

class _SitterDetailsScreenState extends ConsumerState<SitterDetailsScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _notesController = TextEditingController();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  void _confirmBooking() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) return;

    final startDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    
    final endDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _endTime!.hour, _endTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final durationHours = endDateTime.difference(startDateTime).inMinutes / 60.0;
    final totalPrice = durationHours * (widget.sitter.hourlyRate ?? 0);

    try {
      await ref.read(bookingsControllerProvider).createBooking(
        sitterId: widget.sitter.uid,
        sitterName: widget.sitter.name,
        startTime: startDateTime,
        endTime: endDateTime,
        totalPrice: totalPrice,
        notes: _notesController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isParent = user?.role == UserRole.parent;

    return Scaffold(
      appBar: AppBar(title: Text(widget.sitter.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(widget.sitter.profileImage ?? ''),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "\$${widget.sitter.hourlyRate?.toStringAsFixed(0) ?? 'N/A'}/hr",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isParent)
                    ElevatedButton.icon(
                      onPressed: () {
                         context.push('/chat/${widget.sitter.uid}', extra: widget.sitter);
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Chat with Sitter"),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Bio
            Text("About Me", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.sitter.bio ?? "No bio available."),
            const SizedBox(height: 24),

            // Booking Section (Only for Parents)
            if (isParent)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                 color: Colors.grey[50], 
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.grey[200]!)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Book a Session", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Iconsax.calendar),
                    title: Text(_selectedDate == null 
                        ? "Select Date" 
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
                    onTap: _pickDate,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tileColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Iconsax.clock),
                          title: Text(_startTime?.format(context) ?? "Start"),
                          onTap: () => _pickTime(true),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Iconsax.clock),
                          title: Text(_endTime?.format(context) ?? "End"),
                          onTap: () => _pickTime(false),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: "Notes (optional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmBooking,
                      child: const Text("Confirm Booking"),
                    ),
                  )
                ],
              ),
            )
            else
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Switch to a Parent account to book sessions with this sitter.",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
