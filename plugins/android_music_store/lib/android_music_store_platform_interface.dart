import 'package:android_music_store/album_art_store.dart';
import 'package:android_music_store/data_models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'android_music_store_method_channel.dart';

abstract class AndroidMusicStorePlatform extends PlatformInterface {
  /// Constructs a AndroidMusicStorePlatform.
  AndroidMusicStorePlatform() : super(token: _token);

  static final Object _token = Object();

  static AndroidMusicStorePlatform _instance = MethodChannelAndroidMusicStore();

  /// The default instance of [AndroidMusicStorePlatform] to use.
  ///
  /// Defaults to [MethodChannelAndroidMusicStore].
  static AndroidMusicStorePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AndroidMusicStorePlatform] when
  /// they register themselves.
  static set instance(AndroidMusicStorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // /// Call getVersion() on the MediaStore.Audio to see if metadata needs to be synced.
  // /// [See Android documentation for more info.](https://developer.android.com/training/data-storage/shared/media#check-for-updates)
  // Future<String?> getMediaStoreVersion();

  // /// Call MediaStore.getExternalVolumeNames() to find all the external volumes that may have audio data
  // /// that may have changed
  // Future<List<String>?> getVolumes();

  // /// Call MediaStore.getGeneration(volumeName) for each volume name,
  // /// which can be used to detect which volumes should be rescanned
  // /// as laid out [in Android documentation](https://developer.android.com/reference/android/provider/MediaStore#getGeneration(android.content.Context,%20java.lang.String))
  // Future<String?> getVolumesGenerations(List<String> volumeNames);

  /// Get a list of all albums
  Future<List<AlbumSummary>?> listAllAlbums();

  /// Get an ordered list of songs in an album, or a list of the songs not attached to any album
  Future<List<Song>?> listSongsInAlbum(int? albumId);

  void registerNewAlbumArtNotifier(void Function(AlbumArtStore)? newArtCallback);

  Future<void> requestArtsForAlbums(int thumbSize, Iterable<int> albumIds);
}
