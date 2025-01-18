import 'package:android_music_store/data_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_music_store/android_music_store.dart';
import 'package:android_music_store/android_music_store_platform_interface.dart';
import 'package:android_music_store/android_music_store_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAndroidMusicStorePlatform with MockPlatformInterfaceMixin implements AndroidMusicStorePlatform {
  @override
  Future<List<AlbumSummary>?> listAllAlbums() {
    // TODO: implement listAllAlbums
    throw UnimplementedError();
  }

  @override
  Future<List<Song>?> listSongsInAlbum(int? albumId) {
    // TODO: implement listSongsInAlbum
    throw UnimplementedError();
  }
}

void main() {
  final AndroidMusicStorePlatform initialPlatform = AndroidMusicStorePlatform.instance;

  test('$MethodChannelAndroidMusicStore is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAndroidMusicStore>());
  });

  // TODO tests
  // test('getPlatformVersion', () async {
  //   AndroidMusicStore androidMusicStorePlugin = AndroidMusicStore();
  //   MockAndroidMusicStorePlatform fakePlatform = MockAndroidMusicStorePlatform();
  //   AndroidMusicStorePlatform.instance = fakePlatform;

  //   expect(await androidMusicStorePlugin.getPlatformVersion(), '42');
  // });
}
