class UserEntity {
  final String id;
  final String email;
  final String? username;
  final String? image;

  UserEntity(
      {required this.id, required this.email, this.username, this.image});
}
