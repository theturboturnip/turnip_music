import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/repos/db/db_user.dart';
import 'package:turnip_music/util/rwlocked.dart';

const int dbOverallVersion = 1;

class DbRepo {
  static Future<DbRepo> createDatabase(String path, Map<String, DbUser> users) async {
    final db = await openDatabase(
      path,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
      version: dbOverallVersion,
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 1) {
          db.execute("CREATE TABLE userVersions (userId TEXT UNIQUE, version INT)");
        }
      },
    );

    final userVersionRows = await db.query("userVersions", columns: ["userId", "version"]);
    final userVersions = Map.fromEntries(
      userVersionRows.map(
        (row) => MapEntry(row["userId"] as String, row["version"] as int),
      ),
    );

    for (final entry in users.entries) {
      final dbUser = entry.value;
      final version = userVersions[entry.key];
      if (version == null) {
        dbUser.upgradeDb(db, 0);
      } else if (version < dbUser.dbVersion) {
        dbUser.upgradeDb(db, version);
      } else if (version > dbUser.dbVersion) {
        throw "DbUser ${dbUser.id} is compiled for a lower db version ${dbUser.dbVersion} than found in the database $version";
      }
    }

    return DbRepo(db: RwLocked(db));
  }

  final RwLocked<Database> db;

  DbRepo({required this.db});
}
