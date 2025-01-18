import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class AlbumArtStore {
  final Map<String, (Uint8List, int, int)> store = {};

  void addImage(
    String key,
    Uint8List data,
    int width,
    int height,
  ) {
    store[key] = (data, width, height);
  }

  void removeImage(String key) {
    store.remove(key);
  }

  Image? getImage(String key, {double? width, double? height}) {
    final data = store[key];
    if (data == null) {
      return null;
    } else {
      return Image.memory(
        data.$1,
        cacheWidth: data.$2,
        cacheHeight: data.$3,
        width: width,
        height: height,
      );
    }
  }
}
