import '../../../../core/res/data_state.dart';
import '../entity/user.dart';

abstract class AuthRepository {
  Future<DataState<UserEntity>> login(String email, String password);
  Future<DataState<UserEntity>> signup(String email, String password);
}
