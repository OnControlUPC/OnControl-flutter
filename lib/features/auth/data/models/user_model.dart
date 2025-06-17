// lib/features/auth/data/models/user_model.dart

import '../../domain/entities/user.dart';

class UserModel extends User {
  final String token;
  final String role;

  UserModel({
    required String id,
    required String name,
    required this.token,
    required this.role,
  }) : super(id: id, name: name);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),           // lee id directo
      name: json['username'],               // lee username directo
      token: json['token'],                 // lee token
      role: json['role'],                   // lee role
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': name,
        'token': token,
        'role': role,
      };
}
