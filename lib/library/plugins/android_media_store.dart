import 'package:android_music_store/album_art_store.dart' as amsalbum;
import 'package:android_music_store/android_music_store.dart';
import 'package:android_music_store/data_models.dart' as amsdata;
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/library/data/song.dart';
import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/data/tag_artist.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/library/pages/library_import_build_session.dart';
import 'package:turnip_music/repos/db/db_repo.dart';

const androidMediaStoreBackendId = "ams";
// const androidMediaStoreMetadataOrigin = "mp3";

BackendAlbum amsBackendAlbum(amsdata.AlbumSummary album, List<amsdata.Song> songsInAlbum) {
  return BackendAlbum(
    logicalAlbumId: AlbumId.unspecified,
    backend: androidMediaStoreBackendId,
    stableId: null,
    unstableId: album.id.toString(),
    name: album.title,
    firstArtist: album.mainArtist,
    extra: null,
    coverArt: null, // TODO
    tracks: songsInAlbum
        .map((song) => (
              song.id.toString(),
              song.title,
              song.discNumber,
              song.trackNumber,
            ))
        .toList(),
  );
}

// class AndroidMediaStoreSelectorState {
//   final List<amsdata.AlbumSummary>? albums;

//   final int? selectedAlbumId;
//   final List<amsdata.Song>? songsInAlbum;

//   final amsalbum.AlbumArtStore albumArt;

//   AndroidMediaStoreSelectorState({
//     required this.albums,
//     required this.selectedAlbumId,
//     required this.songsInAlbum,
//     required this.albumArt,
//   });

//   ImportSessionGenerator? get importSessionGenerator {
//     if (albums == null || selectedAlbumId == null || songsInAlbum == null) {
//       return null;
//     } else {
//       return (DbRepo db) async {
//

//         return session;
//       };
//     }
//   }

//   /*
//   List<BackendSetOfSongsToImport> getSongsToImport() {
//     if (albums == null || selectedAlbumId == null || songsInAlbum == null) {
//       return [];
//     }
//     final selectedAlbum = albums!.where((a) => a.id == selectedAlbumId).first;
//     final backendArtists = <String, BackendSpecificArtist>{};
//     final backendSongs = <String, BackendSpecificSong>{};
//     final backendAlbums = <String, BackendSpecificAlbum>{
//       "$selectedAlbumId": BackendSpecificAlbum(
//         name: selectedAlbum.title,
//         metadatas: [
//           BackendSong(
//             albumId: AlbumId.unspecified,
//             origin: androidMediaStoreMetadataOrigin,
//             id: null,
//             name: selectedAlbum.title,
//             firstArtist: null,
//             extra: null,
//             coverArt: null, // TODO?
//             tracks: songsInAlbum!.map((song) => (null, song.title, song.discNumber, song.trackNumber)).toList(),
//           )
//         ],
//       ),
//     };
//     for (final song in songsInAlbum!) {
//       backendArtists.putIfAbsent("${song.mainArtistId}", () {
//         return BackendSpecificArtist(
//           name: song.mainArtist,
//           metadatas: [
//             BackendArtist(
//               artistId: ArtistId.unspecified,
//               origin: androidMediaStoreMetadataOrigin,
//               stableId: null,
//               name: song.mainArtist,
//               extra: null,
//               coverArt: null,
//             )
//           ],
//         );
//       });
//       backendSongs["${song.id}"] = BackendSpecificSong(
//         name: song.title,
//         metadatas: [
//           SongMetadata(
//             songId: SongId.unspecified,
//             origin: androidMediaStoreMetadataOrigin,
//             id: null,
//             name: song.title,
//             firstArtist: song.mainArtist,
//             firstAlbum: selectedAlbum.title,
//             extra: null,
//             coverArt: null,
//           )
//         ],
//         lengthS: song.durationMs ~/ 1000,
//         album: BackendSpecificSongAlbumLink(
//           albumId: "$selectedAlbumId",
//           disc: song.discNumber,
//           track: song.trackNumber,
//         ),
//         artistIds: [
//           "${song.mainArtistId}",
//         ],
//       );
//     }

