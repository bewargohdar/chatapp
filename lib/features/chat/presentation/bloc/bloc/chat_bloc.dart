import 'dart:async';
import 'package:bloc/bloc.dart';

import '../../../../../core/res/data_state.dart';
import '../../../../../core/services/voice_service.dart';
import '../../../../../core/services/user_message_service.dart';
import '../../../../auth/domain/entity/user.dart';
import '../../../domain/entity/message.dart';
import '../../../domain/usecase/get_message.dart';
import '../../../domain/usecase/send_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessageUsecase getMessagesUsecase;
  final SendMessageUseCase sendMessageUseCase;
  final VoiceService _voiceService;
  final UserMessageService _userMessageService;

  // Subscription for typing status
  StreamSubscription? _typingSubscription;
  UserEntity? _currentChatPartner;
  List<MessageEntity> _cachedMessages = [];
  bool _isPartnerTyping = false;

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
    on<StartTypingEvent>(_onStartTyping);
    on<StopTypingEvent>(_onStopTyping);
  }

  Future<void> _onFetchMessages(
      FetchMessagesEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoadingState());

    // If we're switching chat partners, cancel the previous subscription
    if (_currentChatPartner?.id != event.selectedUser?.id) {
      await _typingSubscription?.cancel();
      _typingSubscription = null;
      _startListeningToTypingStatus(event.selectedUser);
    }

    _currentChatPartner = event.selectedUser;

    await for (final dataState in getMessagesUsecase(event.selectedUser?.id)) {
      if (dataState is DataSuccess) {
        _cachedMessages = dataState.data ?? [];
        emit(ChatMessagesFetchedState(_cachedMessages,
            isTyping: _isPartnerTyping));
      } else if (dataState is DataError) {
        emit(ChatErrorState(dataState.error?.toString() ?? 'Unknown error'));
      }
    }
  }

  void _startListeningToTypingStatus(UserEntity? chatPartner) {
    if (chatPartner?.id == null) return;

    _typingSubscription =
        _userMessageService.getTypingStatus(chatPartner!.id).listen((isTyping) {
      _isPartnerTyping = isTyping;
      // Only emit if we have an active chat with cached messages
      if (_cachedMessages.isNotEmpty) {
        emit(ChatMessagesFetchedState(_cachedMessages, isTyping: isTyping));
      }
    });
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatState> emit) async {
    final dataState = await sendMessageUseCase(event.message);

    if (dataState is DataError) {
      emit(
          ChatErrorState(dataState.error?.toString() ?? 'Send message failed'));
    } else if (dataState is DataSuccess) {
      // Clear typing status when sending a message
      if (event.message.recipientId != null) {
        await _userMessageService.setTypingStatus(
            event.message.recipientId, false);
      }

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

  // Handle typing status
  Future<void> _onStartTyping(
      StartTypingEvent event, Emitter<ChatState> emit) async {
    try {
      await _userMessageService.setTypingStatus(event.recipient?.id, true);
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  Future<void> _onStopTyping(
      StopTypingEvent event, Emitter<ChatState> emit) async {
    try {
      await _userMessageService.setTypingStatus(event.recipient?.id, false);
    } catch (e) {
      print('Error clearing typing status: $e');
    }
  }

  @override
  Future<void> close() {
    _typingSubscription?.cancel();
    _voiceService.dispose();
    return super.close();
  }
}
