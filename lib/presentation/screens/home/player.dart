import 'dart:convert';
import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/utils/better_player_track_extension.dart';

class Player extends StatefulWidget {
  final String url;
  final Map<String, String>? clearKey;
  final List<ChannelObj>? channels;
  final int? initialIndex;

  const Player({Key? key, required this.url, this.clearKey, this.channels, this.initialIndex})
      : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  BetterPlayerController? _betterPlayerController;
  final FocusNode _focusNode = FocusNode();
  int _currentIndex = 0;
  List<ChannelObj> _channels = [];

  List<Map<String, dynamic>> _audioTracks = [];
  List<Map<String, dynamic>> _subtitleTracks = [];

  // ── Subtítulos overlay ──
  String _currentSubtitle = '';
  bool _subtitlesActive = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _channels = widget.channels ?? [];
    if (!kIsWeb) _setupPlayer();
  }

  void _setupPlayer() {
    BetterPlayerConfiguration betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        textColor: Colors.white,
        iconsColor: Colors.white,
        enableFullscreen: true,
        showControlsOnInitialize: true,
        showControls: true,
        enableOverflowMenu: true,
        enableAudioTracks: false,
        enableSubtitles: false,
        enablePlaybackSpeed: false,
        overflowMenuCustomItems: [
          BetterPlayerOverflowMenuItem(
            Icons.audiotrack_outlined,
            "Seleccionar Audio",
            () => _showAudioDialog(),
          ),
          BetterPlayerOverflowMenuItem(
            Icons.subtitles_outlined,
            "Seleccionar Subtítulo",
            () => _showSubtitleDialog(),
          ),
        ],
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController!.addEventsListener(_onPlayerEvent);
    _betterPlayerController!.setupDataSource(
      _createDataSource(widget.url, widget.clearKey),
    );

    // Handler para recibir cues desde Kotlin
    const channel = MethodChannel('com.example.tiwee/tracks');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onSubtitleCue') {
        final text = call.arguments as String;
        if (mounted && _subtitlesActive) {
          setState(() => _currentSubtitle = text);
        }
      }
    });
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      Future.delayed(const Duration(milliseconds: 500), _loadNativeTracks);
      // Arrancamos el listener de cues
      _betterPlayerController!.startSubtitleListener();
    }
  }

  Future<void> _loadNativeTracks() async {
    if (_betterPlayerController == null) return;
    final audios = await _betterPlayerController!.getNativeAudioTracks();
    final subs = await _betterPlayerController!.getNativeSubtitleTracks();
    if (mounted) {
      setState(() {
        _audioTracks = audios;
        _subtitleTracks = subs;
      });
    }
  }

  void _showAudioDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Pistas de Audio"),
          backgroundColor: Colors.black87,
          contentTextStyle: const TextStyle(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _audioTracks.map((e) {
              final isSelected = e['selected'] == true;
              return ListTile(
                title: Text(
                  e['label'].toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.greenAccent : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () async {
                  await _betterPlayerController!
                      .selectNativeAudioTrack(e['groupIndex']);
                  Navigator.pop(ctx);
                  Future.delayed(
                      const Duration(milliseconds: 300), _loadNativeTracks);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSubtitleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Subtítulos"),
          backgroundColor: Colors.black87,
          contentTextStyle: const TextStyle(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opción desactivar
              ListTile(
                title: Text(
                  "Desactivar",
                  style: TextStyle(
                    color: !_subtitlesActive ? Colors.redAccent : Colors.white,
                  ),
                ),
                onTap: () async {
                  await _betterPlayerController!
                      .selectNativeSubtitleTrack(null);
                  setState(() {
                    _subtitlesActive = false;
                    _currentSubtitle = '';
                  });
                  Navigator.pop(ctx);
                },
              ),
              // Pistas disponibles
              ..._subtitleTracks.map((e) {
                final isSelected = e['selected'] == true;
                return ListTile(
                  title: Text(
                    e['label'].toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.greenAccent : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    await _betterPlayerController!
                        .selectNativeSubtitleTrack(e['groupIndex']);
                    setState(() => _subtitlesActive = true);
                    Navigator.pop(ctx);
                    Future.delayed(
                        const Duration(milliseconds: 300), _loadNativeTracks);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  String hexToBase64Url(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  BetterPlayerDataSource _createDataSource(
      String url, Map<String, String>? clearKeyMap) {
    String? clearKeyJwk;
    if (clearKeyMap != null) {
      List<Map<String, String>> jwkKeys = [];
      clearKeyMap.forEach((kidHex, keyHex) {
        jwkKeys.add({
          "kty": "oct",
          "kid": hexToBase64Url(kidHex.toString()),
          "k": hexToBase64Url(keyHex.toString()),
        });
      });
      clearKeyJwk = jsonEncode({"keys": jwkKeys, "type": "temporary"});
    }

    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      liveStream: true,
      videoFormat: url.contains(".mpd")
          ? BetterPlayerVideoFormat.dash
          : BetterPlayerVideoFormat.hls,
      drmConfiguration: clearKeyJwk != null
          ? BetterPlayerDrmConfiguration(
              drmType: BetterPlayerDrmType.clearKey,
              clearKey: clearKeyJwk,
            )
          : null,
    );
  }

  void _changeChannel(int newIndex) {
    if (_channels.isEmpty || newIndex < 0 || newIndex >= _channels.length) return;
    setState(() {
      _currentIndex = newIndex;
      // Limpiamos subtítulos al cambiar canal
      _subtitlesActive = false;
      _currentSubtitle = '';
    });
    if (!kIsWeb) {
      final channel = _channels[newIndex];
      _betterPlayerController?.setupDataSource(
        _createDataSource(channel.url, channel.clearkey),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!kIsWeb) _betterPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _changeChannel(_currentIndex - 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _changeChannel(_currentIndex + 1);
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // ── Player ──
                Positioned.fill(
                  child: Center(
                    child: kIsWeb
                        ? const Text(
                            "Reproductor nativo/DRM no soportado en Web.",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          )
                        : BetterPlayer(
                            controller: _betterPlayerController!,
                          ),
                  ),
                ),

                // ── Overlay de subtítulos ──
                if (_subtitlesActive && _currentSubtitle.isNotEmpty)
                  Positioned(
                    bottom: 60,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}