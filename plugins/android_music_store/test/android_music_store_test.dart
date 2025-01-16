import 'package:flutter_test/flutter_test.dart';
import 'package:android_music_store/android_music_store.dart';
import 'package:android_music_store/android_music_store_platform_interface.dart';
import 'package:android_music_store/android_music_store_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAndroidMusicStorePlatform
    with MockPlatformInterfaceMixin
    implements AndroidMusicStorePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AndroidMusicStorePlatform initialPlatform = AndroidMusicStorePlatform.instance;

  test('$MethodChannelAndroidMusicStore is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAndroidMusicStore>());
  });

  test('getPlatformVersion', () async {
    AndroidMusicStore androidMusicStorePlugin = AndroidMusicStore();
    MockAndroidMusicStorePlatform fakePlatform = MockAndroidMusicStorePlatform();
    AndroidMusicStorePlatform.instance = fakePlatform;

    expect(await androidMusicStorePlugin.getPlatformVersion(), '42');
  });
}
