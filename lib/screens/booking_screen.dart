// ignore_for_file: avoid_print, unused_field, unnecessary_null_comparison, prefer_final_fields, prefer_conditional_assignment, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import 'booking_confirmation_screen.dart';
import '../services/time_slot_service.dart';

class BookingScreen extends StatefulWidget {
  final String? stylistName;
  final String? serviceName;
  final double? servicePrice;

  const BookingScreen({
    super.key,
    this.stylistName,
    this.serviceName,
    this.servicePrice,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDay;
  String? _selectedTimeSlot;
  String? _selectedStylist;
  String? _selectedService;
  double? _selectedPrice;
  bool _isLoading = false;
  Map<String, bool> _bookedSlots = {};
  final TimeSlotService _timeSlotService = TimeSlotService();
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _stylists = [
    {
      'name': 'Alex Thompson',
      'specialty': 'Hair Coloring & Balayage',
      'description':
          'Expert in modern coloring techniques with 5 years of experience. Specializes in balayage, ombre, and color correction.',
      'experience': '5 years',
    },
    {
      'name': 'Marcus Lee',
      'specialty': 'Men\'s Haircutting',
      'description':
          'Master barber with expertise in classic and modern men\'s haircuts. Known for precise fades and beard grooming.',
      'experience': '8 years',
    },
    {
      'name': 'Sophia Martinez',
      'specialty': 'Women\'s Haircutting',
      'description':
          'Specializes in women\'s haircuts and styling. Expert in layered cuts, bobs, and pixie cuts.',
      'experience': '6 years',
    },
    {
      'name': 'Ryan Patel',
      'specialty': 'Hair Treatment & Care',
      'description':
          'Certified hair care specialist focusing on treatments, scalp health, and hair restoration.',
      'experience': '4 years',
    },
    {
      'name': 'Isabella Chen',
      'specialty': 'Hair Extensions',
      'description':
          'Expert in hair extensions and transformations. Specializes in tape-in, clip-in, and fusion methods.',
      'experience': '7 years',
    },
    {
      'name': 'Jordan Williams',
      'specialty': 'Creative Styling',
      'description':
          'Creative stylist specializing in unique cuts, styling, and hair art. Perfect for those looking for bold transformations.',
      'experience': '3 years',
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Haircut & Styling',
      'price': 50.00,
      'subServices': [
        {'name': 'Men\'s Haircut', 'price': 30.00},
        {'name': 'Women\'s Haircut', 'price': 40.00},
        {'name': 'Kids Haircut', 'price': 25.00},
        {'name': 'Bob Cut', 'price': 45.00},
        {'name': 'Pixie Cut', 'price': 45.00},
        {'name': 'Layered Cut', 'price': 50.00},
        {'name': 'Bang Trim', 'price': 20.00},
      ],
    },
    {
      'name': 'Hair Coloring',
      'price': 80.00,
      'subServices': [
        {'name': 'Full Color', 'price': 80.00},
        {'name': 'Highlights', 'price': 100.00},
        {'name': 'Balayage', 'price': 150.00},
        {'name': 'Ombre', 'price': 120.00},
        {'name': 'Root Touch-up', 'price': 60.00},
        {'name': 'Color Correction', 'price': 200.00},
      ],
    },
    {
      'name': 'Hair Treatment',
      'price': 60.00,
      'subServices': [
        {'name': 'Deep Conditioning', 'price': 40.00},
        {'name': 'Keratin Treatment', 'price': 150.00},
        {'name': 'Hair Spa', 'price': 70.00},
        {'name': 'Scalp Treatment', 'price': 50.00},
        {'name': 'Hair Mask', 'price': 45.00},
      ],
    },
    {'name': 'Hair Wash & Blow Dry', 'price': 40.00},
    {'name': 'Hair Extensions', 'price': 200.00},
    {'name': 'Hair Spa', 'price': 70.00},
    {'name': 'Hair Trim', 'price': 30.00},
    {'name': 'Hair Consultation', 'price': 20.00},
  ];

  final List<String> _timeSlots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (widget.stylistName != null) {
      setState(() {
        _selectedStylist = widget.stylistName;
        _selectedService = widget.serviceName ?? 'Haircut & Styling';
        _selectedPrice = widget.servicePrice ?? 50.00;
      });
      _loadBookedSlots();
    }
  }

  Future<void> _loadBookedSlots() async {
    if (_selectedDay == null || _selectedStylist == null) return;

    setState(() {
      _isLoading = true;
      _selectedTimeSlot = null;
      _bookedSlots.clear();
    });

    try {
      print('=============================================');
      print(
        'Loading slots for stylist: $_selectedStylist, date: $_selectedDay',
      );

      // First initialize all slots as available
      for (String timeSlot in _timeSlots) {
        _bookedSlots[timeSlot] = false;
      }

      // Normalize the selected date for consistent comparison
      final normalizedSelectedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      print('Normalized selected date: $normalizedSelectedDate');

      // Check for locks first
      for (String timeSlot in _timeSlots) {
        try {
          final lockRef = FirebaseFirestore.instance
              .collection('locks')
              .doc(
                '${_selectedStylist}_${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}_$timeSlot',
              );

          final lockDoc = await lockRef.get();
          if (lockDoc.exists) {
            // Check if the lock is recent (less than 10 minutes old)
            final lockData = lockDoc.data();
            if (lockData != null && lockData['lockedAt'] is Timestamp) {
              final lockTime = (lockData['lockedAt'] as Timestamp).toDate();
              final now = DateTime.now();
              final lockAge = now.difference(lockTime).inMinutes;

              // If lock is older than 10 minutes, consider it stale and delete it
              if (lockAge > 10) {
                print('Found stale lock for $timeSlot, deleting it');
                await lockRef.delete();
              } else {
                print('Found active lock for $timeSlot, marking as booked');
                _bookedSlots[timeSlot] = true;
              }
            }
          }
        } catch (e) {
          print('Error checking lock for time slot $timeSlot: $e');
        }
      }

      // Query for existing appointments on the selected date
      final querySnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('user_appointments')
              .where('stylistName', isEqualTo: _selectedStylist)
              .where('status', isEqualTo: 'confirmed')
              .get();

      print(
        'Found ${querySnapshot.docs.length} appointments for stylist $_selectedStylist',
      );

      // Create a set of booked time slots for the selected date
      final Set<String> bookedTimeSlots = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        DateTime? appointmentDate;

        if (data['date'] is Timestamp) {
          appointmentDate = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          try {
            // Parse ISO8601 string format
            appointmentDate = DateTime.parse(data['date'].toString());
            print('Successfully parsed date string: ${data['date']}');
          } catch (e) {
            print('Error parsing date string: ${data['date']} - $e');
            continue;
          }
        } else {
          print('Unknown date format: ${data['date']}');
          continue;
        }

        if (appointmentDate == null) {
          print('Cannot parse date for appointment ${doc.id}, skipping');
          continue;
        }

        // Normalize appointment date for consistent comparison
        final normalizedAppointmentDate = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
        );

        print('Checking appointment: ${doc.id}');
        print('  Date: $normalizedAppointmentDate');
        print('  Time: ${data['time']}');
        print(
          '  Is same date: ${normalizedAppointmentDate.isAtSameMomentAs(normalizedSelectedDate)}',
        );

        if (normalizedAppointmentDate.year == normalizedSelectedDate.year &&
            normalizedAppointmentDate.month == normalizedSelectedDate.month &&
            normalizedAppointmentDate.day == normalizedSelectedDate.day) {
          final timeSlot = data['time'];
          if (timeSlot != null && _timeSlots.contains(timeSlot)) {
            print('  Adding booked time slot: $timeSlot');
            bookedTimeSlots.add(timeSlot);
          }
        }
      }

      // Also check the direct user_appointments collection
      try {
        final directQuery =
            await FirebaseFirestore.instance
                .collection('user_appointments')
                .where('stylistName', isEqualTo: _selectedStylist)
                .where('status', isEqualTo: 'confirmed')
                .get();

        print('Found ${directQuery.docs.length} appointments in direct query');

        for (var doc in directQuery.docs) {
          final data = doc.data();
          DateTime? appointmentDate;

          if (data['date'] is Timestamp) {
            appointmentDate = (data['date'] as Timestamp).toDate();
          } else if (data['date'] is String) {
            try {
              // Parse ISO8601 string format
              appointmentDate = DateTime.parse(data['date'].toString());
              print('Successfully parsed date string: ${data['date']}');
            } catch (e) {
              print('Error parsing date string: ${data['date']} - $e');
              continue;
            }
          } else {
            print('Unknown date format: ${data['date']}');
            continue;
          }

          if (appointmentDate == null) {
            print('Cannot parse date for appointment ${doc.id}, skipping');
            continue;
          }

          // Normalize appointment date
          final normalizedAppointmentDate = DateTime(
            appointmentDate.year,
            appointmentDate.month,
            appointmentDate.day,
          );

          if (normalizedAppointmentDate.year == normalizedSelectedDate.year &&
              normalizedAppointmentDate.month == normalizedSelectedDate.month &&
              normalizedAppointmentDate.day == normalizedSelectedDate.day) {
            final timeSlot = data['time'];
            if (timeSlot != null && _timeSlots.contains(timeSlot)) {
              print('  Adding booked time slot from direct query: $timeSlot');
              bookedTimeSlots.add(timeSlot);
            }
          }
        }
      } catch (e) {
        print('Error in direct query: $e');
      }

      print(
        'Booked slots for date $normalizedSelectedDate: ${bookedTimeSlots.join(", ")}',
      );

      // Update the UI with booked slots
      if (mounted) {
        setState(() {
          for (String timeSlot in _timeSlots) {
            // Mark as booked if either found in appointments or has an active lock
            if (bookedTimeSlots.contains(timeSlot)) {
              _bookedSlots[timeSlot] = true;
            }
            print('Time slot $timeSlot is booked: ${_bookedSlots[timeSlot]}');
          }
        });
      }

      print('=============================================');
    } catch (e) {
      print('Error loading time slots: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load available time slots: $e'),
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedTimeSlot = null; // Reset time slot when date changes
    });
    _loadBookedSlots();
  }

  void _onStylistSelected(String? stylist) {
    if (stylist != _selectedStylist) {
      setState(() {
        _selectedStylist = stylist;
        _selectedTimeSlot = null; // Reset time slot when stylist changes
        // Set default service and price when stylist is selected
        if (stylist != null) {
          _selectedService = widget.serviceName ?? 'Haircut & Styling';
          _selectedPrice = widget.servicePrice ?? 50.00;
        } else {
          _selectedService = null;
          _selectedPrice = null;
        }
      });
      if (stylist != null) {
        _loadBookedSlots();
      }
    }
  }

  Widget _buildTimeSlots() {
    if (_selectedDay == null) {
      return const Center(child: Text('Please select a date first'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Create a 3x3 grid of time slots
    final timeSlots = [
      ['9:00 AM', '10:00 AM', '11:00 AM'],
      ['12:00 PM', '1:00 PM', '2:00 PM'],
      ['3:00 PM', '4:00 PM', '5:00 PM'],
    ];

    return Column(
      children:
          timeSlots.map((row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  row.map((timeSlot) {
                    final isBooked = _bookedSlots[timeSlot] ?? false;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ChoiceChip(
                          label: Text(
                            timeSlot,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          selected: _selectedTimeSlot == timeSlot,
                          onSelected:
                              isBooked
                                  ? null
                                  : (selected) {
                                    setState(() {
                                      _selectedTimeSlot =
                                          selected ? timeSlot : null;
                                      if (_selectedService == null) {
                                        _selectedService =
                                            widget.serviceName ??
                                            'Haircut & Styling';
                                      }
                                      if (_selectedPrice == null) {
                                        _selectedPrice =
                                            widget.servicePrice ?? 50.00;
                                      }
                                    });
                                  },
                          disabledColor: Colors.grey[300],
                          labelStyle: TextStyle(
                            color:
                                isBooked
                                    ? Colors.grey[600]
                                    : _selectedTimeSlot == timeSlot
                                    ? Colors.white
                                    : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          }).toList(),
    );
  }

  // Add this method to check if all fields are selected
  bool _areAllFieldsSelected() {
    return _selectedStylist != null &&
        _selectedDay != null &&
        _selectedTimeSlot != null &&
        _selectedService != null &&
        _selectedPrice != null;
  }

  Future<void> _handleBooking() async {
    if (!_areAllFieldsSelected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book an appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Try to get the user's full name
      String? userName;
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          userName = userDoc.data()?['fullName'];
        }
      } catch (e) {
        print('Error getting user profile: $e');
      }

      // Check availability again before booking
      final isAvailable = await _timeSlotService.isSlotAvailable(
        _selectedStylist!,
        _selectedDay!,
        _selectedTimeSlot!,
      );

      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This time slot is no longer available'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Try to book the time slot with all appointment details
      final slotBooked = await _timeSlotService.bookTimeSlot(
        user.uid,
        _selectedDay!,
        _selectedTimeSlot!,
        _selectedService!,
        _selectedStylist!,
        _selectedPrice!,
        userName: userName,
        notes: _notesController.text.trim(),
      );

      if (!slotBooked) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to book the time slot'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Fetch the newly created appointment
      context.read<AppointmentProvider>().clearAppointments();
      await _loadAppointments();

      if (mounted) {
        // Navigate to confirmation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BookingConfirmationScreen(
                  selectedDate: _selectedDay!,
                  selectedTime: _selectedTimeSlot!,
                  stylistName: _selectedStylist!,
                  serviceName: _selectedService!,
                  price: _selectedPrice!,
                ),
          ),
        );
      }
    } catch (e) {
      print('Error during booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during booking: $e'),
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

  Future<void> _loadAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(user.uid)
              .collection('user_appointments')
              .where('status', isEqualTo: 'confirmed')
              .get();

      final appointments =
          snapshot.docs.map((doc) {
            final data = doc.data();

            // Handle date stored as a string
            if (data['date'] is String) {
              try {
                DateTime date = DateTime.parse(data['date']);
                data['date'] = date;
              } catch (e) {
                print('Error parsing date from string: ${data['date']} - $e');
              }
            }

            return Appointment.fromMap(doc.id, data);
          }).toList();

      if (mounted) {
        context.read<AppointmentProvider>().setAppointments(appointments);
      }
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedStylist == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Stylist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _stylists
                                .map(
                                  (stylist) => ChoiceChip(
                                    label: Text(stylist['name']),
                                    selected:
                                        _selectedStylist == stylist['name'],
                                    onSelected:
                                        (selected) => _onStylistSelected(
                                          selected ? stylist['name'] : null,
                                        ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_selectedStylist != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 30)),
                        focusedDay: _selectedDay ?? DateTime.now(),
                        selectedDayPredicate:
                            (day) =>
                                _selectedDay != null &&
                                isSameDay(_selectedDay!, day),
                        onDaySelected: _onDaySelected,
                        calendarStyle: const CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTimeSlots(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            if (_selectedStylist != null && _selectedDay != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add any special requests or notes for the stylist',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'E.g., Specific hair concerns, preferences, or any other details...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading || !_areAllFieldsSelected()
                        ? null
                        : _handleBooking,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
