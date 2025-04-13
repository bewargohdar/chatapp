import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

abstract class HomeRepository {
  Future<DataState<List<UserEntity>>> getUsers();
}
