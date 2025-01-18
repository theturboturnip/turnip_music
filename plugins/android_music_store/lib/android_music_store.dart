import 'package:android_music_store/album_art_store.dart';
import 'package:android_music_store/data_models.dart';

import 'android_music_store_platform_interface.dart';

class AndroidMusicStore {
  /// Get a list of all albums
  Future<List<AlbumSummary>?> listAllAlbums() {
    return AndroidMusicStorePlatform.instance.listAllAlbums();
  }

  /// Get an ordered list of songs in an album, or a list of the songs not attached to any album
  Future<List<Song>?> listSongsInAlbum(int? albumId) {
    return AndroidMusicStorePlatform.instance.listSongsInAlbum(albumId);
  }

  void registerNewAlbumArtNotifier(void Function(AlbumArtStore)? newArtCallback) {
    return AndroidMusicStorePlatform.instance.registerNewAlbumArtNotifier(newArtCallback);
  }

  Future<void> requestArtsForAlbums(int thumbSize, Iterable<int> albumIds) {
    return AndroidMusicStorePlatform.instance.requestArtsForAlbums(thumbSize, albumIds);
  }
}
