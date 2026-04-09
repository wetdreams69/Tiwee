import 'dart:convert';
import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/business_logic/model/channel.dart';
import 'package:tiwee/business_logic/utils/better_player_track_extension.dart';
import 'package:dio/dio.dart';

class Player extends StatefulWidget {
  final List<ChannelObj> channels;
  final int initialIndex;

  const Player({
    Key? key,
    required this.channels,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  BetterPlayerController? _betterPlayerController;
  final FocusNode _focusNode = FocusNode();
  int _currentIndex = 0;
  int _currentStreamIndex = 0;
  List<ChannelObj> _channels = [];

  List<Map<String, dynamic>> _audioTracks = [];
  List<Map<String, dynamic>> _subtitleTracks = [];

  String _currentSubtitle = '';
  bool _subtitlesActive = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _channels = widget.channels;
    _setupPlayer();
  }

  void _setupPlayer() async {
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

    if (_channels.isNotEmpty && _currentIndex < _channels.length) {
      final channel = _channels[_currentIndex];
      if (channel.streams.isNotEmpty) {
        final stream = channel.streams[_currentStreamIndex];
        
        String finalUrl = await _resolveUrl(stream.url, stream.headers);

        _betterPlayerController!.setupDataSource(
          _createDataSource(finalUrl, stream.clearkey, stream.headers),
        );
      }
    }

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
      _betterPlayerController!.startSubtitleListener();
    } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      debugPrint("BetterPlayer Exception: ${event.parameters}");
      _tryNextStream();
    }
  }

  void _tryNextStream() {
    if (_channels.isEmpty || _currentIndex >= _channels.length) return;
    final channel = _channels[_currentIndex];
    
    if (_currentStreamIndex + 1 < channel.streams.length) {
      _currentStreamIndex++;
      final nextStream = channel.streams[_currentStreamIndex];
      
      _resolveUrl(nextStream.url, nextStream.headers).then((finalUrl) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error en stream ${_currentStreamIndex}. Intentando fallback..."),
            backgroundColor: Colors.orangeAccent.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );

        debugPrint("Streaming failed. Trying next stream (${_currentStreamIndex}): $finalUrl");
        
        _betterPlayerController?.setupDataSource(
          _createDataSource(finalUrl, nextStream.clearkey, nextStream.headers),
        );
      });
    } else {
      // Si ya no hay más streams, avisar del error definitivo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo cargar ningún stream para este canal."),
          backgroundColor: Colors.redAccent,
        ),
      );
      debugPrint("No more streams available for this channel.");
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

  void _showAudioDialog() async {
    await _loadNativeTracks();
    if (!mounted) return;
    
    if (_audioTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontraron pistas de audio todavía.")),
      );
      return;
    }

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

  void _showSubtitleDialog() async {
    await _loadNativeTracks();
    if (!mounted) return;

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
      String url, List<ClearKey>? clearKeyList, Map<String, String>? headers) {
    String? clearKeyJwk;
    if (clearKeyList != null && clearKeyList.isNotEmpty) {
      List<Map<String, String>> jwkKeys = [];
      for (var ck in clearKeyList) {
        jwkKeys.add({
          "kty": "oct",
          "kid": hexToBase64Url(ck.keyId),
          "k": hexToBase64Url(ck.key),
        });
      }
      clearKeyJwk = jsonEncode({"keys": jwkKeys, "type": "temporary"});
    }

    Map<String, String> finalHeaders = {
      "Accept": "*/*",
      "Access-Control-Allow-Origin": "*",
    };
    if (headers != null) {
      finalHeaders.addAll(headers);
      if (headers.containsKey("Origin")) {
        finalHeaders["Referer"] = "${headers["Origin"]}/";
        if (headers["Origin"]!.contains("flow.com.ar")) {
          finalHeaders["X-Flow-Origin"] = "portal";
        }
      }
    }

    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      liveStream: true,
      headers: finalHeaders,
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

  Future<String> _resolveUrl(String url, Map<String, String>? headers) async {
    try {
      final dio = Dio(BaseOptions(
        followRedirects: false,
        validateStatus: (status) => true,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        },
      ));

      final response = await dio.head(url);
      
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value("location");
        if (location != null) {
          return location;
        }
      }
    } catch (e) {
      debugPrint("Error resolving redirect: $e");
    }
    return url;
  }

  void _changeChannel(int newIndex) {
    if (_channels.isEmpty || newIndex < 0 || newIndex >= _channels.length) return;
    setState(() {
      _currentIndex = newIndex;
      _currentStreamIndex = 0;
      _subtitlesActive = false;
      _currentSubtitle = '';
    });
    final channel = _channels[newIndex];
    if (channel.streams.isNotEmpty) {
      final stream = channel.streams[0];
      _resolveUrl(stream.url, stream.headers).then((finalUrl) {
        _betterPlayerController?.setupDataSource(
          _createDataSource(finalUrl, stream.clearkey, stream.headers),
        );
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _betterPlayerController?.dispose();
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
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: BetterPlayer(
                      controller: _betterPlayerController!,
                    ),
                  ),
                ),

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