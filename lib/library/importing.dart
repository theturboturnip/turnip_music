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
  final String setName;

  ImportPlanBackendSongSet({
    required this.setName,
  });

  List<ImportPlanBackendSong> get songs;
}

class ImportPlanBackendSongSetAsAlbum extends ImportPlanBackendSongSet {
  // The (backendId, idWithinBackend) for the backend's album
  final (String, String) backendId;

  // If not null, the album that already exists in the database that this (backendId, idWithinBackend)
  // will be linked to.
  final AlbumId? preexistingAlbumId;

  final String name;
  final String? linkedFromMusicbrainzId;

  // The set of songs to import, that will be linked to the album once imported
  @override
  final List<ImportPlanBackendSongLinkedToAlbum> songs;

  ImportPlanBackendSongSetAsAlbum({
    required super.setName,
    required this.backendId,
    required this.preexistingAlbumId,
    required this.name,
    required this.linkedFromMusicbrainzId,
    required this.songs,
  });

  // TODO artists
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
  final SongId? preexistingSongId;

  // If preexistingSongId = null, the metadata for the new song that will be imported
  final String name;
  final String? linkedFromMusicbrainzId;

  ImportPlanBackendSong({
    required this.backendId,
    required this.backendName,
    required this.preexistingSongId,
    required this.name,
    required this.linkedFromMusicbrainzId,
  });

  // TODO artists
}

class ImportPlanBackendSongLinkedToAlbum extends ImportPlanBackendSong {
  final int discNumber;
  final int trackNumber;

  ImportPlanBackendSongLinkedToAlbum({
    required super.backendId,
    required super.backendName,
    required super.preexistingSongId,
    required super.name,
    required super.linkedFromMusicbrainzId,
    required this.discNumber,
    required this.trackNumber,
  });
}

class ImportPlanBackendSongSetAsTag extends ImportPlanBackendSongSet {
  final String tagName;
  // The set of songs to import, that will be linked to the tag once imported
  @override
  final List<ImportPlanBackendSong> songs;

  ImportPlanBackendSongSetAsTag({
    required super.setName,
    required this.tagName,
    required this.songs,
  });
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
            setName: songSet.userFacingName,
            tagName: songSet.userFacingName,
            songs: songSet.songs.entries.map((song) {
              return ImportPlanBackendSong(
                backendId: (songSet.backendId, song.key),
                backendName: song.value.name,
                preexistingSongId: null, // TODO populate!
                name: song.value.name,
                linkedFromMusicbrainzId: null, // TODO populate!
              );
            }).toList(),
          );
        } else {
          // There is exactly one backend album used by every song.
          final album = songSet.albums.entries.first;
          return ImportPlanBackendSongSetAsAlbum(
            setName: songSet.userFacingName,
            backendId: (songSet.backendId, album.key),
            preexistingAlbumId: null, // TODO populate!
            name: album.value.name,
            linkedFromMusicbrainzId: null, // TODO populate!
            songs: songSet.songs.entries.map((song) {
              return ImportPlanBackendSongLinkedToAlbum(
                backendId: (songSet.backendId, song.key),
                backendName: song.value.name,
                preexistingSongId: null, // TODO populate!
                name: song.value.name,
                linkedFromMusicbrainzId: null, // TODO populate!
                discNumber: song.value.album!.disc,
                trackNumber: song.value.album!.track,
              );
            }).toList(),
          );
        }
      },
    ).toList(),
  );
}
