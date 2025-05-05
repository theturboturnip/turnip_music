import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/library/data/art.dart';
import 'package:turnip_music/library/data/song.dart';
import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/data/tag_artist.dart';
import 'package:turnip_music/repos/db/db_user.dart';

extension NullableGet<K, V> on Map<K, V> {
  V? get(K key) {
    return this[key];
  }
}

class LibraryDbUser extends DbUser {
  @override
  String get id => "com.theturboturnip.turnip_music.library";

  @override
  List<Future<void> Function(DatabaseExecutor)> get migrations => [
        (DatabaseExecutor db) async {
          // Art table
          await db.execute(
            "CREATE TABLE Arts ( "
            "id INTEGER PRIMARY KEY, "
            "data BLOB NOT NULL "
            ");",
          );
          // Song table
          await db.execute(
            "CREATE TABLE Songs ( "
            "id INTEGER PRIMARY KEY, "
            "name TEXT NOT NULL, "
            "lengthSeconds INTEGER NOT NULL, "
            "art INTEGER REFERENCES Arts(id) ON DELETE NO ACTION "
            ");",
          );
          // BackendSongs table
          await db.execute(
            "CREATE TABLE BackendSongs ( "
            "id INTEGER PRIMARY KEY, "
            "logicalSongId INTEGER NOT NULL REFERENCES Songs(id) ON DELETE CASCADE, "
            "backend TEXT NOT NULL, "
            "stableId TEXT, " // nullable
            "unstableId TEXT NOT NULL, "
            "playbackPriority INTEGER NOT NULL, "
            "name TEXT NOT NULL, "
            "firstArtist TEXT, " // nullable
            "firstAlbum TEXT, " // nullable
            "extra TEXT, " // nullable
            "coverArt TEXT " // nullable
            ");",
          );
          // Album table
          await db.execute(
            "CREATE TABLE Albums ( "
            "id INTEGER PRIMARY KEY, "
            "name TEXT NOT NULL, "
            "art INTEGER REFERENCES Arts(id) ON DELETE NO ACTION "
            ");",
          );
          // BackendAlbum table
          await db.execute(
            "CREATE TABLE BackendAlbums ( "
            "id INTEGER PRIMARY KEY, "
            "logicalAlbumId INTEGER NOT NULL REFERENCES Albums(id) ON DELETE CASCADE, "
            "backend TEXT NOT NULL, "
            "stableId TEXT, " // nullable
            "unstableId TEXT NOT NULL, " // nullable
            "name TEXT NOT NULL, "
            "firstArtist TEXT, " // nullable
            "extra TEXT, " // nullable
            "coverArt TEXT, " // nullable
            "tracks TEXT NOT NULL" // JSON encoded
            ");",
          );
          // Artist table
          await db.execute(
            "CREATE TABLE Artists ( "
            "id INTEGER PRIMARY KEY, "
            "name TEXT NOT NULL, "
            "art INTEGER REFERENCES Arts(id) ON DELETE NO ACTION "
            ");",
          );
          // ArtistMetadata table
          await db.execute(
            "CREATE TABLE BackendArtists ( "
            "id INTEGER PRIMARY KEY, "
            "logicalArtistId INTEGER NOT NULL REFERENCES Artists(id) ON DELETE CASCADE, "
            "backend TEXT NOT NULL, "
            "stableId TEXT, " // nullable
            "unstableId TEXT NOT NULL, "
            "name TEXT NOT NULL, "
            "extra TEXT, " // nullable
            "coverArt TEXT " // nullable
            ");",
          );
          // UserTag table
          await db.execute(
            "CREATE TABLE UserTags ( "
            "name TEXT NOT NULL UNIQUE"
            ");",
          );
          // LinkSongToAlbum table
          await db.execute(
            "CREATE TABLE LinkSongToAlbum ("
            "songId INTEGER NOT NULL REFERENCES Songs(id) ON DELETE CASCADE, "
            "albumId INTEGER NOT NULL REFERENCES Albums(id) ON DELETE CASCADE, "
            "disc INTEGER, "
            "track INTEGER "
            ");",
          );
          // LinkSongToArtist table
          await db.execute(
            "CREATE TABLE LinkSongToArtist ("
            "songId INTEGER NOT NULL REFERENCES Songs(id) ON DELETE CASCADE, "
            "artistId INTEGER NOT NULL REFERENCES Artists(id) ON DELETE CASCADE, "
            "artistOrderInSong INTEGER " // nullable, named "order" in SongToArtist class but that is a SQL keyword
            ");",
          );
          // LinkSongToUserTag table
          await db.execute(
            "CREATE TABLE LinkSongToUserTag ("
            "songId INTEGER NOT NULL REFERENCES Songs(id) ON DELETE CASCADE, "
            "userTagId INTEGER NOT NULL REFERENCES Songs(id) ON DELETE CASCADE, "
            "UNIQUE(songId, userTagId) ON CONFLICT IGNORE"
            ");",
          );
        }
      ];

