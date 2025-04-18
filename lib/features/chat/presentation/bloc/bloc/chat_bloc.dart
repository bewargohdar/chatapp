import 'package:bloc/bloc.dart';

import '../../../../../core/res/data_state.dart';
import '../../../domain/usecase/get_message.dart';
import '../../../domain/usecase/send_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessageUsecase getMessagesUsecase;
  final SendMessageUseCase sendMessageUseCase;

  ChatBloc(this.getMessagesUsecase, this.sendMessageUseCase)
      : super(ChatInitialState()) {
    on<FetchMessagesEvent>(_onFetchMessages);
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onFetchMessages(
      FetchMessagesEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoadingState());
    await for (final dataState in getMessagesUsecase(event.selectedUser?.id)) {
      if (dataState is DataSuccess) {
        emit(ChatMessagesFetchedState(dataState.data ?? []));
      } else if (dataState is DataError) {
        emit(ChatErrorState(dataState.error?.toString() ?? 'Unknown error'));
      }
    }
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatState> emit) async {
    final dataState = await sendMessageUseCase(event.message);

    if (dataState is DataError) {
      emit(
          ChatErrorState(dataState.error?.toString() ?? 'Send message failed'));
    }
  }
}
