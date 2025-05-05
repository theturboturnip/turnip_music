import 'package:turnip_music/library/data/db.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/repos/db/db_user.dart';

class PluginRepo {
  PluginRepo._(
    this.libraryDbUser,
    this._libraryPlugins,
    this._dbUsers,
  );

  static PluginRepo makePluginRepo({required List<LibraryPlugin> libraryPlugins}) {
    final libraryDbUser = LibraryDbUser();

    var dbUsers = <String, DbUser>{
      for (var dbUser in [
        libraryDbUser,
        ...libraryPlugins,
      ])
        dbUser.id: dbUser
    };

    return PluginRepo._(libraryDbUser, libraryPlugins, dbUsers);
  }

  final LibraryDbUser libraryDbUser;
  final List<LibraryPlugin> _libraryPlugins;
  final Map<String, DbUser> _dbUsers;

  Iterable<LibraryPlugin> get libraryPlugins => _libraryPlugins;

  Map<String, DbUser> get dbUsers => _dbUsers;
}
