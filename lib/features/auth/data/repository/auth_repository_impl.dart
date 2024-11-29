import 'package:chatapp/features/auth/domain/repository/auth_repository.dart';
import '../../../../core/res/data_state.dart';
import '../../domain/entity/user.dart';
import '../datasource/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<DataState<UserEntity>> login(String email, String password) async {
    final result = await remoteDataSource.login(email, password);
    if (result is DataSuccess) {
      return DataSuccess(
        UserEntity(id: result.data!.id, email: result.data!.email),
      );
    } else if (result is DataError) {
      return DataError(result.error!);
    }
    return DataError(Exception('Unexpected error'));
  }

  @override
  Future<DataState<UserEntity>> signup(String email, String password) async {
    final result = await remoteDataSource.signup(email, password);
    if (result is DataSuccess) {
      return DataSuccess(
        UserEntity(id: result.data!.id, email: result.data!.email),
      );
    } else if (result is DataError) {
      return DataError(result.error!);
    }
    return DataError(Exception('Unexpected error'));
  }
}
