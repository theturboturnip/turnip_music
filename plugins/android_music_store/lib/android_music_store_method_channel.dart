import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_music_store_platform_interface.dart';

/// An implementation of [AndroidMusicStorePlatform] that uses method channels.
class MethodChannelAndroidMusicStore extends AndroidMusicStorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('android_music_store');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
