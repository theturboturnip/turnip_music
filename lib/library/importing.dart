import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/library/data/db.dart';
import 'package:turnip_music/library/data/song.dart';
import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/data/tag_artist.dart';
import 'package:turnip_music/library/data/tag_user.dart';
import 'package:turnip_music/repos/db/db_repo.dart';

// TODO need to support "import x as y" somewhere.

abstract class Action<T> {
  // TODO make this abstract
  Future<void> execute(DatabaseExecutor txn, ImportSession session, LibraryDbUser library) async {
    throw UnimplementedError();
  }
}

class ActionRef<TData, T extends Action<TData>> {
  final int id;
  final TData? dbData; // If non-null, it's a database ID and this was the object in the database

  ActionRef.actionIndex(this.id) : dbData = null;
  ActionRef.databaseId(this.id, TData this.dbData);
}

// class CreatePlaylistAction extends Action<Playlist> {
//   final String newPlaylistName;

//   CreatePlaylistAction({required this.newPlaylistName});
// }
// typedef PlaylistRef = ActionRef<Playlist, CreatePlaylistAction>;

/// Tags

class ImportTagAction extends Action<UserTag> {
  ImportTagAction({required this.tagName});

  final String tagName;
}

typedef TagRef = ActionRef<UserTag, ImportTagAction>;

/// Artists

abstract class ImportArtistAction extends Action<Artist> {
  BackendArtist get importedData;
}

typedef ArtistRef = ActionRef<Artist, ImportArtistAction>;

class CreateNewArtist extends ImportArtistAction {
  @override
  final BackendArtist importedData;
  final String newName;

  CreateNewArtist({
    required this.importedData,
    required this.newName,
  });
}

class ForcedLinkToExistingArtist extends ImportArtistAction {
  @override
  final BackendArtist importedData;
  final ArtistRef existingArtist;

  ForcedLinkToExistingArtist({
    required this.importedData,
    required this.existingArtist,
  });
}

// TODO SuggestedLinkToExistingArtist

/// Albums

abstract class ImportAlbumAction extends Action<Album> {
  BackendAlbum get importedData;
  List<ArtistRef> get linkedArtists;
}

typedef AlbumRef = ActionRef<Album, ImportAlbumAction>;

class CreateNewAlbum extends ImportAlbumAction {
  @override
  final BackendAlbum importedData;
  @override
  final List<ArtistRef> linkedArtists;

  final String newName;

  CreateNewAlbum({
    required this.importedData,
    required this.linkedArtists,
    required this.newName,
  });
}

class ForcedLinkToExistingAlbum extends ImportAlbumAction {
  @override
  final BackendAlbum importedData;
  @override
  final List<ArtistRef> linkedArtists;

  final AlbumRef existingAlbum;

  ForcedLinkToExistingAlbum({
    required this.importedData,
    required this.linkedArtists,
    required this.existingAlbum,
  });
}

// TODO SuggestedLinkToExistinAlbum

/// Songs

abstract class ImportSongAction extends Action<Song> {
  BackendSong get importedData;
  // If it turns out the artists are already attached,
  // don't re-add them.
  List<ArtistRef> get newLinkedArtists;
  (AlbumRef, int disc, int tracks)? get newLinkedAlbum;
  TagRef? get linkToTag;
  // PlaylistRef? get appendToPlaylist;
}

typedef SongRef = ActionRef<Song, ImportSongAction>;

class CreateNewSong extends ImportSongAction {
  @override
  final BackendSong importedData;
  @override
  final List<ArtistRef> newLinkedArtists;
  @override
  final (AlbumRef, int disc, int tracks)? newLinkedAlbum;
  @override
  final TagRef? linkToTag;
  // final PlaylistRef? appendToPlaylist;

  final String newName;

  CreateNewSong({
    required this.newLinkedArtists,
    required this.newLinkedAlbum,
    required this.linkToTag,
    required this.importedData,
    required this.newName,
  });
}

class ForcedLinkToExistingSong extends ImportSongAction {
  @override
  final BackendSong importedData;
  @override
  final List<ArtistRef> newLinkedArtists;
  @override
  final (AlbumRef, int disc, int tracks)? newLinkedAlbum;
  @override
  final TagRef? linkToTag;
  // final PlaylistRef? appendToPlaylist;

  final SongRef existingSong;

  ForcedLinkToExistingSong({
    required this.importedData,
    required this.newLinkedArtists,
    required this.newLinkedAlbum,
    required this.linkToTag,
    required this.existingSong,
  });
}

// TODO SuggestedLinkToExistingSong

class ImportSession {
  final DbRepo db;

  final List<ImportTagAction> tagActions;
  final List<ImportArtistAction> artistActions;
  final List<ImportAlbumAction> albumActions;
  final List<ImportSongAction> songActions;

  Iterable<Action<dynamic>> get allActions => tagActions.cast<Action<dynamic>>().followedBy(artistActions).followedBy(albumActions).followedBy(songActions);

  ImportSession({required this.db})
      : tagActions = [],
        artistActions = [],
        albumActions = [],
        songActions = [];

  TagRef addTag(String tagName) {
    final ref = TagRef.actionIndex(tagActions.length);
    tagActions.add(ImportTagAction(tagName: tagName));
    return ref;
  }

