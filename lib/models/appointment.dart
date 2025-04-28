import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final DateTime date;
  final String time;
  final String serviceName;
  final String stylistName;
  final double price;
  final String status;
  final DateTime? createdAt;
  final DateTime? previousDate;
  final String? previousTime;
  final DateTime? rescheduledAt;
  final String? notes;

  Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.serviceName,
    required this.stylistName,
    required this.price,
    this.status = 'confirmed',
    this.createdAt,
    this.previousDate,
    this.previousTime,
    this.rescheduledAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'time': time,
      'serviceName': serviceName,
      'stylistName': stylistName,
      'price': price,
      'status': status,
      'previousDate': previousDate,
      'previousTime': previousTime,
      'rescheduledAt': rescheduledAt,
      if (notes != null) 'notes': notes,
    };
  }

  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      date:
          map['date'] is Timestamp
              ? (map['date'] as Timestamp).toDate()
              : DateTime.parse(map['date'].toString()),
      time: map['time'] ?? '',
      serviceName: map['serviceName'] ?? '',
      stylistName: map['stylistName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'confirmed',
      createdAt:
          map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : null,
      previousDate:
          map['previousDate'] is Timestamp
              ? (map['previousDate'] as Timestamp).toDate()
              : map['previousDate'] != null
              ? DateTime.parse(map['previousDate'].toString())
              : null,
      previousTime: map['previousTime'],
      rescheduledAt:
          map['rescheduledAt'] is Timestamp
              ? (map['rescheduledAt'] as Timestamp).toDate()
              : null,
      notes: map['notes'],
    );
  }

  // Helper method to check if an appointment conflicts with another
  bool conflictsWith(Appointment other) {
    return date.year == other.date.year &&
        date.month == other.date.month &&
        date.day == other.date.day &&
        time == other.time &&
        stylistName == other.stylistName;
  }
}
