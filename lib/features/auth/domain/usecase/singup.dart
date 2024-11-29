import 'package:chatapp/core/usecase/usecase.dart';

import '../../../../core/res/data_state.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';

class Singup implements UseCase<DataState<UserEntity>, SignupParams> {
  final AuthRepository repository;

  Singup(this.repository);

  @override
  Future<DataState<UserEntity>> call(SignupParams params) {
    return repository.signup(params.email, params.password);
  }
}

class SignupParams {
  final String email;
  final String password;

  SignupParams(this.email, this.password);
}
