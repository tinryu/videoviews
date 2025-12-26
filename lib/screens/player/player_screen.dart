import 'package:universal_io/io.dart' show Platform;

import '../../widgets/tv_player_controls.dart';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win.dart' as win_player;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/movie.dart';

class PlayerScreen extends StatefulWidget {
  final Movie movie;
  final String? videoUrlOverride;
  final String? episodeLabel;

  const PlayerScreen({
    super.key,
    required this.movie,
    this.videoUrlOverride,
    this.episodeLabel,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  win_player.WinVideoPlayerController? _winVideo;
  Player? _mediaKitPlayer;
  VideoController? _mediaKitVideoController;
  Object? _error;
  double _playbackSpeed = 1.0;
  bool get _isWindows => Platform.isWindows;

  static const List<double> _speedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0
  ];

  bool _isHlsUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.m3u8') || lowerUrl.contains('.m3u8');
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    debugPrint('Setting playback speed to: $speed');

    if (_mediaKitPlayer != null) {
      debugPrint('Using media_kit player');
      try {
        await _mediaKitPlayer!.setRate(speed);
        debugPrint('Successfully set media_kit playback speed to $speed');
      } catch (e) {
        debugPrint('Error setting media_kit playback speed: $e');
      }
    } else if (_chewie?.videoPlayerController.value.isInitialized == true) {
      debugPrint('Using chewie player');
      try {
        await _chewie?.videoPlayerController.setPlaybackSpeed(speed);
        debugPrint('Successfully set chewie playback speed to $speed');
      } catch (e) {
        debugPrint('Error setting chewie playback speed: $e');
      }
    } else if (_winVideo != null) {
      debugPrint('Using win_video player');
      try {
        await _winVideo?.setPlaybackSpeed(speed);
        debugPrint('Successfully set win_video playback speed to $speed');
      } catch (e) {
        debugPrint('Error setting win_video playback speed: $e');
      }
    } else {
      debugPrint('No valid video player found');
    }

    if (mounted) {
      setState(() {
        _playbackSpeed = speed;
        debugPrint('Updated UI playback speed to: $_playbackSpeed');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Enable wakelock to keep screen awake during video playback
    WakelockPlus.enable();
    _init();
  }

  Future<void> _init() async {
    try {
      final url = (widget.videoUrlOverride ?? widget.movie.videoUrl).trim();

      // Validate URL is not empty
      if (url.isEmpty) {
        throw Exception('Video URL is empty');
      }

      // Parse and validate URI
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL: $url');
      }

      // Ensure URI is absolute
      if (!uri.isAbsolute) {
        throw Exception('Video URL must be absolute: $url');
      }

      if (_isWindows) {
        // Windows platform - use media_kit for HLS, video_player_win for others
        if (_isHlsUrl(url)) {
          // HLS on Windows - use media_kit
          final player = Player();
          final videoController = VideoController(
            player,
            configuration:
                VideoControllerConfiguration(width: 640, height: 480),
          );
          await player.open(Media(url));
          setState(() {
            _mediaKitPlayer = player;
            _mediaKitVideoController = videoController;
          });
        } else {
          // Non-HLS on Windows - use video_player_win
          final winVideo =
              win_player.WinVideoPlayerController.network(uri.toString());
          await winVideo.initialize();
          setState(() {
            _winVideo = winVideo;
          });
        }
      } else {
        // Use standard video_player for other platforms
        final video = VideoPlayerController.networkUrl(uri);
        await video.initialize();
        final chewie = ChewieController(
          videoPlayerController: video,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showOptions: true,
          playbackSpeeds: _speedOptions,
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).colorScheme.primary,
            handleColor: Theme.of(context).colorScheme.primary,
            bufferedColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
        if (!mounted) {
          chewie.dispose();
          video.dispose();
          return;
        }
        setState(() {
          _video = video;
          _chewie = chewie;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    // Disable wakelock when leaving player screen
    WakelockPlus.disable();
    _chewie?.dispose();
    _video?.dispose();
    _winVideo?.dispose();
    _mediaKitPlayer?.dispose();
    // VideoController doesn't need explicit disposal - it's handled by Player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.episodeLabel == null
              ? widget.movie.title
              : '${widget.movie.title} • ${widget.episodeLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_disabled,
                    color: Colors.white70, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Could not play this video.\n${_error.toString()}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _init,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isWindows) {
      // Check if we're using media_kit (for HLS) or video_player_win (for non-HLS)
      if (_mediaKitVideoController != null && _mediaKitPlayer != null) {
        // Use media_kit for HLS streams on Windows
        return MaterialDesktopVideoControlsTheme(
          normal: MaterialDesktopVideoControlsThemeData(
            seekBarThumbColor: Colors.blue,
            seekBarPositionColor: Colors.blue,
            topButtonBar: [
              const Spacer(),
              MaterialDesktopCustomButton(
                onPressed: () {
                  showModalBottomSheet(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5),
                    context: context,
                    backgroundColor: Colors.transparent,
                    shape: Border.all(width: 0, color: Colors.transparent),
                    builder: (BuildContext context) {
                      return Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          border:
                              Border.all(width: 0, color: Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            for (final speed in [
                              0.5,
                              0.75,
                              1.0,
                              1.25,
                              1.5,
                              2.0
                            ])
                              RadioListTile<double>(
                                selectedTileColor: Colors.white,
                                activeColor: Colors.white,
                                title: Text(
                                  '${speed}x',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                                value: speed,
                                groupValue: _playbackSpeed,
                                onChanged: (value) {
                                  if (value != null) {
                                    _setPlaybackSpeed(value);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.more_vert),
              ),
            ],
            bottomButtonBar: const [
              MaterialDesktopPlayOrPauseButton(),
              MaterialDesktopPositionIndicator(),
              Spacer(),
              MaterialDesktopVolumeButton(),
              MaterialDesktopFullscreenButton(),
            ],
          ),
          fullscreen: const MaterialDesktopVideoControlsThemeData(),
          child: Scaffold(body: Video(controller: _mediaKitVideoController!)),
        );
      } else if (_winVideo != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: VideoPlayer(_winVideo! as VideoPlayerController),
        );
      } else {
        return const DecoratedBox(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      // Non-Windows Platforms
      if (_video == null || !_video!.value.isInitialized) {
        return const DecoratedBox(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      // Check for Tizen/TV environment (Linux is the underlying OS for Tizen)
      // We assume Linux implies Tizen in this project context effectively
      if (Platform.isLinux) {
        return TVPlayerControls(
          controller: _video!,
          title: widget.movie.title,
        );
      }

      // Fallback to Chewie for other Mobile/Web platforms
      if (_chewie == null) {
        return const DecoratedBox(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Chewie(controller: _chewie!),
      );
    }
  }
}
