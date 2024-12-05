import 'package:chatapp/core/usecase/usecase.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/res/data_state.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';

class Singup implements UseCase<DataState<UserEntity>, SignupParams> {
  final AuthRepository repository;

  Singup(this.repository);

  @override
  Future<DataState<UserEntity>> call(SignupParams params) {
    return repository.signup(
        params.email, params.password, params.username, params.image);
  }
}

class SignupParams {
  final String email;
  final String password;
  final String username;
  final XFile image;

  SignupParams(this.email, this.password, this.username, this.image);
}