  String resolveArtistRefLogicalName(ArtistRef ref) {
    while (ref.dbData == null) {
      switch (artistActions[ref.id]) {
        case CreateNewArtist newItem:
          return newItem.newName;
        case ForcedLinkToExistingArtist existing:
          assert(existing.existingArtist.id < ref.id);
          ref = existing.existingArtist;
      }
    }

    return ref.dbData!.name;
  }

  String resolveAlbumRefLogicalName(AlbumRef ref) {
    while (ref.dbData == null) {
      switch (albumActions[ref.id]) {
        case CreateNewAlbum newItem:
          return newItem.newName;
        case ForcedLinkToExistingAlbum existing:
          assert(existing.existingAlbum.id < ref.id);
          ref = existing.existingAlbum;
      }
    }

    return ref.dbData!.name;
  }

  String resolveSongRefLogicalName(SongRef ref) {
    while (ref.dbData == null) {
      switch (songActions[ref.id]) {
        case CreateNewSong newItem:
          return newItem.newName;
        case ForcedLinkToExistingSong existing:
          assert(existing.existingSong.id < ref.id);
          ref = existing.existingSong;
      }
    }

    return ref.dbData!.name;
  }

  Future<ArtistRef> addArtist(BackendArtist backendArtist) async {
    ArtistRef? existingArtist;

    for (final (revIndex, action) in artistActions.reversed.indexed) {
      final index = artistActions.length - 1 - revIndex;
      if (action.importedData.unstableId == backendArtist.unstableId) {
        existingArtist = ArtistRef.actionIndex(index);
        break;
      }
    }

    if (existingArtist == null) {
      final existingDbPair = await db.useLibrary((db, library) {
        return library.exactMatchArtistFromBackendUnstableId(db, backendArtist);
      });
      if (existingDbPair != null) {
        final (id, data) = existingDbPair;
        existingArtist = ArtistRef.databaseId(id.raw, data);
      }
    }

    final newRef = ArtistRef.actionIndex(artistActions.length);

    if (existingArtist == null) {
      artistActions.add(CreateNewArtist(
        importedData: backendArtist,
        newName: backendArtist.name,
      ));
    } else {
      artistActions.add(ForcedLinkToExistingArtist(
        importedData: backendArtist,
        existingArtist: existingArtist,
      ));
    }

    return newRef;
  }

  Future<AlbumRef> addAlbum(BackendAlbum backendAlbum, List<ArtistRef> artists) async {
    AlbumRef? existingAlbum;

    for (final (revIndex, action) in albumActions.reversed.indexed) {
      final index = albumActions.length - 1 - revIndex;
      if (action.importedData.unstableId == backendAlbum.unstableId) {
        existingAlbum = AlbumRef.actionIndex(index);
        break;
      }
    }

    if (existingAlbum == null) {
      final existingDbPair = await db.useLibrary((db, library) {
        return library.exactMatchAlbumFromBackendUnstableId(db, backendAlbum);
      });
      if (existingDbPair != null) {
        final (id, data) = existingDbPair;
        existingAlbum = AlbumRef.databaseId(id.raw, data);
      }
    }

    final newRef = AlbumRef.actionIndex(albumActions.length);

    if (existingAlbum == null) {
      albumActions.add(CreateNewAlbum(
        importedData: backendAlbum,
        linkedArtists: artists,
        newName: backendAlbum.name,
      ));
    } else {
      albumActions.add(ForcedLinkToExistingAlbum(
        importedData: backendAlbum,
        linkedArtists: artists,
        existingAlbum: existingAlbum,
      ));
    }

    return newRef;
  }

  Future<SongRef?> addSong(
    BackendSong backendSong,
    List<ArtistRef> artists,
    (AlbumRef, int disc, int track)? album,
    TagRef? linkedTag,
  ) async {
    SongRef? existing;

    for (final (revIndex, action) in songActions.reversed.indexed) {
      final index = songActions.length - 1 - revIndex;
      if (action.importedData.unstableId == backendSong.unstableId) {
        existing = SongRef.actionIndex(index);
        break;
      }
    }

    if (existing == null) {
      final existingDbPair = await db.useLibrary((db, library) {
        return library.exactMatchSongFromBackendUnstableId(db, backendSong);
      });
      if (existingDbPair != null) {
        final (id, data) = existingDbPair;
        existing = SongRef.databaseId(id.raw, data);
      }
    }

    final newRef = SongRef.actionIndex(songActions.length);

    if (existing == null) {
      songActions.add(CreateNewSong(
        newLinkedArtists: artists,
        newLinkedAlbum: album,
        linkToTag: linkedTag,
        importedData: backendSong,
        newName: backendSong.name,
      ));
    } else {
      songActions.add(ForcedLinkToExistingSong(
        importedData: backendSong,
        newLinkedArtists: artists,
        newLinkedAlbum: album,
        linkToTag: linkedTag,
        existingSong: existing,
      ));
    }

    return newRef;
  }

  Future<void> execute(LibraryDbUser library) {
    return db.transaction((txn) async {
      for (final action in tagActions) {
        await action.execute(txn, this, library);
      }
      for (final action in artistActions) {
        await action.execute(txn, this, library);
      }
      for (final action in albumActions) {
        await action.execute(txn, this, library);
      }
      for (final action in songActions) {
        await action.execute(txn, this, library);
      }
    });
  }
}
