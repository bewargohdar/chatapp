import 'package:chatapp/features/auth/domain/entity/user.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'id': super.id,
      'email': super.email,
    };
  }
}
