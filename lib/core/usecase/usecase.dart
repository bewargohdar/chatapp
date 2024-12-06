abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

abstract class UseCase1<Type, Params> {
  Stream<Type> call(Params params);
}
