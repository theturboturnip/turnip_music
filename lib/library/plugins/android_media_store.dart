import 'package:flutter/src/widgets/framework.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:turnip_music/library/library_plugin.dart';

class AndroidMediaStoreLibraryPlugin extends LibraryPlugin {
  @override
  String get id => "com.theturboturnip.turnip_music.android_media_store";

  @override
  // TODO: implement icon
  Widget get icon => throw UnimplementedError();

  @override
  // TODO: implement userVisibleName
  String get userVisibleName => throw UnimplementedError();

  @override
  String get dataBackendId => "ams";

  @override
  int get dbVersion => 1;

  @override
  Future<void> upgradeDb(DatabaseExecutor db, int oldVersion) async {
    if (oldVersion < 1) {
      // TODO
    }
  }
}
