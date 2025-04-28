// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isSlotAvailable(
    String stylistId,
    DateTime date,
    String time,
  ) async {
    try {
      print('=============================================');
      print(
        'Checking availability for $stylistId on ${date.toString()} at $time',
      );

      // Normalize the date to remove time component
      final normalizedDate = DateTime(date.year, date.month, date.day);
      print('Normalized date: ${normalizedDate.toString()}');

      // First check if there's a lock for this time slot
      final lockRef = _firestore
          .collection('locks')
          .doc('${stylistId}_${date.year}-${date.month}-${date.day}_$time');

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
            print('Found stale lock, deleting it');
            await lockRef.delete();
          } else {
            print('Found active lock, slot is not available');
            print('=============================================');
            return false;
          }
        }
      }

      // Query for existing appointments on the same date and time
      final querySnapshot =
          await _firestore
              .collectionGroup('user_appointments')
              .where('stylistName', isEqualTo: stylistId)
              .where('time', isEqualTo: time)
              .where('status', isEqualTo: 'confirmed')
              .get();

      print('Found ${querySnapshot.docs.length} potential conflicts');

      // Check if any appointment exists for the same date
      for (var doc in querySnapshot.docs) {
        final appointmentData = doc.data();
        DateTime appointmentDate;

        if (appointmentData['date'] is Timestamp) {
          appointmentDate = (appointmentData['date'] as Timestamp).toDate();
        } else if (appointmentData['date'] is String) {
          appointmentDate = DateTime.parse(appointmentData['date']);
        } else {
          print('Unknown date format: ${appointmentData['date']}');
          continue;
        }

        // Normalize appointment date
        appointmentDate = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
        );

        print('Comparing with appointment date: ${appointmentDate.toString()}');
        print('Same date check: ${appointmentDate == normalizedDate}');

        if (appointmentDate.year == normalizedDate.year &&
            appointmentDate.month == normalizedDate.month &&
            appointmentDate.day == normalizedDate.day) {
          print('Found conflicting appointment: ${doc.id}');
          print('Slot is NOT available');
          print('=============================================');
          return false;
        }
      }

      // Also check the direct user_appointments collection
      try {
        final directQuery =
            await _firestore
                .collection('user_appointments')
                .where('stylistName', isEqualTo: stylistId)
                .where('time', isEqualTo: time)
                .where('status', isEqualTo: 'confirmed')
                .get();

        print(
          'Found ${directQuery.docs.length} potential conflicts in direct query',
        );

        for (var doc in directQuery.docs) {
          final appointmentData = doc.data();
          DateTime appointmentDate;

          if (appointmentData['date'] is Timestamp) {
            appointmentDate = (appointmentData['date'] as Timestamp).toDate();
          } else if (appointmentData['date'] is String) {
            appointmentDate = DateTime.parse(appointmentData['date']);
          } else {
            print('Unknown date format: ${appointmentData['date']}');
            continue;
          }

          // Normalize appointment date
          appointmentDate = DateTime(
            appointmentDate.year,
            appointmentDate.month,
            appointmentDate.day,
          );

          if (appointmentDate.year == normalizedDate.year &&
              appointmentDate.month == normalizedDate.month &&
              appointmentDate.day == normalizedDate.day) {
            print('Found conflicting appointment in direct query: ${doc.id}');
            print('Slot is NOT available');
            print('=============================================');
            return false;
          }
        }
      } catch (e) {
        print('Error in direct query: $e');
      }

      print('Slot is available');
      print('=============================================');
      return true;
    } catch (e) {
      print('Error checking slot availability: $e');
      print('Returning false due to error');
      print('=============================================');
      return false; // Return false on error to prevent double bookings
    }
  }

  Future<bool> bookTimeSlot(
    String userId,
    DateTime date,
    String time,
    String serviceName,
    String stylistName,
    double price, {
    String? userName,
    String? notes,
  }) async {
    try {
      print('=============================================');
      print(
        'Attempting to book slot for $stylistName on ${date.toString()} at $time',
      );
      print('userId: $userId, service: $serviceName, price: $price');
      if (notes?.isNotEmpty == true) {
        print('Additional notes: $notes');
      }

      // Try to get user's full name if not provided
      String fullName = userName ?? '';
      if (fullName.isEmpty) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            fullName = userDoc.data()?['fullName'] ?? 'Guest User';
          }
        } catch (e) {
          print('Error getting user name: $e');
          fullName = 'Guest User';
        }
      }

      // Check availability first
      final isAvailable = await isSlotAvailable(stylistName, date, time);
      if (!isAvailable) {
        print('Slot is not available, cannot book');
        print('=============================================');
        return false;
      }

      // Create the appointment document reference
      final appointmentRef =
          _firestore
              .collection('appointments')
              .doc(userId)
              .collection('user_appointments')
              .doc();

      print('Created appointment reference: ${appointmentRef.path}');

      // Create a lock document reference
      final lockRef = _firestore
          .collection('locks')
          .doc('${stylistName}_${date.year}-${date.month}-${date.day}_$time');

      // Start a transaction to handle the booking atomically
      await _firestore.runTransaction((transaction) async {
        // Check if there's a lock and if it's stale
        final lockDoc = await transaction.get(lockRef);
        if (lockDoc.exists) {
          final lockData = lockDoc.data();
          if (lockData != null && lockData['lockedAt'] is Timestamp) {
            final lockTime = (lockData['lockedAt'] as Timestamp).toDate();
            final now = DateTime.now();
            final lockAge = now.difference(lockTime).inMinutes;

            // If lock is not stale (less than 10 minutes old), abort
            if (lockAge <= 10) {
              print('Found active lock, aborting transaction');
              throw Exception('Time slot is locked');
            }
          }
        }

        // Create/update the lock
        transaction.set(lockRef, {'lockedAt': FieldValue.serverTimestamp()});

        // Create the appointment
        transaction.set(appointmentRef, {
          'date': date,
          'time': time,
          'serviceName': serviceName,
          'stylistName': stylistName,
          'price': price,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          'userName': fullName,
          if (notes?.isNotEmpty == true) 'notes': notes,
        });
      });

      print('Successfully created appointment and lock');

      // Create a record in the user_appointments collection for easier querying
      try {
        await _firestore.collection('user_appointments').doc().set({
          'userId': userId,
          'appointmentId': appointmentRef.id,
          'date': date,
          'time': time,
          'serviceName': serviceName,
          'stylistName': stylistName,
          'price': price,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          'userName': fullName,
          if (notes?.isNotEmpty == true) 'notes': notes,
        });
        print('Successfully created user_appointments record');
      } catch (e) {
        print('Error creating user_appointments record: $e');
        // Don't fail the whole booking if this fails
      }

      print('Booking completed successfully');
      print('=============================================');
      return true;
    } catch (e) {
      print('Error booking time slot: $e');
      print('=============================================');
      return false;
    }
  }

  Future<bool> rescheduleAppointment(
    String userId,
    String appointmentId,
    DateTime newDate,
    String newTime,
    String stylistId,
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      // Check if the new slot is available
      final isAvailable = await isSlotAvailable(stylistId, newDate, newTime);
      if (!isAvailable) {
        print('New time slot is not available');
        return false;
      }

      // Get appointment reference
      final appointmentRef = _firestore
          .collection('appointments')
          .doc(userId)
          .collection('user_appointments')
          .doc(appointmentId);

      // Convert dates to Timestamp for Firestore
      final newDateTimestamp = Timestamp.fromDate(newDate);
      final previousDate =
          appointmentData['date'] is Timestamp
              ? (appointmentData['date'] as Timestamp).toDate()
              : DateTime.parse(appointmentData['date'].toString());

      // Use a transaction for atomic operations
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get the current appointment data
        final appointmentDoc = await transaction.get(appointmentRef);
        if (!appointmentDoc.exists) {
          print('Appointment not found');
          return false;
        }

        // Update the appointment
        transaction.update(appointmentRef, {
          'date': newDateTimestamp,
          'time': newTime,
          'status': 'confirmed',
          'rescheduledAt': FieldValue.serverTimestamp(),
          'previousDate': previousDate,
          'previousTime': appointmentData['time'],
        });

        print('Successfully rescheduled appointment');
        return true;
      });
    } catch (e) {
      print('Error rescheduling appointment: $e');
      return false;
    }
  }

  Future<bool> cancelAppointment(String userId, String appointmentId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(userId)
          .collection('user_appointments')
          .doc(appointmentId)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('Error cancelling appointment: $e');
      return false;
    }
  }

  Future<void> releaseTimeSlot(
    String stylistId,
    DateTime date,
    String time,
  ) async {
    try {
      final formattedDate =
          DateTime(
            date.year,
            date.month,
            date.day,
          ).toIso8601String().split('T')[0];
      await _firestore
          .collection('timeSlots')
          .doc(stylistId)
          .collection('dates')
          .doc(formattedDate)
          .collection('slots')
          .doc(time)
          .delete();
    } catch (e) {
      print('Error releasing time slot: $e');
    }
  }

  Future<void> initializeTimeSlots(String stylistId) async {
    try {
      print('Initializing time slots for stylist: $stylistId');

      // Get today's date and create slots for the next 30 days
      final today = DateTime.now();
      final timeSlots = [
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

      for (int i = 0; i < 30; i++) {
        final date = today.add(Duration(days: i));
        final formattedDate = date.toIso8601String().split('T')[0];

        // Create a batch write for all time slots
        final batch = _firestore.batch();

        for (String time in timeSlots) {
          final slotRef = _firestore
              .collection('timeSlots')
              .doc(stylistId)
              .collection('dates')
              .doc(formattedDate)
              .collection('slots')
              .doc(time);

          batch.set(slotRef, {
            'createdAt': FieldValue.serverTimestamp(),
            'isAvailable': true,
          });
        }

        await batch.commit();
      }

      print('Successfully initialized time slots for stylist: $stylistId');
    } catch (e) {
      print('Error initializing time slots: $e');
      rethrow;
    }
  }
}
