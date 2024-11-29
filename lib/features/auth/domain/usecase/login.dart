import 'package:chatapp/core/usecase/usecase.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

import '../repository/auth_repository.dart';

class Login implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  Login(this.repository);
  @override
  Future<UserEntity> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams(this.email, this.password);
}
