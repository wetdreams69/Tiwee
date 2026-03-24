import 'dart:convert';
import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiwee/core/consts.dart';
import 'package:lottie/lottie.dart';

class Player extends StatefulWidget {
  final String url;
  final Map<String, String>? clearKey; // Pasado como Map de Dart

  const Player({Key? key, required this.url, this.clearKey}) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  BetterPlayerController? _betterPlayerController;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      // 1. Configuraciones generales
      BetterPlayerConfiguration betterPlayerConfiguration = const BetterPlayerConfiguration(
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
        ),
      );

      // Función local para convertir HEX a Base64Url (requerimiento de ExoPlayer JWK)
      String hexToBase64Url(String hex) {
        List<int> bytes = [];
        for (int i = 0; i < hex.length; i += 2) {
          bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
        }
        return base64UrlEncode(bytes).replaceAll('=', '');
      }

      String? clearKeyJwk;
      if (widget.clearKey != null) {
        List<Map<String, String>> jwkKeys = [];
        widget.clearKey!.forEach((kidHex, keyHex) {
          jwkKeys.add({
            "kty": "oct",
            "kid": hexToBase64Url(kidHex.toString()),
            "k": hexToBase64Url(keyHex.toString())
          });
        });
        clearKeyJwk = jsonEncode({"keys": jwkKeys, "type": "temporary"});
      }

      // 2. Configuración de la fuente de datos (DASH + DRM)
      BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.url,
        videoFormat: widget.url.contains(".mpd") 
            ? BetterPlayerVideoFormat.dash 
            : BetterPlayerVideoFormat.hls,
        drmConfiguration: clearKeyJwk != null 
            ? BetterPlayerDrmConfiguration(
                drmType: BetterPlayerDrmType.clearKey,
                clearKey: clearKeyJwk,
              ) 
            : null,
      );

      _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
      _betterPlayerController!.setupDataSource(dataSource);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _betterPlayerController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