//     return [
//       BackendSetOfSongsToImport(
//         backendId: androidMediaStoreBackendId,
//         userFacingName: selectedAlbum.title,
//         artists: backendArtists,
//         albums: backendAlbums,
//         songs: backendSongs,
//       ),
//     ];
//   }
//   */
// }

class AndroidMediaStoreSearchState extends PluginSuppliedLibrarySearchState {
  final amsalbum.AlbumArtStore albumArt;
  final List<amsdata.AlbumSummary> allAlbums;

  AndroidMediaStoreSearchState({required super.loading, required super.albums, required this.allAlbums, required this.albumArt});

  @override
  Image? imageFor(PluginSuppliedImportable item) {
    switch (item) {
      case PluginSuppliedImportableAlbum a:
        return albumArt.getImage(a.unstableId);
      default:
        return null;
    }
  }
}

class AndroidMediaStoreStartLoadingAlbums extends PluginSuppliedLibrarySearchEvent {}

class AndroidMediaStoreUpdateAlbumArtEvent extends PluginSuppliedLibrarySearchEvent {
  final amsalbum.AlbumArtStore newArt;

  AndroidMediaStoreUpdateAlbumArtEvent({required this.newArt});
}

class AndroidMediaStoreSearchBloc extends PluginSuppliedLibrarySearchBloc<AndroidMediaStoreSearchState> {
  AndroidMediaStoreSearchBloc()
      : super(
          AndroidMediaStoreSearchState(
            loading: true,
            albums: [],
            allAlbums: [],
            albumArt: amsalbum.AlbumArtStore(),
          ),
        ) {
    on<AndroidMediaStoreStartLoadingAlbums>((event, emit) async {
      List<amsdata.AlbumSummary>? albums;
      while (albums == null) {
        albums = await AndroidMusicStore().listAllAlbums();
      }
      albums.sort((a, b) => a.title.compareTo(b.title));
      // Request art after sorting so we get the art we see first.
      AndroidMusicStore().requestArtsForAlbums(500 /* TODO */, albums.map((a) => a.id));
      // TODO exclude album IDs already logged in the backend?
      //  - ah, but the album may only be partially loaded? so we should mark the albums as either
      //    1. not imported 2. partially imported 3. fully imported
      emit(AndroidMediaStoreSearchState(
        loading: false,
        albums: albums
            .map((summary) => PluginSuppliedImportableAlbum(
                  dataBackendId: androidMediaStoreBackendId,
                  unstableId: summary.id.toString(),
                  name: summary.title,
                  artists: summary.mainArtist,
                  data: summary,
                ))
            .toList(),
        allAlbums: albums,
        albumArt: state.albumArt,
      ));
    });
    on<UpdatePluginSuppliedLibrarySearchQuery>((event, emit) async {
      emit(AndroidMediaStoreSearchState(
        loading: false,
        albums: state.allAlbums
            .where((summary) => summary.title.toLowerCase().contains(event.newFilter.toLowerCase()))
            .map((summary) => PluginSuppliedImportableAlbum(
                  dataBackendId: androidMediaStoreBackendId,
                  unstableId: summary.id.toString(),
                  name: summary.title,
                  artists: summary.mainArtist,
                  data: summary,
                ))
            .toList(),
        allAlbums: state.allAlbums,
        albumArt: state.albumArt,
      ));
    });
    // on<AndroidMediaStoreSelectAlbumEvent>(
    //   (event, emit) async {
    //     late final List<amsdata.Song>? songs;
    //     if (event.selectedAlbumId != null) {
    //       songs = await AndroidMusicStore().listSongsInAlbum(event.selectedAlbumId);
    //     } else {
    //       songs = null;
    //     }

    //     final newState = AndroidMediaStoreSelectorState(
    //       albums: state.albums,
    //       selectedAlbumId: event.selectedAlbumId,
    //       songsInAlbum: songs,
    //       albumArt: state.albumArt,
    //     );

    //     final sessionGenerator = newState.importSessionGenerator;
    //     if (sessionGenerator != null) {
    //       parentBloc.add(
    //         LibrarySelectSongsToImportEvent(
    //           sessionGenerator: sessionGenerator,
    //         ),
    //       );
    //     }

    //     emit(
    //       newState,
    //     );
    //   },
    //   transformer: sequential(),
    // );
    on<AndroidMediaStoreUpdateAlbumArtEvent>(
      (event, emit) async {
        emit(
          AndroidMediaStoreSearchState(
            loading: state.loading,
            albums: state.albums,
            allAlbums: state.allAlbums,
            albumArt: event.newArt,
          ),
        );
      },
    );
    AndroidMusicStore().registerNewAlbumArtNotifier(
      (newArt) => add(
        AndroidMediaStoreUpdateAlbumArtEvent(
          newArt: newArt,
        ),
      ),
    );

    add(AndroidMediaStoreStartLoadingAlbums());
  }

