import 'dart:io';
import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VoiceService {
  AnotherAudioRecorder? _recorder;
  String? _recordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  // Start recording
  Future<void> startRecording() async {
    if (!await Permission.microphone.request().isGranted) {
      throw Exception('Microphone permission not granted');
    }

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';

      _recorder = AnotherAudioRecorder(path, audioFormat: AudioFormat.AAC);
      await _recorder!.initialized;
      await _recorder!.start();

      _isRecording = true;
      _recordingPath = path;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  // Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording || _recorder == null) return null;

    try {
      final recording = await _recorder!.stop();
      _isRecording = false;
      return recording?.path;
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to stop recording: $e');
    }
  }

  // Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (!_isRecording || _recorder == null) return;

    try {
      await _recorder!.stop();
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    } finally {
      _isRecording = false;
      _recordingPath = null;
    }
  }

  // Upload voice file to Firebase Storage and return the URL
  Future<String> uploadVoiceFile(String filePath) async {
    try {
      final fileName =
          'voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child(fileName);

      final File file = File(filePath);
      final uploadTask = await storageRef.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload voice file: $e');
    }
  }

  // Dispose
  void dispose() {
    cancelRecording();
    _recorder = null;
  }
}
