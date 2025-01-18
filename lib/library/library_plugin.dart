import 'package:flutter/widgets.dart';
import 'package:turnip_music/repos/db/db_user.dart';

abstract class LibraryPlugin extends DbUser {
  Widget get icon;
  String get userVisibleName;
  // The backendId used by all datas managed by this plugin
  String get dataBackendId;
}
