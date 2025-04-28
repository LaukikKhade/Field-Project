// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/appointment.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // User operations
  Future<void> saveUser(User user) async {
    await _firestore.collection('users').doc(user.email).set(user.toMap());
  }

  Future<User?> getUser(String email) async {
    final doc = await _firestore.collection('users').doc(email).get();
    if (doc.exists) {
      return User.fromMap(doc.data()!);
    }
    return null;
  }

  // Appointment operations
  Future<void> saveAppointment(
    String userEmail,
    Appointment appointment,
  ) async {
    await _firestore
        .collection('appointments')
        .doc(userEmail)
        .collection('user_appointments')
        .doc(appointment.id)
        .set(appointment.toMap());
  }

  Future<List<Appointment>> getUserAppointments(String userEmail) async {
    final snapshot =
        await _firestore
            .collection('appointments')
            .doc(userEmail)
            .collection('user_appointments')
            .get();

    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteAppointment(String userEmail, String appointmentId) async {
    await _firestore
        .collection('appointments')
        .doc(userEmail)
        .collection('user_appointments')
        .doc(appointmentId)
        .delete();
  }

  // Check if time slot is available
  Future<bool> isTimeSlotAvailable(
    String userEmail,
    DateTime date,
    String time,
    String stylistName,
  ) async {
    final appointments = await getUserAppointments(userEmail);
    return !appointments.any(
      (appointment) =>
          appointment.date.year == date.year &&
          appointment.date.month == date.month &&
          appointment.date.day == date.day &&
          appointment.time == time &&
          appointment.stylistName == stylistName,
    );
  }
}
