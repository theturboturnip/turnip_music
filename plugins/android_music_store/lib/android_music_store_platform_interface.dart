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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
