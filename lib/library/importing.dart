import 'package:turnip_music/library/data/song.dart';
import 'package:turnip_music/library/data/tag_album.dart';

/// A set of songs harvested from a backend for importing
class BackendSetOfSongsToImport {
  final String backendId;
  final String userFacingName;

  final Map<String, BackendSpecificArtist> artists;
  final Map<String, BackendSpecificAlbum> albums;
  final Map<String, BackendSpecificSong> songs;

  BackendSetOfSongsToImport({
    required this.backendId,
    required this.userFacingName,
    required this.artists,
    required this.albums,
    required this.songs,
  });
}

class BackendSpecificSongAlbumLink {
  final String albumId;
  final int disc;
  final int track;

  BackendSpecificSongAlbumLink({
    required this.albumId,
    required this.disc,
    required this.track,
  });
}

class BackendSpecificSong {
  final String name;
  final String? suggestedMusicbrainzUuid;
  final int lengthS;
  final BackendSpecificSongAlbumLink? album;
  final List<String> artistIds;

  BackendSpecificSong({
    required this.name,
    required this.suggestedMusicbrainzUuid,
    required this.lengthS,
    required this.album,
    required this.artistIds,
  });
}

class BackendSpecificAlbum {
  final String name;
  final String? suggestedMusicbrainzUuid;

  BackendSpecificAlbum({
    required this.name,
    required this.suggestedMusicbrainzUuid,
  });
}

class BackendSpecificArtist {
  final String name;
  final String? suggestedMusicbrainzUuid;

  BackendSpecificArtist({
    required this.name,
    required this.suggestedMusicbrainzUuid,
  });
}

/// A plan for importing sets of songs, generated from BackendSetOfSongsToImport
class ImportPlan {
  final List<ImportPlanBackendSongSet> importSets;

  ImportPlan({
    required this.importSets,
  });
}

abstract class ImportPlanBackendSongSet {
  ImportPlanBackendSongSet();

  String get finalName;
  List<ImportPlanBackendSong> get songs;

  ImportPlanBackendSongSet withNewName(String newName);
}

class ImportPlanBackendSongSetAsAlbum extends ImportPlanBackendSongSet {
  // The (backendId, idWithinBackend) for the backend's song set
  final (String, String) backendId;
  final String backendName;

  // If not null, the album that already exists in the database that this (backendId, idWithinBackend)
  // will be linked to.
  final (AlbumId, Album)? preexistingAlbum;

  final String? newName;
  final String? newMusicbrainzId;

  @override
  String get finalName => newName ?? backendName;

  // The set of songs to import, that will be linked to the album once imported
  @override
  final List<ImportPlanBackendSongLinkedToAlbum> songs;

  ImportPlanBackendSongSetAsAlbum({
    required this.backendId,
    required this.backendName,
    required this.preexistingAlbum,
    required this.newName,
    required this.newMusicbrainzId,
    required this.songs,
  });

  // TODO artists

  @override
  ImportPlanBackendSongSet withNewName(String newName) {
    return ImportPlanBackendSongSetAsAlbum(
      backendId: backendId,
      backendName: backendName,
      preexistingAlbum: preexistingAlbum,
      newName: newName,
      newMusicbrainzId: newMusicbrainzId,
      songs: songs,
    );
  }

  ImportPlanBackendSongSetAsAlbum withNewMetadata(String newName, String newMusicbrainzId, List<ImportPlanBackendSongLinkedToAlbum> newSongs) {
    return ImportPlanBackendSongSetAsAlbum(
      backendId: backendId,
      backendName: backendName,
      preexistingAlbum: preexistingAlbum,
      newName: newName,
      newMusicbrainzId: newMusicbrainzId,
      songs: newSongs,
    );
  }
}

// TODO
class ImportPlanBackendArtistLinkedToAlbum {}

class ImportPlanBackendSong {
  // The (backendId, idWithinBackend) for the backend's song, if we're importing one
  // null if we're only importing the song to fill out the album, not because we actually have the song
  final (String, String)? backendId;
  // The name this was referred to with on the backend
  final String backendName;

