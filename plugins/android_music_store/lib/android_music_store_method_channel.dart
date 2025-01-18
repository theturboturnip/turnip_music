import 'dart:async';
import 'dart:convert';

import 'package:android_music_store/album_art_store.dart';
import 'package:android_music_store/data_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'android_music_store_platform_interface.dart';

/// An implementation of [AndroidMusicStorePlatform] that uses method channels.
class MethodChannelAndroidMusicStore extends AndroidMusicStorePlatform {
  MethodChannelAndroidMusicStore()
      : methodChannel = const MethodChannel('android_music_store'),
        _albumArts = AlbumArtStore() {
    methodChannel.setMethodCallHandler(handleMethodCall);
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel;

  final AlbumArtStore _albumArts;

  void Function(AlbumArtStore)? _newArtCallback;

  Future<void> handleMethodCall(MethodCall call) async {
    if (call.method == "receiveAlbumArt") {
      final args = call.arguments as List<dynamic>;
      final albumId = (args[0] as String);
      final albumJpg = (args[1] as Uint8List?);
      if (albumJpg != null) {
        final width = (args[2] as int);
        final height = (args[3] as int);
        _albumArts.addImage(albumId, albumJpg, width, height);
      } else {
        _albumArts.removeImage(albumId);
      }
      _newArtCallback?.call(_albumArts);
    } else {
      throw "Unknown method ${call.method}";
    }
  }

  @override
  void registerNewAlbumArtNotifier(void Function(AlbumArtStore)? newArtCallback) {
    _newArtCallback = newArtCallback;
    if (newArtCallback != null) {
      newArtCallback(_albumArts);
    }
  }

  @override
  Future<List<AlbumSummary>?> listAllAlbums() async {
    print("listAllAlbums");
    final List<String>? albums = await methodChannel.invokeListMethod('listAllAlbums');
    print("got $albums");
    return albums?.map((json) => AlbumSummary.fromJson(jsonDecode(json))).toList();
  }

  @override
  Future<List<Song>?> listSongsInAlbum(int? albumId) async {
    print("listSongInAlbum $albumId");
    final List<String>? songs = await methodChannel.invokeListMethod('listSongsInAlbum', [albumId?.toString()]);
    print("got $songs");
    return songs?.map((json) => Song.fromJson(jsonDecode(json))).toList();
  }

  @override
  Future<void> requestArtsForAlbums(int thumbSize, Iterable<int> albumIds) {
    return methodChannel.invokeListMethod('requestArtsForAlbums', ["$thumbSize", ...albumIds.map((e) => "$e")]);
  }

  // @override
  // Future<String?> getPlatformVersion() async {
  //   final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
  //   return version;
  // }
}
