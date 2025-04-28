// ignore_for_file: avoid_print, unused_local_variable, unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print('----------------------------------------------------');
      print('Loading appointments for admin panel');
      print('Current date: ${DateTime.now().toString()}');
      print('Selected date: ${_selectedDay.toString()}');

      // Direct query to user_appointments collection
      print('\nQuerying user_appointments collection directly');
      try {
        final appointmentsSnapshot =
            await FirebaseFirestore.instance
                .collection('user_appointments')
                .get();

        print('Found ${appointmentsSnapshot.docs.length} appointments');

        final appointments = <Map<String, dynamic>>[];

        for (var doc in appointmentsSnapshot.docs) {
          final appointmentData = doc.data();
          print('Processing appointment: ${doc.id}');

          // Get appointment date
          DateTime? appointmentDate;
          if (appointmentData['date'] is Timestamp) {
            appointmentDate = (appointmentData['date'] as Timestamp).toDate();
          } else if (appointmentData['date'] is String) {
            try {
              // Parse ISO8601 string format
              appointmentDate = DateTime.parse(appointmentData['date']);
              print(
                'Successfully parsed date string: ${appointmentData['date']}',
              );
            } catch (e) {
              print(
                'Error parsing date string: ${appointmentData['date']} - $e',
              );
            }
          }

          if (appointmentDate == null) {
            print('Cannot parse date for appointment ${doc.id}, skipping');
            continue;
          }

          // Try to get user email
          String userEmail = 'Unknown User';
          String userName = 'Unknown User';
          if (appointmentData['userId'] != null) {
            try {
              // First try to get from the appointment data itself
              if (appointmentData['userEmail'] != null &&
                  appointmentData['userEmail'].toString().isNotEmpty) {
                userEmail = appointmentData['userEmail'];
              }
              if (appointmentData['userName'] != null &&
                  appointmentData['userName'].toString().isNotEmpty) {
                userName = appointmentData['userName'];
              }

              // If not found in appointment, check the users collection
              if (userEmail == 'Unknown User' || userName == 'Unknown User') {
                final userDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(appointmentData['userId'])
                        .get();

                if (userDoc.exists) {
                  final userData = userDoc.data();
                  if (userEmail == 'Unknown User') {
                    userEmail = userData?['email'] ?? 'No email';
                  }
                  if (userName == 'Unknown User') {
                    userName = userData?['fullName'] ?? 'Guest User';
                  }
                }
              }
            } catch (e) {
              print('Error fetching user: ${e.toString()}');
            }
          }

          final appointment = {
            ...appointmentData,
            'id': doc.id,
            'userEmail': userEmail,
            'userName': userName,
            'appointmentDate': appointmentDate,
          };

          appointments.add(appointment);
          print('Added appointment: ${doc.id}');
          print('  Date: ${appointmentDate.toString()}');
          print('  Time: ${appointmentData['time'] ?? 'Unknown'}');
          print('  Service: ${appointmentData['serviceName'] ?? 'Unknown'}');
          print('  Stylist: ${appointmentData['stylistName'] ?? 'Unknown'}');
          print('  Status: ${appointmentData['status'] ?? 'Unknown'}');
        }

        if (mounted) {
          setState(() {
            _appointments = appointments;
          });
        }

        print('Total appointments loaded: ${appointments.length}');
      } catch (e) {
        print('Error querying user_appointments: ${e.toString()}');
      }

      // If direct query failed, try the collection group query
      if (_appointments.isEmpty) {
        print(
          '\nDirect query failed or returned no results. Trying collection group query...',
        );
        try {
          final groupQuerySnapshot =
              await FirebaseFirestore.instance
                  .collectionGroup('user_appointments')
                  .get();

          print(
            'Collection group query found ${groupQuerySnapshot.docs.length} appointments',
          );

          final appointments = <Map<String, dynamic>>[];

          for (var doc in groupQuerySnapshot.docs) {
            final appointmentData = doc.data();
            print('Processing appointment: ${doc.id}');

            // Get appointment date
            DateTime? appointmentDate;
            if (appointmentData['date'] is Timestamp) {
              appointmentDate = (appointmentData['date'] as Timestamp).toDate();
            } else if (appointmentData['date'] is String) {
              try {
                appointmentDate = DateTime.parse(appointmentData['date']);
              } catch (e) {
                print('Error parsing date string: ${appointmentData['date']}');
              }
            }

            if (appointmentDate == null) {
              print('Cannot parse date for appointment ${doc.id}, skipping');
              continue;
            }

            // Try to get user ID from the document path
            String userId = 'unknown';
            String userEmail = 'Unknown User';
            String userName = 'Unknown User';

            try {
              // Parse the document reference path to extract userId
              final pathParts = doc.reference.path.split('/');
              if (pathParts.length >= 3) {
                // Path format should be "appointments/{userId}/user_appointments/{docId}"
                userId = pathParts[1];

                // First try to get from the appointment data itself
                if (appointmentData['userEmail'] != null &&
                    appointmentData['userEmail'].toString().isNotEmpty) {
                  userEmail = appointmentData['userEmail'];
                }
                if (appointmentData['userName'] != null &&
                    appointmentData['userName'].toString().isNotEmpty) {
                  userName = appointmentData['userName'];
                }

                // If not found in appointment, check the users collection
                if (userEmail == 'Unknown User' || userName == 'Unknown User') {
                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get();

                  if (userDoc.exists) {
                    final userData = userDoc.data();
                    if (userEmail == 'Unknown User') {
                      userEmail = userData?['email'] ?? 'No email';
                    }
                    if (userName == 'Unknown User') {
                      userName = userData?['fullName'] ?? 'Guest User';
                    }
                  }
                }
              }
            } catch (e) {
              print(
                'Error extracting user ID or fetching user: ${e.toString()}',
              );
            }

            final appointment = {
              ...appointmentData,
              'id': doc.id,
              'userId': userId,
              'userEmail': userEmail,
              'userName': userName,
              'appointmentDate': appointmentDate,
            };

            appointments.add(appointment);
            print('Added appointment: ${doc.id}');
            print('  Date: ${appointmentDate.toString()}');
            print('  Time: ${appointmentData['time'] ?? 'Unknown'}');
            print('  Service: ${appointmentData['serviceName'] ?? 'Unknown'}');
            print('  Stylist: ${appointmentData['stylistName'] ?? 'Unknown'}');
            print('  Status: ${appointmentData['status'] ?? 'Unknown'}');
          }

          if (mounted && appointments.isNotEmpty) {
            setState(() {
              _appointments = appointments;
            });
          }

          print('Total appointments loaded: ${appointments.length}');
        } catch (e) {
          print('Collection group query error: ${e.toString()}');
        }
      }

      // If both previous methods fail, try user-by-user
      if (_appointments.isEmpty) {
        print('\nTrying method 3: User-by-User Query');
        final usersSnapshot =
            await FirebaseFirestore.instance.collection('users').get();

        print('Found ${usersSnapshot.docs.length} users');

        final appointments = <Map<String, dynamic>>[];

        // For each user, get their appointments
        for (var userDoc in usersSnapshot.docs) {
          final userId = userDoc.id;
          final userData = userDoc.data();

          print(
            'Loading appointments for user: ${userData['email'] ?? 'Unknown Email'}',
          );

          try {
            // Get appointments for this user
            final appointmentsSnapshot =
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(userId)
                    .collection('user_appointments')
                    .get();

            print(
              'Found ${appointmentsSnapshot.docs.length} appointments for user: ${userData['email'] ?? 'Unknown Email'}',
            );

            // Process each appointment
            for (var appointmentDoc in appointmentsSnapshot.docs) {
              final appointmentData = appointmentDoc.data();

              // Get appointment date
              DateTime? appointmentDate;
              if (appointmentData['date'] is Timestamp) {
                appointmentDate =
                    (appointmentData['date'] as Timestamp).toDate();
              } else if (appointmentData['date'] is String) {
                try {
                  appointmentDate = DateTime.parse(appointmentData['date']);
                } catch (e) {
                  print(
                    'Error parsing date string: ${appointmentData['date']}',
                  );
                }
              }

              if (appointmentDate == null) {
                print(
                  'Cannot parse date for appointment ${appointmentDoc.id}, skipping',
                );
                continue;
              }

              // Add the appointment to our list
              String userName = 'Unknown User';
              String userEmail = 'Unknown User';

              // First try to get from the appointment data itself
              if (appointmentData['userEmail'] != null &&
                  appointmentData['userEmail'].toString().isNotEmpty) {
                userEmail = appointmentData['userEmail'];
              } else {
                userEmail = userData['email'] ?? 'No email';
              }

              if (appointmentData['userName'] != null &&
                  appointmentData['userName'].toString().isNotEmpty) {
                userName = appointmentData['userName'];
              } else {
                userName = userData['fullName'] ?? 'Guest User';
              }

              final appointment = {
                ...appointmentData,
                'id': appointmentDoc.id,
                'userId': userId,
                'userEmail': userEmail,
                'userName': userName,
                'appointmentDate': appointmentDate,
              };

              appointments.add(appointment);
              print('Added appointment: ${appointmentDoc.id}');
              print('  Date: ${appointmentDate.toString()}');
              print('  Time: ${appointmentData['time']}');
              print('  Service: ${appointmentData['serviceName']}');
              print('  Stylist: ${appointmentData['stylistName']}');
              print('  Status: ${appointmentData['status']}');
            }
          } catch (e) {
            print(
              'Error loading appointments for user $userId: ${e.toString()}',
            );
          }
        }

        if (mounted && appointments.isNotEmpty) {
          setState(() {
            _appointments = appointments;
          });
        }

        print('Total appointments loaded: ${appointments.length}');
      }

      // Print appointments for today
      final todayAppointments =
          _appointments.where((appointment) {
            final appointmentDate = appointment['appointmentDate'] as DateTime?;
            return appointmentDate != null &&
                isSameDay(appointmentDate, _selectedDay);
          }).toList();

      print(
        'Appointments for selected date (${_selectedDay.toString()}): ${todayAppointments.length}',
      );
      for (var appointment in todayAppointments) {
        print(
          '  ${appointment['id']} - ${appointment['stylistName']} - ${appointment['time']}',
        );
      }

      print('----------------------------------------------------');
    } catch (e) {
      print('Error loading appointments: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
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
      _focusedDay = focusedDay;
    });

    print('Selected day: ${_selectedDay.toString()}');

    final filteredCount =
        _appointments.where((appointment) {
          final appointmentDate = appointment['appointmentDate'] as DateTime?;
          return appointmentDate != null &&
              isSameDay(appointmentDate, _selectedDay);
        }).length;

    print('Filtered appointments count: $filteredCount');
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter appointments for the selected date using isSameDay
    final filteredAppointments =
        _appointments.where((appointment) {
          final appointmentDate = appointment['appointmentDate'] as DateTime?;
          return appointmentDate != null &&
              isSameDay(appointmentDate, _selectedDay);
        }).toList();

    final dateString = DateFormat('MMMM d, yyyy').format(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Reload Appointments',
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Calendar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TableCalendar(
                        firstDay: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDay, day),
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
              const SizedBox(height: 24),

              // Appointments Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'User Appointments',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_appointments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No appointments found in the database',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      else if (filteredAppointments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No appointments found for selected date',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = filteredAppointments[index];
                            final appointmentDate =
                                appointment['appointmentDate'] as DateTime;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User info section
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        right: 8,
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.blue,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  appointment['userName'] ??
                                                      appointment['fullName'] ??
                                                      'Guest User',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.email_outlined,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        appointment['userEmail'] ??
                                                            'No email',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                appointment['status'],
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              (appointment['status'] ??
                                                      'unknown')
                                                  .toString()
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  appointment['status'],
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Divider(height: 1),

                                    // Appointment details
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_month,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        DateFormat(
                                                          'MMM dd, yyyy',
                                                        ).format(
                                                          appointmentDate,
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      appointment['time'] ??
                                                          'Unknown',
                                                      style: TextStyle(
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.content_cut,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        appointment['serviceName'] ??
                                                            'Unknown',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_outline,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        appointment['stylistName'] ??
                                                            'Unknown',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Price display
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Price: ₹${appointment['price'] ?? '0.00'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (appointment['notes'] != null &&
                                              appointment['notes']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.note,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Notes: ${appointment['notes']}',
                                                    style: TextStyle(
                                                      color: Colors.grey[800],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase() ?? 'unknown') {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAppointmentDetails(Map<String, dynamic> appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Appointment Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Service', appointment['serviceName'] ?? 'N/A'),
          _buildDetailRow('Stylist', appointment['stylistName'] ?? 'N/A'),
          _buildDetailRow('Time', appointment['time'] ?? 'N/A'),
          _buildDetailRow(
            'Price',
            '₹${appointment['price']?.toStringAsFixed(2) ?? '0.00'}',
          ),
          _buildDetailRow('Status', appointment['status'] ?? 'N/A'),
          if (appointment['notes'] != null &&
              appointment['notes'].toString().isNotEmpty)
            _buildDetailRow('Notes', appointment['notes']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _updateAppointmentStatus(appointment['id'], 'confirmed');
                  Navigator.pop(context);
                },
                child: const Text('Confirm'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateAppointmentStatus(appointment['id'], 'cancelled');
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Future<void> _updateAppointmentStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_appointments')
          .doc(id)
          .update({'status': status});
      await _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
