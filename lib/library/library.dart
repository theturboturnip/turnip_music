import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/library/plugins/android_media_store.dart';

List<LibraryPlugin> getLibraryPluginsForPlatform() {
  return [
    if (!kIsWeb && Platform.isAndroid) AndroidMediaStoreLibraryPlugin(),
  ];
}
