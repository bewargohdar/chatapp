import 'package:get_it/get_it.dart';

import 'features/auth/data/datasource/auth_remote_data_source.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/domain/repository/auth_repository.dart';
import 'features/auth/domain/usecase/login.dart';
import 'features/auth/domain/usecase/singup.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

void init() {
  //usecases
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Singup(sl()));

  //repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  //datasource
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl());

  //bloc
  sl.registerFactory(() => AuthBloc(sl(), sl()));
}
