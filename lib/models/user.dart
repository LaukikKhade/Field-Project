class User {
  final String fullName;
  final String email;

  User({required this.fullName, required this.email});

  Map<String, dynamic> toMap() {
    return {'fullName': fullName, 'email': email};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(fullName: map['fullName'] ?? '', email: map['email'] ?? '');
  }
}
