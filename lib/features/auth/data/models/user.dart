import 'package:chatapp/features/auth/domain/entity/user.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    super.username,
    super.image,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'id': super.id,
      'email': super.email,
      'username': super.username,
      'image': super.image,
    };
  }
}
