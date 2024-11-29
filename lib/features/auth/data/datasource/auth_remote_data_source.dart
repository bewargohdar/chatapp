import 'package:chatapp/features/auth/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> signup(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final _auth = FirebaseAuth.instance;
  @override
  Future<UserModel> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return UserModel(
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
    );
  }

  @override
  Future<UserModel> signup(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return UserModel(
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
    );
  }
}
