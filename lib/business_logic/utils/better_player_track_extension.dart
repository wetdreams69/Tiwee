import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/services.dart';

extension BetterPlayerTrackExtension on BetterPlayerController {
  // Mismo nombre que el CHANNEL en MainActivity
  static const _channel = MethodChannel('com.example.tiwee/tracks');

  int get _playerId => videoPlayerController?.textureId ?? 0;

  Future<List<Map<String, dynamic>>> getNativeAudioTracks() async {
    try {
      final result = await _channel.invokeMethod('getAudioTracks', {
        'playerId': _playerId,
      });
      return (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNativeSubtitleTracks() async {
    try {
      final result = await _channel.invokeMethod('getSubtitleTracks', {
        'playerId': _playerId,
      });
      return (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> selectNativeAudioTrack(int groupIndex) async {
    try {
      await _channel.invokeMethod('selectAudioTrack', {
        'playerId': _playerId,
        'groupIndex': groupIndex,
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> selectNativeSubtitleTrack(int? groupIndex) async {
    try {
      await _channel.invokeMethod('selectSubtitleTrack', {
        'playerId': _playerId,
        'groupIndex': groupIndex,
      });
    } catch (e) {
      // ignore
    }
  }

    Future<void> startSubtitleListener() async {
    try {
      await _channel.invokeMethod('startSubtitleListener', {
        'playerId': _playerId,
      });
    } catch (e) {}
  }

  Future<void> stopSubtitleListener() async {
    try {
      await _channel.invokeMethod('stopSubtitleListener', {
        'playerId': _playerId,
      });
    } catch (e) {}
  }
}
