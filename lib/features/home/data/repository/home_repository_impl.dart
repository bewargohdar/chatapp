import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/home/data/datasource/home_data_source.dart';
import 'package:chatapp/features/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _dataSource;

  HomeRepositoryImpl(this._dataSource);

  @override
  Future<DataState<List<UserEntity>>> getUsers() {
    return _dataSource.getUsers();
  }
}
