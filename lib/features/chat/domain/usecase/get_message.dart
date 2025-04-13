import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/core/usecase/usecase.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'package:chatapp/features/chat/domain/repesotiry/chat_repository.dart';

class GetMessageUsecase
    extends UseCase1<DataState<List<MessageEntity>>, String?> {
  final ChatRepository _repository;

  GetMessageUsecase(this._repository);

  @override
  Stream<DataState<List<MessageEntity>>> call(String? recipientId) {
    return _repository.getMessages(recipientId);
  }
}
