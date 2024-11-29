import 'package:chatapp/features/auth/data/models/user.dart';
import 'package:chatapp/features/auth/domain/repository/auth_repository.dart';

import '../datasource/auth_remote_data_source.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserModel> login(String email, String password) {
    return remoteDataSource.login(email, password);
  }

  @override
  Future<UserModel> signup(String email, String password) {
    return remoteDataSource.signup(email, password);
  }
}
