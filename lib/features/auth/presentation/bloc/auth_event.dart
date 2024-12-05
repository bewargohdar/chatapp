part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin(this.email, this.password);
}

final class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final XFile image;

  AuthRegister(this.email, this.password, this.username, this.image);
}

final class AuthLogout extends AuthEvent {}

final class AuthCheck extends AuthEvent {}
