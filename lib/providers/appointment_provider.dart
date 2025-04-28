// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../services/time_slot_service.dart';

class AppointmentProvider with ChangeNotifier {
  List<Appointment> _appointments = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TimeSlotService _timeSlotService = TimeSlotService();

  List<Appointment> get appointments => _appointments;

  void setAppointments(List<Appointment> appointments) {
    _appointments = appointments;
    notifyListeners();
  }

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }

  void removeAppointment(Appointment appointment) {
    _appointments.removeWhere((a) => a.id == appointment.id);
    notifyListeners();
  }

  void clearAppointments() {
    _appointments.clear();
    notifyListeners();
  }

  bool isTimeSlotBooked(DateTime date, String time, String stylistName) {
    return _appointments.any(
      (appointment) =>
          appointment.date.year == date.year &&
          appointment.date.month == date.month &&
          appointment.date.day == date.day &&
          appointment.time == time &&
          appointment.stylistName == stylistName,
    );
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final success = await _timeSlotService.cancelAppointment(
        userId,
        appointmentId,
      );

      if (success) {
        // Update the local state
        final updatedAppointments =
            _appointments.map((appointment) {
              if (appointment.id == appointmentId) {
                return Appointment(
                  id: appointment.id,
                  date: appointment.date,
                  time: appointment.time,
                  serviceName: appointment.serviceName,
                  stylistName: appointment.stylistName,
                  price: appointment.price,
                  status: 'cancelled',
                  createdAt: appointment.createdAt,
                  previousDate: appointment.previousDate,
                  previousTime: appointment.previousTime,
                  rescheduledAt: appointment.rescheduledAt,
                );
              }
              return appointment;
            }).toList();

        _appointments = updatedAppointments;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error cancelling appointment: $e');
      return false;
    }
  }
}
