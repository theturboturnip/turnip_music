import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/library/data/song.dart';
import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/data/tag_artist.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/library/pages/library_import_build_session.dart';

const debugLibrarySongs = [
  ("Leave the Door Open", ["Bruno Mars", "Anderson Paak"]),
  ("Fly As Me", ["Bruno Mars", "Anderson Paak"]),
  ("After Last Night", ["Bruno Mars", "Anderson Paak", "Thundercat", "Bootsy Collins"]),
  ("Smokin Out The Window", ["Bruno Mars", "Anderson Paak"]),
  ("Put On A Smile", ["Bruno Mars", "Anderson Paak"]),
  ("777", ["Bruno Mars", "Anderson Paak"]),
  ("Skate", ["Bruno Mars", "Anderson Paak"]),
  ("Love's Train", ["Bruno Mars", "Anderson Paak"]),
  ("Blast Off", ["Bruno Mars", "Anderson Paak"]),
];
const debugLibraryAlbums = [
  ("An Evening with Silk Sonic", ["Bruno Mars", "Anderson Paak"], [0, 1, 2, 3, 4, 5, 6, 7, 8])
];

const String debugDataBackendId = "dbg";

class DebugLibraryPlugin extends LibraryPlugin {
  @override
  String get id => "com.theturboturnip.turnip_music.library.debug";

  @override
  String get dataBackendId => debugDataBackendId;

  @override
  Widget get icon => Icon(Icons.bug_report);

  @override
  List<Future<void> Function(DatabaseExecutor)> get migrations => [];

  @override
  String get userVisibleName => "Debug Library";

  @override
  PluginSuppliedLibrarySearchBloc<PluginSuppliedLibrarySearchState> makeSearchBloc() => DebugLibrarySearchBloc();

  @override
  Future<void> addImportablesToSession(Iterable<PluginSuppliedImportable> items, ImportSession session) async {
    final knownArtists = <String, ArtistRef>{};
    for (final item in items) {
      switch (item) {
        case PluginSuppliedImportableAlbum album:
          final (name, artistNames, songIds) = album.data as (String, List<String>, List<int>);

          for (final artistName in artistNames) {
            if (knownArtists.containsKey(artistName)) {
              continue;
            }
            knownArtists[artistName] = await session.addArtist(BackendArtist(
              logicalArtistId: ArtistId.unspecified,
              backend: debugDataBackendId,
              stableId: artistName,
              unstableId: artistName,
              name: artistName,
              extra: null,
              coverArt: null,
            ));
          }
          final albumArtists = artistNames.map((artistName) => knownArtists[artistName]!).toList();
          final backendAlbum = BackendAlbum(
            logicalAlbumId: AlbumId.unspecified,
            backend: album.dataBackendId,
            stableId: album.unstableId,
            unstableId: album.unstableId,
            name: name,
            firstArtist: artistNames.firstOrNull,
            extra: null,
            coverArt: null,
            // (unstable song ID, song name, disc, track)
            tracks: songIds.indexed.map((indexAndSongId) {
              final (index, songId) = indexAndSongId;
              final song = debugLibrarySongs[songId];
              return (songId.toString(), song.$1, 0, index + 1);
            }).toList(),
          );
          final albumRef = await session.addAlbum(backendAlbum, albumArtists);

          for (final indexAndSongId in songIds.indexed) {
            final (index, songId) = indexAndSongId;
            final song = debugLibrarySongs[songId];

            for (final artistName in song.$2) {
              if (knownArtists.containsKey(artistName)) {
                continue;
              }
              knownArtists[artistName] = await session.addArtist(BackendArtist(
                logicalArtistId: ArtistId.unspecified,
                backend: debugDataBackendId,
                stableId: artistName,
                unstableId: artistName,
                name: artistName,
                extra: null,
                coverArt: null,
              ));
            }

            final songArtists = song.$2.map((artistName) => knownArtists[artistName]!).toList();

            final backendSong = BackendSong(
              logicalSongId: SongId.unspecified,
              backend: debugDataBackendId,
              stableId: null,
              unstableId: songId.toString(),
              name: song.$1,
              firstArtist: song.$2.firstOrNull,
              firstAlbum: backendAlbum.name,
              playbackPriority: 0,
              extra: null,
              coverArt: null,
            );

            await session.addSong(
              backendSong,
              songArtists,
              (albumRef, 0, index + 1),
              null,
            );
          }
        default:
          throw "Cannot import this importable";
      }
    }
  }
}

class DebugSearchState extends PluginSuppliedLibrarySearchState {
  final List<PluginSuppliedImportableAlbum> allAlbums;

  DebugSearchState({
    required super.loading,
    required this.allAlbums,
    List<PluginSuppliedImportableAlbum>? albums,
  }) : super(albums: albums ?? allAlbums);

  @override
  Image? imageFor(PluginSuppliedImportable item) => null;
}

class DebugLibrarySearchBloc extends PluginSuppliedLibrarySearchBloc<DebugSearchState> {
  DebugLibrarySearchBloc()
      : super(
          DebugSearchState(
            loading: false,
            allAlbums: debugLibraryAlbums.indexed
                .map(
                  (indexAndAlb) => PluginSuppliedImportableAlbum(
                    dataBackendId: debugDataBackendId,
                    unstableId: indexAndAlb.$1.toString(),
                    name: indexAndAlb.$2.$1,
                    artists: indexAndAlb.$2.$2.join(", "),
                    data: indexAndAlb.$2,
                  ),
                )
                .toList(),
          ),
        ) {
    on<UpdatePluginSuppliedLibrarySearchQuery>((event, emit) async {
      emit(DebugSearchState(
        loading: false,
        albums: state.allAlbums.where((album) => album.name.toLowerCase().contains(event.newFilter.toLowerCase())).toList(),
        allAlbums: state.allAlbums,
      ));
    });
  }
}
