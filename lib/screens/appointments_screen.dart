// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../services/time_slot_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final TimeSlotService _timeSlotService = TimeSlotService();
  bool _isLoading = false;

  // Helper method to check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(user.uid)
              .collection('user_appointments')
              .get();

      final appointments =
          snapshot.docs
              .map((doc) => Appointment.fromMap(doc.id, doc.data()))
              .toList();

      // Sort appointments by date: upcoming dates first (closest to today at the top)
      // For past dates, show most recent first
      final now = DateTime.now();
      appointments.sort((a, b) {
        // First, separate past and future appointments
        bool aIsFuture = a.date.isAfter(now) || _isSameDay(a.date, now);
        bool bIsFuture = b.date.isAfter(now) || _isSameDay(b.date, now);

        // If one is future and one is past, future comes first
        if (aIsFuture && !bIsFuture) return -1;
        if (!aIsFuture && bIsFuture) return 1;

        // If both are future, closest date comes first
        if (aIsFuture && bIsFuture) {
          return a.date.compareTo(b.date);
        }

        // If both are past, most recent comes first
        return b.date.compareTo(a.date);
      });

      if (mounted) {
        context.read<AppointmentProvider>().setAppointments(appointments);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load appointments')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await _timeSlotService.cancelAppointment(
        user.uid,
        appointment.id,
      );

      if (success) {
        await _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel appointment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : appointments.isEmpty
              ? const Center(
                child: Text(
                  'No appointments found',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                appointment.serviceName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      appointment.status == 'confirmed'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  appointment.status.toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        appointment.status == 'confirmed'
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${DateFormat('MMM dd, yyyy').format(appointment.date)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Time: ${appointment.time}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Stylist: ${appointment.stylistName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Price: ₹${appointment.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (appointment.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Notes:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment.notes!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                          if (appointment.status == 'confirmed') ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    () => _cancelAppointment(appointment),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
