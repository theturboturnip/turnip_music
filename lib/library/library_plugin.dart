import 'package:flutter/widgets.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/pages/library_import_build_session.dart';
import 'package:turnip_music/repos/db/db_user.dart';

abstract class LibraryPlugin extends DbUser {
  Widget get icon;
  String get userVisibleName;
  // The backendId used by all datas managed by this plugin
  String get dataBackendId;

  // Create a Bloc used to search the library for new data
  PluginSuppliedLibrarySearchBloc makeSearchBloc();

  // Given a set of PluginImportable items, push them into an ImportSession
  Future<void> addImportablesToSession(Iterable<PluginSuppliedImportable> items, ImportSession session);
}
