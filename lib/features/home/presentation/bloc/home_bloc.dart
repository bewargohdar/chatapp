import 'package:bloc/bloc.dart';
import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/features/home/domain/usecase/get_users_usecase.dart';
import 'package:chatapp/features/home/presentation/bloc/home_event.dart';
import 'package:chatapp/features/home/presentation/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUsersUseCase _getUsersUseCase;

  HomeBloc(this._getUsersUseCase) : super(HomeInitialState()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<RefreshUsersEvent>(_onRefreshUsers);
    on<SearchUsersEvent>(_onSearchUsers);
  }

  Future<void> _onSearchUsers(
      SearchUsersEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    final dataState = await _getUsersUseCase(event.query);

    if (dataState is DataSuccess) {
      emit(HomeLoadedState(dataState.data ?? []));
    } else if (dataState is DataError) {
      emit(HomeErrorState(dataState.error?.toString() ?? 'Unknown error'));
    }
  }

  Future<void> _onLoadUsers(
      LoadUsersEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    await _loadUsers(emit);
  }

  Future<void> _onRefreshUsers(
      RefreshUsersEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    await _loadUsers(emit);
  }

  Future<void> _loadUsers(Emitter<HomeState> emit) async {
    final dataState = await _getUsersUseCase(null);

    if (dataState is DataSuccess) {
      emit(HomeLoadedState(dataState.data ?? []));
    } else if (dataState is DataError) {
      emit(HomeErrorState(dataState.error?.toString() ?? 'Unknown error'));
    }
  }
}
