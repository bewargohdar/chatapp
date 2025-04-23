import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chatapp/features/chat/domain/entity/message.dart';
import 'dart:collection';

// A static cache to store durations of previously loaded audio files
class AudioCache {
  static final Map<String, Duration> _durationCache =
      HashMap<String, Duration>();

  static Duration? getDuration(String url) {
    return _durationCache[url];
  }

  static void storeDuration(String url, Duration duration) {
    _durationCache[url] = duration;
  }
}

// A MessageBubble for showing a single chat message on the ChatScreen.
class MessageBubble extends StatefulWidget {
  // Create a message bubble which is meant to be the first in the sequence.
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
    this.voiceUrl,
    this.messageType = MessageType.text,
  }) : isFirstInSequence = true;

  // Create a amessage bubble that continues the sequence.
  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    this.voiceUrl,
    this.messageType = MessageType.text,
  })  : isFirstInSequence = false,
        userImage = null,
        username = null;

  // Whether or not this message bubble is the first in a sequence of messages
  // from the same user.
  // Modifies the message bubble slightly for these different cases - only
  // shows user image for the first message from the same user, and changes
  // the shape of the bubble for messages thereafter.
  final bool isFirstInSequence;

  // Image of the user to be displayed next to the bubble.
  // Not required if the message is not the first in a sequence.
  final String? userImage;

  // Username of the user.
  // Not required if the message is not the first in a sequence.
  final String? username;
  final String message;
  final String? voiceUrl;
  final MessageType messageType;

  // Controls how the MessageBubble will be aligned.
  final bool isMe;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoadingDuration = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == MessageType.voice) {
      _setupAudioPlayer();
      if (widget.voiceUrl != null && widget.voiceUrl!.isNotEmpty) {
        _loadDuration();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDuration() async {
    if (widget.voiceUrl == null) return;

    // First check if we have this duration cached
    final cachedDuration = AudioCache.getDuration(widget.voiceUrl!);
    if (cachedDuration != null) {
      if (mounted) {
        setState(() {
          _duration = cachedDuration;
        });
      }
      return;
    }

    // If not cached, show loading and fetch duration
    if (mounted) {
      setState(() {
        _isLoadingDuration = true;
      });
    }

    try {
      // Set a timeout to prevent hanging if server is slow
      await Future.any([
        _preloadAudioDuration(),
        Future.delayed(const Duration(seconds: 5))
      ]);
    } catch (e) {
      print('Error loading duration: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDuration = false;
        });
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
          // Cache the duration for future reference
          if (widget.voiceUrl != null && newDuration.inMilliseconds > 0) {
            AudioCache.storeDuration(widget.voiceUrl!, newDuration);
          }
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _preloadAudioDuration() async {
    try {
      // Optimize by setting lower quality when just getting duration
      _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

      // Create and set the audio source without playing
      await _audioPlayer.setSourceUrl(widget.voiceUrl!);

      // Get the duration
      final duration = await _audioPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
        });

        // Cache the duration for future use
        AudioCache.storeDuration(widget.voiceUrl!, duration);
      }

      // Reset to normal quality for playback
      _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (e) {
      print('Error preloading audio duration: $e');
    }
  }

  Future<void> _playPause() async {
    if (widget.voiceUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        // If we haven't loaded the source yet (which could happen if preload failed)
        if (_duration == Duration.zero) {
          await _audioPlayer.setSourceUrl(widget.voiceUrl!);
        }
        await _audioPlayer.resume();
      } catch (e) {
        print('Error playing audio: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _buildVoiceMessageContent() {
    // Calculate progress percentage
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    // Colors based on message sender
    final Color primaryColor = widget.isMe ? Colors.grey[800]! : Colors.white;
    final Color progressColor = widget.isMe
        ? Colors.deepPurpleAccent
        : Color(0xFF70C6FF); // WhatsApp green / light blue
    final Color backgroundColor =
        widget.isMe ? Colors.grey[300]! : Colors.white.withOpacity(0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button (WhatsApp style)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progressColor,
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _playPause,
            ),
          ),

          const SizedBox(width: 8),

          // Progress indicator and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // WhatsApp-style progress line with "bubbles"
                SizedBox(
                  height: 26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background track
                      Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Active track
                      Row(
                        children: [
                          Flexible(
                            flex: (progress * 100).toInt(),
                            child: Container(
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: progressColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (progress < 1)
                            Flexible(
                              flex: 100 - (progress * 100).toInt(),
                              child: Container(),
                            ),
                        ],
                      ),

                      // Waveform-like dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          30, // Number of dots
                          (index) {
                            final isActive = index / 30 <= progress;
                            return Container(
                              width: 2,
                              height: isActive ? 15 : 7,
                              decoration: BoxDecoration(
                                color:
                                    isActive ? progressColor : backgroundColor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Time indicator
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                      _isLoadingDuration
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor.withOpacity(0.7),
                              ))
                          : Row(
                              children: [
                                Icon(
                                  Icons.mic,
                                  size: 12,
                                  color: primaryColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(_duration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    if (widget.messageType == MessageType.image) {
      return SizedBox(
        width: 240, // Match parent's maxWidth
        height: 240, // Set a fixed height for consistency
        child: Image.network(
          widget.userImage ?? widget.message,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200], // Optional background
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Failed to load image',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.messageType == MessageType.voice) {
      return _buildVoiceMessageContent();
    }
    return Text(widget.message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        if (widget.userImage != null && widget.userImage!.isNotEmpty)
          Positioned(
              top: 15,
              // Align user image to the right, if the message is from me.
              right: widget.isMe ? 0 : null,
              child: CircleAvatar(
                backgroundImage: _getImageProvider(widget.userImage!),
                backgroundColor: theme.colorScheme.primary.withAlpha(180),
                radius: 23,
                child: widget.userImage == null || widget.userImage!.isEmpty
                    ? Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              )),
        Container(
          // Add some margin to the edges of the messages, to allow space for the
          // user's image.
          margin: const EdgeInsets.symmetric(horizontal: 46),
          child: Row(
            // The side of the chat screen the message should show at.
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // First messages in the sequence provide a visual buffer at
                  // the top.
                  if (widget.isFirstInSequence) const SizedBox(height: 18),
                  if (widget.username != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 13,
                        right: 13,
                      ),
                      child: Text(
                        widget.username!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                  // The "speech" box surrounding the message.
                  Container(
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.grey[300]
                          : theme.colorScheme.secondary.withAlpha(200),
                      // Only show the message bubble's "speaking edge" if first in
                      // the chain.
                      // Whether the "speaking edge" is on the left or right depends
                      // on whether or not the message bubble is the current user.
                      borderRadius: BorderRadius.only(
                        topLeft: !widget.isMe && widget.isFirstInSequence
                            ? Radius.zero
                            : const Radius.circular(12),
                        topRight: widget.isMe && widget.isFirstInSequence
                            ? Radius.zero
                            : const Radius.circular(12),
                        bottomLeft: const Radius.circular(12),
                        bottomRight: const Radius.circular(12),
                      ),
                    ),
                    // Set some reasonable constraints on the width of the
                    // message bubble so it can adjust to the amount of text
                    // it should show.
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    // Margin around the bubble.
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    child: _buildMessageContent(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to safely create an image provider
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const AssetImage('assets/images/chat.png');
    }

    try {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return NetworkImage(imageUrl);
      } else if (imageUrl.startsWith('assets/')) {
        return AssetImage(imageUrl);
      } else {
        // If URL is not empty but doesn't have a protocol, add https://
        return NetworkImage('https://$imageUrl');
      }
    } catch (e) {
      print('Error creating image provider: $e');
      // Fallback to default image
      return const AssetImage('assets/images/chat.png');
    }
  }
}
