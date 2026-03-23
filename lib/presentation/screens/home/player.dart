import 'dart:convert';
import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/material.dart';
import 'package:Tiwee/core/consts.dart';
import 'package:lottie/lottie.dart';

class Player extends StatefulWidget {
  final String url;
  final Map<String, String>? clearKey; // Pasado como Map de Dart

  const Player({Key? key, required this.url, this.clearKey}) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();

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

    // 2. Configuración de la fuente de datos (DASH + DRM)
    // En Media3 (BetterPlayerEnhanced), ClearKey espera un String JSON.
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.url,
      // Detección automática de formato
      videoFormat: widget.url.contains(".mpd") 
          ? BetterPlayerVideoFormat.dash 
          : BetterPlayerVideoFormat.hls,
      // Configuración DRM
      drmConfiguration: widget.clearKey != null 
          ? BetterPlayerDrmConfiguration(
              drmType: BetterPlayerDrmType.clearKey, // CamelCase (corregido)
              clearKey: jsonEncode(widget.clearKey), // Convertimos Map a String JSON
            ) 
          : null,
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
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
                  child: BetterPlayer(
                    controller: _betterPlayerController,
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
