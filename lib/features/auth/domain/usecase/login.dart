import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/auth/domain/repository/auth_repository.dart';

import '../../../../core/usecase/usecase.dart';

class Login implements UseCase<DataState<UserEntity>, LoginParams> {
  final AuthRepository repository;

  Login(this.repository);

  @override
  Future<DataState<UserEntity>> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams(this.email, this.password);
}
