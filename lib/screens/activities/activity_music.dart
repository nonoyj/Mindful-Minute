import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'calm_audio.dart';

/// Invisible widget that loops one bundled mp3 while [running] is true.
/// Each activity passes its OWN file, so every activity sounds different.
///   asset is relative to assets/, e.g. 'audio/breathing.mp3'
/// If the file is missing it falls back to the built-in calm tones.
class MusicLayer extends StatefulWidget {
  final String asset;
  final bool running;
  const MusicLayer({super.key, required this.asset, required this.running});

  @override
  State<MusicLayer> createState() => _MusicLayerState();
}

class _MusicLayerState extends State<MusicLayer> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if (widget.running) _play();
  }

  @override
  void didUpdateWidget(MusicLayer old) {
    super.didUpdateWidget(old);
    if (widget.running && !old.running) _play();
    if (!widget.running && old.running) _player.stop();
  }

  Future<void> _play() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(widget.asset));
    } catch (_) {
      try {
        await _player.play(BytesSource(calmWav(), mimeType: 'audio/wav'));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
