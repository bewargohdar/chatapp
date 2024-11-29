import 'package:bloc/bloc.dart';
import 'package:chatapp/features/auth/domain/entity/user.dart';
import 'package:chatapp/features/auth/domain/usecase/login.dart';
import 'package:chatapp/features/auth/domain/usecase/singup.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Singup _singup;
  final Login _login;
  AuthBloc(this._singup, this._login) : super(AuthInitial()) {
    on<AuthRegister>(_onSignUp);
    on<AuthLogin>(_onLogin);
  }

  void _onSignUp(AuthRegister event, Emitter<AuthState> emit) async {
    try {
      final result = await _singup(SignupParams(event.email, event.password));
      emit(AuthSuccess(result));
    } catch (e) {
      emit(AuthFailure('Singup failed'));
    }
  }

  void _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    try {
      final result = await _login(LoginParams(event.email, event.password));
      emit(AuthSuccess(result));
    } catch (e) {
      emit(AuthFailure('Login failed'));
    }
  }
}
