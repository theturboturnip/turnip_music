import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/repos/db/db_user.dart';

class LibraryDbUser extends DbUser {
  @override
  int get dbVersion => 1;

  @override
  String get id => "com.theturboturnip.turnip_music.library";

  @override
  Future<void> upgradeDb(DatabaseExecutor db, int oldVersion) async {
    if (oldVersion < 1) {
      // Song table
      await db.execute(
        "CREATE TABLE Songs ( "
        "id INTEGER PRIMARY KEY, "
        "musicBrainzId TEXT, " // nullable
        "name TEXT NOT NULL, "
        "lengthSeconds INTEGER NOT NULL"
        ");",
      );
      // SongBacking table
      await db.execute(
        "CREATE TABLE SongBackings ( "
        "id INTEGER PRIMARY KEY, "
        "songId INTEGER NOT NULL REFERENCES Songs(id) ON DELETE CASCADE, "
        "backendId TEXT NOT NULL, "
        "idInBackend TEXT NOT NULL, "
        "fallbackMetadataInBackend TEXT NOT NULL, " // encoded as a JSON list
        "priorityInBackend INTEGER NOT NULL, "
        "coverArtInBackend TEXT " // nullable
        ");",
      );
      // Album table
      await db.execute(
        "CREATE TABLE Albums ( "
        "id INTEGER PRIMARY KEY, "
        "musicBrainzId TEXT, " // nullable
        "name TEXT NOT NULL "
        ");",
      );
      // AlbumBacking table
      await db.execute(
        "CREATE TABLE AlbumBackings ( "
        "id INTEGER PRIMARY KEY, "
        "albumId INTEGER NOT NULL REFERENCES Albums(id) ON DELETE CASCADE, "
        "backendId TEXT NOT NULL, "
        "idInBackend TEXT NOT NULL, "
        "fallbackMetadataInBackend TEXT NOT NULL, " // encoded as a JSON list
        "coverArtInBackend TEXT " // nullable
        ");",
      );
      // Artist table
      await db.execute(
        "CREATE TABLE Artists ( "
        "id INTEGER PRIMARY KEY, "
        "musicBrainzId TEXT, " // nullable
        "name TEXT NOT NULL "
        ");",
      );
      // ArtistBacking table
      await db.execute(
        "CREATE TABLE ArtistBackings ( "
        "id INTEGER PRIMARY KEY, "
        "artistId INTEGER NOT NULL REFERENCES Artists(id) ON DELETE CASCADE, "
        "backendId TEXT NOT NULL, "
        "idInBackend TEXT NOT NULL, "
        "fallbackMetadataInBackend TEXT NOT NULL, " // encoded as a JSON list
        "coverArtInBackend TEXT " // nullable
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
  }
}
