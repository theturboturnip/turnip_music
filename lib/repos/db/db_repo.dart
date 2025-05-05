import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/library/data/db.dart';
import 'package:turnip_music/repos/plugin_repo.dart';
import 'package:turnip_music/util/locked_ref.dart';

class DbRepo {
  static const int dbOverallVersion = 1;
  static Future<Database> _openDatabase(String path) => openDatabase(
        path,
        onConfigure: (db) async {
          await db.execute("PRAGMA foreign_keys = ON");
        },
        version: dbOverallVersion,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < dbOverallVersion) {
            await initialMigrations[0](db);
          }
        },
      );
  static List<Future<void> Function(Database)> initialMigrations = [
    (db) async {
      await db.execute("CREATE TABLE userVersions (userId TEXT UNIQUE, version INT)");
    }
  ];

  static Future<DbRepo> createDatabase(PluginRepo plugins, {String? path, bool inMemory = false}) async {
    if (path == ":memory:") {
      inMemory = true;
    } else if (path != null && inMemory) {
      throw "createDatabase() called with non-null filepath $path *and* inMemory = true. Must be one or the other.";
    } else if (path == null && !inMemory) {
      throw "createDatabase() called with null filepath and inMemory = false. Either set the filepath, or set inMemory = true.";
    }

    // At this point we are in one of three states:
    // - path == ":memory:" and inMemory = true
    // - path == null and inMemory = true
    // - path != null and path != ":memory:", inMemory = false
    // => (path ?? ":memory:") = ":memory:" if inMemory = true, and some value != ":memory:" if inMemory = false.

    final db = await _openDatabase(path ?? ":memory:");

    final userVersionRows = await db.query("userVersions", columns: ["userId", "version"]);
    final userVersions = Map.fromEntries(
      userVersionRows.map(
        (row) => MapEntry(row["userId"] as String, row["version"] as int),
      ),
    );

    for (final entry in plugins.dbUsers.entries) {
      final dbUserId = entry.key;
      final dbUser = entry.value;
      int version = userVersions[entry.key] ?? 0;
      await db.transaction((txn) async {
        final migrations = dbUser.migrations;
        if (version > migrations.length) {
          throw "DbUser $dbUserId is compiled for a lower db version ${migrations.length} than found in the database $version";
        }
        while (version < migrations.length) {
          await migrations[version](txn);
          version += 1;
        }

        await txn.update(
          "userVersions",
          {
            "version": version,
          },
          where: "userId = ?",
          whereArgs: [dbUserId],
        );
      });
    }

    return DbRepo._(
      db: LockedRef(db),
      library: plugins.libraryDbUser,
      inMemory: inMemory,
    );
  }

  final LockedRef<Database> db;
  final bool inMemory;
  final LibraryDbUser library;

  DbRepo._({
    required this.db,
    required this.inMemory,
    required this.library,
  });

  // This function is called after large-scale changes to the database take place (e.g. restores or clears).
  // TODO fill this in to update any e.g. reactive streams
  Future<void> updateAllListeners() async {}

  // We cannot export the database contents directly via SQLite into an Android user filesystem.
  // SQLite does not interact with Android's file-based controls well.
  // Therefore the closest thing is to
  // - close the database
  // - read the internal database file, which we assume is accessible via the Flutter filesystem interface.
  // - reopen the database
  Future<Uint8List> getDatabaseBytes() {
    if (inMemory) {
      throw "Cannot extract bytes from in-memory database";
    }
    return db.swap<Uint8List>((db) async {
      final databasePath = db.path;
      // It's best practice to vacuum the database to remove old and potentially large records.
      await db.execute("VACUUM");
      await db.close();

      final bytes = await File(databasePath).readAsBytes();

      final newDb = await _openDatabase(databasePath);

      return (newDb, bytes);
    });
  }

  // As above, we can't open a database file from an Android user filesystem directly.
  // Therefore we implement restore by
  // - closing the old database
  // - copying the new database bytes into the internal database file
  // - reopen the internal database file, which should have the new data
  Future<void> restoreDatabaseBytes(Stream<List<int>> newBytes) async {
    if (inMemory) {
      throw "Cannot restore bytes for in-memory database";
    }
    await db.swap((db) async {
      final databasePath = db.path;
      await db.close();

      final writableFile = File(databasePath).openWrite();
      await newBytes.forEach((byteBlock) => writableFile.add(byteBlock));
      writableFile.close();

      final newDb = await _openDatabase(databasePath);
      return (newDb, ());
    });
    await updateAllListeners();
  }

  // Useful for debug modes
  Future<void> clearDatabase() async {
    // Use swap here to block any database transactions from being attempted
    await db.swap((db) async {
      // https://stackoverflow.com/a/65743498
      await db.execute("PRAGMA writable_schema = 1;");
      await db.execute("DELETE FROM sqlite_master;");
      await db.execute("PRAGMA writable_schema = 0;");
      await db.execute("VACUUM;");
      await db.execute("PRAGMA integrity_check;");
      // TODO need to wrap this in a transaction?
      for (final migration in initialMigrations) {
        await migration(db);
      }
      return (db, ());
    });
    await updateAllListeners();
  }

  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor) callback) {
    return db.use((db) {
      return db.transaction(callback);
    });
  }

  Future<T> useLibrary<T>(Future<T> Function(DatabaseExecutor, LibraryDbUser) callback) {
    return db.use((db) {
      return db.transaction((txn) => callback(txn, library));
    });
  }
}
