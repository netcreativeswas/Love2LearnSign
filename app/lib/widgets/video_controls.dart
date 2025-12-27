
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:line_icons/line_icons.dart';

ButtonStyle videoControlButtonStyle(BuildContext context) {
  return ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    foregroundColor: Theme.of(context).colorScheme.primary,
    padding: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final double currentSpeed;
  final VoidCallback changeSpeed;
  final VoidCallback togglePlayPause;

  const VideoControls({
    super.key,
    required this.controller,
    required this.currentSpeed,
    required this.changeSpeed,
    required this.togglePlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: ElevatedButton(
              onPressed: changeSpeed,
              style: videoControlButtonStyle(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(IconlyLight.timeCircle, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    "${currentSpeed.toStringAsFixed(1)}x",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: ElevatedButton(
              onPressed: togglePlayPause,
            style: videoControlButtonStyle(context),
              child: Icon(
                controller.value.isPlaying ? LineIcons.pause : IconlyLight.play,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}