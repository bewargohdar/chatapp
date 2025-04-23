import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/res/data_state.dart';
import '../../../data/models/message.dart';
import '../../../data/services/voice_service.dart';
import '../../../data/services/user_message_service.dart';
import '../../../domain/entity/message.dart';
import '../../../domain/usecase/get_message.dart';
import '../../../domain/usecase/send_message.dart';
import '../../../../auth/domain/entity/user.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessageUsecase getMessagesUsecase;
  final SendMessageUseCase sendMessageUseCase;
  final VoiceService _voiceService;
  final UserMessageService _userMessageService;

  ChatBloc(
    this.getMessagesUsecase,
    this.sendMessageUseCase,
    this._voiceService,
    this._userMessageService,
  ) : super(ChatInitialState()) {
    on<FetchMessagesEvent>(_onFetchMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<StartRecordingVoiceEvent>(_onStartRecordingVoice);
    on<StopRecordingVoiceEvent>(_onStopRecordingVoice);
    on<CancelRecordingVoiceEvent>(_onCancelRecordingVoice);
    on<SendVoiceMessageEvent>(_onSendVoiceMessage);
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
    } else if (dataState is DataSuccess) {
      // Refresh the messages list after sending a text message
      final recipientId = event.message.recipientId;
      if (recipientId != null) {
        // Create a dummy UserEntity with just the ID to refresh messages
        final recipient = UserEntity(id: recipientId, username: '', email: '');
        add(FetchMessagesEvent(selectedUser: recipient));
      }
    }
  }

  Future<void> _onStartRecordingVoice(
      StartRecordingVoiceEvent event, Emitter<ChatState> emit) async {
    try {
      await _voiceService.startRecording();
      emit(VoiceRecordingStartedState());
    } catch (e) {
      emit(ChatErrorState('Failed to start recording: $e'));
    }
  }

  Future<void> _onStopRecordingVoice(
      StopRecordingVoiceEvent event, Emitter<ChatState> emit) async {
    try {
      final filePath = await _voiceService.stopRecording();
      emit(VoiceRecordingStoppedState());

      if (filePath != null) {
        add(SendVoiceMessageEvent(
          filePath: filePath,
          recipient: event.recipient,
        ));
      }
    } catch (e) {
      emit(ChatErrorState('Failed to stop recording: $e'));
    }
  }

  Future<void> _onCancelRecordingVoice(
      CancelRecordingVoiceEvent event, Emitter<ChatState> emit) async {
    try {
      await _voiceService.cancelRecording();
      emit(VoiceRecordingCanceledState());
    } catch (e) {
      emit(ChatErrorState('Failed to cancel recording: $e'));
    }
  }

  Future<void> _onSendVoiceMessage(
      SendVoiceMessageEvent event, Emitter<ChatState> emit) async {
    emit(VoiceSendingState());

    try {
      // Upload voice file to Firebase Storage
      final voiceUrl = await _voiceService.uploadVoiceFile(event.filePath);

      // Create voice message
      final message = await _userMessageService.createVoiceMessage(
        voiceUrl,
        event.recipient?.id,
      );

      final dataState = await sendMessageUseCase(message);

      if (dataState is DataSuccess) {
        emit(VoiceSentState());

        // Refresh the messages list after sending a voice message
        add(FetchMessagesEvent(selectedUser: event.recipient));
      } else if (dataState is DataError) {
        emit(ChatErrorState(
            dataState.error?.toString() ?? 'Failed to send voice message'));
      }
    } catch (e) {
      emit(ChatErrorState('Failed to process voice message: $e'));
    }
  }

  @override
  Future<void> close() {
    _voiceService.dispose();
    return super.close();
  }
}
