package com.example.tiwee

import android.util.LongSparseArray
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

@androidx.annotation.OptIn(UnstableApi::class)
class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.tiwee/tracks"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            try {
                val textureId = (call.argument<Any>("playerId") as? Number)?.toLong()
                    ?: run { result.error("NO_ID", "playerId requerido", null); return@setMethodCallHandler }

                // ── Reflection: obtenemos el plugin por nombre de clase ──
                val pluginClass = Class.forName(
                    "com.sarthak.better_player_enhanced.BetterPlayerPlugin"
                )

                val pluginRegistryClass = flutterEngine.plugins.javaClass

                val pluginInstance = pluginRegistryClass.declaredFields
                    .map { it.apply { isAccessible = true } }
                    .mapNotNull { field ->
                        val value = field.get(flutterEngine.plugins)
                        when (value) {
                            is Map<*, *> -> value.values.firstOrNull { pluginClass.isInstance(it) }
                            else -> null
                        }
                    }
                    .firstOrNull()
                    ?: run { result.error("NO_PLUGIN", "BetterPlayerPlugin no encontrado", null); return@setMethodCallHandler }

                // ── Reflection: videoPlayers ──
                val videoPlayersField = pluginClass
                    .getDeclaredField("videoPlayers")
                    .apply { isAccessible = true }

                @Suppress("UNCHECKED_CAST")
                val videoPlayers = videoPlayersField.get(pluginInstance) as LongSparseArray<Any>

                val betterPlayer = videoPlayers[textureId]
                    ?: run { result.error("NO_PLAYER", "Player $textureId no encontrado", null); return@setMethodCallHandler }

                // ── Reflection: exoPlayer y trackSelector ──
                val betterPlayerClass = betterPlayer.javaClass

                val exoPlayerField = betterPlayerClass
                    .getDeclaredField("exoPlayer")
                    .apply { isAccessible = true }
                val exoPlayer = exoPlayerField.get(betterPlayer) as? ExoPlayer
                    ?: run { result.error("NO_EXOPLAYER", "ExoPlayer no disponible", null); return@setMethodCallHandler }

                val trackSelectorField = betterPlayerClass
                    .getDeclaredField("trackSelector")
                    .apply { isAccessible = true }
                val trackSelector = trackSelectorField.get(betterPlayer) as? DefaultTrackSelector
                    ?: run { result.error("NO_SELECTOR", "TrackSelector no disponible", null); return@setMethodCallHandler }

                // ── Handlers ────────────────────────────────────────────
                when (call.method) {

                    "getAudioTracks" -> {
                        val tracks = exoPlayer.currentTracks.groups
                            .filter { it.type == C.TRACK_TYPE_AUDIO }
                            .mapIndexed { i, group ->
                                val fmt = group.getTrackFormat(0)
                                mapOf(
                                    "groupIndex" to i,
                                    "language"   to (fmt.language ?: "und"),
                                    "label"      to (fmt.label ?: fmt.language ?: "Audio $i"),
                                    "selected"   to group.isSelected
                                )
                            }
                        result.success(tracks)
                    }

                    "getSubtitleTracks" -> {
                        val tracks = exoPlayer.currentTracks.groups
                            .filter { it.type == C.TRACK_TYPE_TEXT }
                            .mapIndexed { i, group ->
                                val fmt = group.getTrackFormat(0)
                                mapOf(
                                    "groupIndex" to i,
                                    "language"   to (fmt.language ?: "und"),
                                    "label"      to (fmt.label ?: fmt.language ?: "Sub $i"),
                                    "selected"   to group.isSelected
                                )
                            }
                        result.success(tracks)
                    }

                    "selectAudioTrack" -> {
                        val groupIndex = call.argument<Int>("groupIndex")!!
                        val audioGroups = exoPlayer.currentTracks.groups
                            .filter { it.type == C.TRACK_TYPE_AUDIO }
                        val group = audioGroups.getOrNull(groupIndex)
                        if (group != null) {
                            trackSelector.parameters = trackSelector.buildUponParameters()
                                .setOverrideForType(
                                    TrackSelectionOverride(group.mediaTrackGroup, 0)
                                ).build()
                        }
                        result.success(null)
                    }

                    "selectSubtitleTrack" -> {
                        val groupIndex = call.argument<Int?>("groupIndex")
                        if (groupIndex == null) {
                            trackSelector.parameters = trackSelector.buildUponParameters()
                                .setRendererDisabled(C.TRACK_TYPE_TEXT, true)
                                .build()
                        } else {
                            val subGroups = exoPlayer.currentTracks.groups
                                .filter { it.type == C.TRACK_TYPE_TEXT }
                            val group = subGroups.getOrNull(groupIndex)
                            if (group != null) {
                                trackSelector.parameters = trackSelector.buildUponParameters()
                                    .setRendererDisabled(C.TRACK_TYPE_TEXT, false)
                                    .setOverrideForType(
                                        TrackSelectionOverride(group.mediaTrackGroup, 0)
                                    ).build()
                            }
                        }
                        result.success(null)
                    }

                    "startSubtitleListener" -> {
                        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
                        val channel = MethodChannel(
                            flutterEngine.dartExecutor.binaryMessenger,
                            CHANNEL
                        )

                        exoPlayer.addListener(object : Player.Listener {
                            override fun onCues(cueGroup: CueGroup) {
                                val text = cueGroup.cues
                                    .mapNotNull { it.text?.toString() }
                                    .joinToString("\n")
                                mainHandler.post {
                                    channel.invokeMethod("onSubtitleCue", text)
                                }
                            }
                        })
                        result.success(null)
                    }

                    "stopSubtitleListener" -> {
                        // ExoPlayer limpia listeners al dispose
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }

            } catch (e: Exception) {
                result.error("EXCEPTION", e.message, e.stackTraceToString())
            }
        }
    }
}