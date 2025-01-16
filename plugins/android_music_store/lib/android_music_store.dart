
import 'android_music_store_platform_interface.dart';

class AndroidMusicStore {
  Future<String?> getPlatformVersion() {
    return AndroidMusicStorePlatform.instance.getPlatformVersion();
  }
}
