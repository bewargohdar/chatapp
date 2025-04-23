import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadUsersEvent extends HomeEvent {}

class RefreshUsersEvent extends HomeEvent {}

class SearchUsersEvent extends HomeEvent {
  final String query;

  SearchUsersEvent(this.query);

  @override
  List<Object> get props => [query];
}