  @override
  Future<void> close() {
    AndroidMusicStore().registerNewAlbumArtNotifier(null);
    return super.close();
  }
}

class AndroidMediaStoreLibraryPlugin extends LibraryPlugin {
  @override
  String get id => "com.theturboturnip.turnip_music.library.android_media_store";

  @override
  Widget get icon => Icon(Icons.android);

  @override
  String get userVisibleName => "Android Media Store";

  @override
  String get dataBackendId => androidMediaStoreBackendId;

  @override
  List<Future<void> Function(DatabaseExecutor)> get migrations => [];

  @override
  PluginSuppliedLibrarySearchBloc makeSearchBloc() => AndroidMediaStoreSearchBloc();

  @override
  Future<void> addImportablesToSession(Iterable<PluginSuppliedImportable> items, ImportSession session) async {
    final knownArtists = <int, ArtistRef>{};
    for (final item in items) {
      switch (item) {
        case PluginSuppliedImportableAlbum album:
          final selectedAlbum = album.data as amsdata.AlbumSummary;
          final songsInAlbum = await AndroidMusicStore().listSongsInAlbum(selectedAlbum.id);

          late final List<ArtistRef> importedAlbumArtists;
          if (selectedAlbum.mainArtistId != 0) {
            knownArtists[selectedAlbum.mainArtistId] = await session.addArtist(BackendArtist(
              logicalArtistId: ArtistId.unspecified,
              backend: androidMediaStoreBackendId,
              stableId: null,
              unstableId: selectedAlbum.mainArtistId.toString(),
              name: selectedAlbum.mainArtist,
              extra: null,
              coverArt: null,
            ));
            importedAlbumArtists = [
              knownArtists[selectedAlbum.mainArtistId]!,
            ];
          } else {
            importedAlbumArtists = [];
          }
          for (final song in songsInAlbum!) {
            if (song.mainArtistId != 0 && !knownArtists.containsKey(song.mainArtistId)) {
              knownArtists[song.mainArtistId] = await session.addArtist(BackendArtist(
                logicalArtistId: ArtistId.unspecified,
                backend: androidMediaStoreBackendId,
                stableId: null,
                unstableId: song.mainArtistId.toString(),
                name: song.mainArtist,
                extra: null,
                coverArt: null,
              ));
            }
          }

          final backendAlbum = amsBackendAlbum(selectedAlbum, songsInAlbum!);
          final albumRef = await session.addAlbum(backendAlbum, importedAlbumArtists);
          final songs = songsInAlbum!.toList();
          songs.sortByCompare((song) => (song.discNumber, song.trackNumber), (dtA, dtB) {
            final cmp1 = dtA.$1.compareTo(dtB.$1);
            if (cmp1 == 0) {
              return dtA.$2.compareTo(dtB.$2);
            }
            return cmp1;
          });
          for (final song in songs) {
            final backendSong = BackendSong(
              logicalSongId: SongId.unspecified,
              backend: androidMediaStoreBackendId,
              stableId: null,
              unstableId: song.id.toString(),
              name: song.title,
              firstArtist: song.mainArtist,
              firstAlbum: backendAlbum.name,
              playbackPriority: 0,
              extra: null,
              coverArt: null, // TODO
            );
            final List<ArtistRef> artists = [song.mainArtistId].map((id) => knownArtists[id]).whereType<ArtistRef>().toList();

            await session.addSong(
              backendSong,
              artists,
              (albumRef, song.discNumber, song.trackNumber),
              null,
            );
          }
        default:
          throw "Cannot import this importable";
      }
    }
  }
}
