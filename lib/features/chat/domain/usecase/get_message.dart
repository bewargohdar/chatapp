import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/core/usecase/usecase.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:chatapp/features/chat/domain/repesotiry/chat_repository.dart';

class GetMessageUsecase extends UseCase<DataState<List<MessageEntity>>, void> {
  final ChatRepository repository;

  GetMessageUsecase(this.repository);

  @override
  Future<DataState<List<MessageEntity>>> call(void params) {
    return repository
        .getMessages(); // Ensure repository method returns DataState
  }
}