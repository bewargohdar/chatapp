import 'package:equatable/equatable.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';

abstract class HomeState extends Equatable {
  @override
  List<Object> get props => [];
}

class HomeInitialState extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {
  final List<UserEntity> users;

  HomeLoadedState(this.users);

  @override
  List<Object> get props => [users];
}

class HomeErrorState extends HomeState {
  final String message;

  HomeErrorState(this.message);

  @override
  List<Object> get props => [message];
}
