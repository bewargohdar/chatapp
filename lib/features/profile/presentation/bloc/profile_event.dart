part of 'profile_bloc.dart';

@immutable
abstract class ProfileEvent {}

class LoadProfile extends ProfileEvent {}

class UpdateProfileUsername extends ProfileEvent {
  final String username;

  UpdateProfileUsername(this.username);
}

class UpdateProfileImage extends ProfileEvent {
  final XFile image;

  UpdateProfileImage(this.image);
}
