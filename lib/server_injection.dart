import 'package:chatapp/features/chat/data/data_source/chat_data_source.dart';
import 'package:chatapp/features/chat/data/repository/chat_repository_impl.dart';
import 'package:chatapp/features/chat/domain/repesotiry/chat_repository.dart';
import 'package:chatapp/features/chat/domain/usecase/get_message.dart';
import 'package:chatapp/features/chat/domain/usecase/send_message.dart';
import 'package:chatapp/features/chat/presentation/bloc/bloc/chat_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  sl.registerLazySingleton(() => GetMessageUsecase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));

  //repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));

  //datasource
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<ChatDataSource>(
      () => ChatDataSourceImpl(sl<FirebaseFirestore>()));
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  //bloc
  sl.registerFactory(() => AuthBloc(sl(), sl()));
  sl.registerFactory(() => ChatBloc(sl(), sl()));
}