  Future<Artist> getArtist(DatabaseExecutor db, ArtistId id) async {
    final rows = await db.query(
      "Artists",
      columns: ["name", "art"],
      where: "id = ?",
      whereArgs: [id.raw],
    );
    final row = rows.first;
    final rawArtId = row["art"] as int?;
    final artId = rawArtId == null ? null : ArtId(rawArtId);
    return Artist(
      name: row["name"] as String,
      art: artId,
    );
  }

  Future<Album> getAlbum(DatabaseExecutor db, AlbumId id) async {
    final rows = await db.query(
      "Albums",
      columns: ["name", "art"],
      where: "id = ?",
      whereArgs: [id.raw],
    );
    final row = rows.first;
    final rawArtId = row["art"] as int?;
    final artId = rawArtId == null ? null : ArtId(rawArtId);
    return Album(
      name: row["name"] as String,
      art: artId,
    );
  }

  Future<Song> getSong(DatabaseExecutor db, SongId id) async {
    final rows = await db.query(
      "Songs",
      columns: ["name", "lengthSeconds", "art"],
      where: "id = ?",
      whereArgs: [id.raw],
    );
    final row = rows.first;
    final rawArtId = row["art"] as int?;
    final artId = rawArtId == null ? null : ArtId(rawArtId);
    return Song(
      name: row["name"] as String,
      lengthSeconds: row["lengthSeconds"] as int,
      art: artId,
    );
  }

  Future<(ArtistId, Artist)?> exactMatchArtistFromBackendUnstableId(DatabaseExecutor db, BackendArtist artist) async {
    final rows = await db.query(
      "BackendArtists",
      columns: ["logicalArtistId"],
      distinct: true,
      where: "backend = ? AND unstableId = ?",
      whereArgs: [artist.backend, artist.unstableId],
    );
    final row = rows.firstOrNull;
    if (row != null) {
      final rawId = row["logicalArtistId"]! as int;
      final id = ArtistId(rawId);
      // TODO combine this with the first db transaction
      final data = await getArtist(db, id);
      return (id, data);
    }
    return null;
  }

  Future<(AlbumId, Album)?> exactMatchAlbumFromBackendUnstableId(DatabaseExecutor db, BackendAlbum artist) async {
    final rows = await db.query(
      "BackendAlbums",
      columns: ["logicalAlbumId"],
      distinct: true,
      where: "backend = ? AND unstableId = ?",
      whereArgs: [artist.backend, artist.unstableId],
    );
    final row = rows.firstOrNull;
    if (row != null) {
      final rawId = row["logicalAlbumId"]! as int;
      final id = AlbumId(rawId);
      // TODO combine this with the first db transaction
      final data = await getAlbum(db, id);
      return (id, data);
    }
    return null;
  }

  Future<(SongId, Song)?> exactMatchSongFromBackendUnstableId(DatabaseExecutor db, BackendSong artist) async {
    final rows = await db.query(
      "BackendSongs",
      columns: ["logicalSongId"],
      distinct: true,
      where: "backend = ? AND unstableId = ?",
      whereArgs: [artist.backend, artist.unstableId],
    );
    final row = rows.firstOrNull;
    if (row != null) {
      final rawId = row["logicalSongId"]! as int;
      final id = SongId(rawId);
      // TODO combine this with the first db transaction
      final data = await getSong(db, id);
      return (id, data);
    }
    return null;
  }
}
