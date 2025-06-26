/// Un doctor es simplemente un usuario con rol “ROLE_DOCTOR”.
class Doctor {
  final int id;
  final String username;
  final String role;

  const Doctor({
    required this.id,
    required this.username,
    required this.role,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
    );
  }
}
