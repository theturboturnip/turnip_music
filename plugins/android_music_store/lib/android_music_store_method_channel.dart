import 'dart:convert';

import 'package:android_music_store/data_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_music_store_platform_interface.dart';

/// An implementation of [AndroidMusicStorePlatform] that uses method channels.
class MethodChannelAndroidMusicStore extends AndroidMusicStorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('android_music_store');

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

  // @override
  // Future<String?> getPlatformVersion() async {
  //   final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
  //   return version;
  // }
}
