import 'package:chatapp/features/auth/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/res/data_state.dart';

abstract class AuthRemoteDataSource {
  Future<DataState<UserModel>> login(String email, String password);
  Future<DataState<UserModel>> signup(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final _auth = FirebaseAuth.instance;

  @override
  Future<DataState<UserModel>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return DataSuccess(
        UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return DataError(e);
    }
  }

  @override
  Future<DataState<UserModel>> signup(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return DataSuccess(
        UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return DataError(e);
    }
  }
}
