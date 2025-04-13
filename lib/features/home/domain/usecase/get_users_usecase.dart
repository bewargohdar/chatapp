import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/core/usecase/usecase.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/home/domain/repository/home_repository.dart';

class GetUsersUseCase extends UseCase<DataState<List<UserEntity>>, void> {
  final HomeRepository _repository;

  GetUsersUseCase(this._repository);

  @override
  Future<DataState<List<UserEntity>>> call(void params) {
    return _repository.getUsers();
  }
}
