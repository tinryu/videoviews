import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class TVPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;

  const TVPlayerControls({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  State<TVPlayerControls> createState() => _TVPlayerControlsState();
}

class _TVPlayerControlsState extends State<TVPlayerControls> {
  bool _isVisible = true;
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Auto-hide controls after delay
    _startHideTimer();
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _togglePlay() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _isVisible = true; // Show controls when paused
      } else {
        widget.controller.play();
        _startHideTimer();
      }
    });
  }

  void _seekRelative(Duration duration) {
    final newPos = widget.controller.value.position + duration;
    widget.controller.seekTo(newPos);
    setState(() {
      _isVisible = true;
    });
    _startHideTimer();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Show controls on any key press
      setState(() {
        _isVisible = true;
      });
      _startHideTimer();

      switch (event.logicalKey) {
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          _togglePlay();
          break;
        case LogicalKeyboardKey.arrowLeft:
          _seekRelative(const Duration(seconds: -10));
          break;
        case LogicalKeyboardKey.arrowRight:
          _seekRelative(const Duration(seconds: 10));
          break;
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
          // Maybe volume control?
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode ?? FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Invisible touch area to toggle controls on click (fallback)
          GestureDetector(
            onTap: () {
              setState(() {
                _isVisible = !_isVisible;
              });
              if (_isVisible) _startHideTimer();
            },
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),

          if (_isVisible)
            Container(
              color: Colors.black54,
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        const BackButton(color: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Play Button (Visual only, Logic is in key listener)
                  if (!widget.controller.value.isPlaying)
                    const Icon(
                      Icons.play_circle_fill,
                      size: 80,
                      color: Colors.white,
                    ),

                  const Spacer(),

                  // Bottom Progress Bar
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(widget.controller.value.position),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                            Text(
                              _formatDuration(widget.controller.value.duration),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        VideoProgressIndicator(
                          widget.controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.grey,
                          ),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
