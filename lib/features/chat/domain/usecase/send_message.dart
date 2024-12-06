import 'package:chatapp/core/res/data_state.dart';
import 'package:chatapp/core/usecase/usecase.dart';
import 'package:chatapp/features/chat/data/models/message.dart';
import 'package:chatapp/features/chat/domain/repesotiry/chat_repository.dart';

class SendMessageUseCase extends UseCase<DataState<void>, MessageModel> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<DataState<void>> call(MessageModel params) {
    return repository.sendMessage(params);
  }
}
