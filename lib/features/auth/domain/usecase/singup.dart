import 'package:chatapp/core/usecase/usecase.dart';

import '../entity/user.dart';
import '../repository/auth_repository.dart';

class Singup implements UseCase<UserEntity, SignupParams> {
  final AuthRepository repository;

  Singup(this.repository);
  @override
  Future<UserEntity> call(SignupParams params) {
    return repository.signup(params.email, params.password);
  }
}

class SignupParams {
  final String email;
  final String password;

  SignupParams(this.email, this.password);
}