  // If not null, the song that already exists in the database that this (backendId, idWithinBackend) will be linked to.
  final (SongId, Song)? preexistingSong;

  // If preexistingSong = null, the metadata for the new song that will be imported
  final String? newName;
  final String? newMusicbrainzId;

  ImportPlanBackendSong({
    required this.backendId,
    required this.backendName,
    required this.preexistingSong,
    required this.newName,
    required this.newMusicbrainzId,
  });

  // TODO artists
}

class ImportPlanBackendSongLinkedToAlbum extends ImportPlanBackendSong {
  final int backendDiscNumber;
  final int backendTrackNumber;

  final SongToAlbum? preexistingSongToPreexistingAlbum;

  final int? newDiscNumber;
  final int? newTrackNumber;

  int get finalDiscNumber => newDiscNumber ?? (preexistingSongToPreexistingAlbum?.disc ?? backendDiscNumber);
  int get finalTrackNumber => newTrackNumber ?? (preexistingSongToPreexistingAlbum?.track ?? backendTrackNumber);

  ImportPlanBackendSongLinkedToAlbum({
    required super.backendId,
    required super.backendName,
    required this.backendDiscNumber,
    required this.backendTrackNumber,
    required super.preexistingSong,
    required this.preexistingSongToPreexistingAlbum,
    required super.newName,
    required super.newMusicbrainzId,
    required this.newDiscNumber,
    required this.newTrackNumber,
  });
}

class ImportPlanBackendSongSetAsTag extends ImportPlanBackendSongSet {
  final String backendName;
  final String? tagName;

  @override
  String get finalName => tagName ?? backendName;

  // The set of songs to import, that will be linked to the tag once imported
  @override
  final List<ImportPlanBackendSong> songs;

  ImportPlanBackendSongSetAsTag({
    required this.backendName,
    required this.tagName,
    required this.songs,
  });

  @override
  ImportPlanBackendSongSet withNewName(String newName) {
    return ImportPlanBackendSongSetAsTag(
      backendName: backendName,
      tagName: newName,
      songs: songs,
    );
  }
}

ImportPlan generateImportPlan(
  List<BackendSetOfSongsToImport> songSets,
  // {
  //   void Function(ImportPlan)? onImportPlansInProgress,
  // }
) {
  // Simple version
  return ImportPlan(
    importSets: songSets.map(
      (songSet) {
        if (songSet.albums.values.length != 1 || songSet.songs.values.any((song) => song.album == null)) {
          // The set of albums used by the songs is not single-element, or it may include null.
          // Either way, this should always be imported as a tag.
          return ImportPlanBackendSongSetAsTag(
            backendName: songSet.userFacingName,
            tagName: songSet.userFacingName,
            songs: songSet.songs.entries.map((song) {
              return ImportPlanBackendSong(
                backendId: (songSet.backendId, song.key),
                backendName: song.value.name,
                preexistingSong: null, // TODO populate!
                newName: null,
                newMusicbrainzId: null, // TODO populate!
              );
            }).toList(),
          );
        } else {
          // There is exactly one backend album used by every song.
          final album = songSet.albums.entries.first;
          return ImportPlanBackendSongSetAsAlbum(
            backendId: (songSet.backendId, album.key),
            backendName: album.value.name,
            preexistingAlbum: null, // TODO populate!
            newName: songSet.userFacingName, // TODO should this be null
            newMusicbrainzId: null, // TODO populate!
            songs: songSet.songs.entries.map((song) {
              return ImportPlanBackendSongLinkedToAlbum(
                backendId: (songSet.backendId, song.key),
                backendName: song.value.name,
                backendDiscNumber: song.value.album!.disc,
                backendTrackNumber: song.value.album!.track,
                preexistingSong: null, // TODO populate!
                preexistingSongToPreexistingAlbum: null, // TODO populate
                newName: null,
                newMusicbrainzId: null, // TODO populate!
                newDiscNumber: null,
                newTrackNumber: null,
              );
            }).toList(),
          );
        }
      },
    ).toList(),
  );
}
