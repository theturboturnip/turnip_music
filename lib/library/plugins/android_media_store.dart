import 'package:android_music_store/android_music_store.dart';
import 'package:android_music_store/data_models.dart' as amsdata;
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/library/pages/library_import.dart';

const androidMediaStoreBackendId = "ams";

class AndroidMediaStoreSelectorState {
  final List<amsdata.AlbumSummary>? albums;

  final int? selectedAlbumId;
  final List<amsdata.Song>? songsInAlbum;

  // TODO album art?

  AndroidMediaStoreSelectorState({
    required this.albums,
    required this.selectedAlbumId,
    required this.songsInAlbum,
  });

  List<BackendSetOfSongsToImport> getSongsToImport() {
    if (albums == null || selectedAlbumId == null || songsInAlbum == null) {
      return [];
    }
    final selectedAlbum = albums!.where((a) => a.id == selectedAlbumId).first;
    final backend_artists = <String, BackendSpecificArtist>{};
    final backend_songs = <String, BackendSpecificSong>{};
    final backend_albums = <String, BackendSpecificAlbum>{
      "$selectedAlbumId": BackendSpecificAlbum(
        name: selectedAlbum.title,
        suggestedMusicbrainzUuid: null,
      ),
    };
    for (final song in songsInAlbum!) {
      backend_artists["${song.mainArtistId}"] = BackendSpecificArtist(name: song.mainArtist, suggestedMusicbrainzUuid: null);
      backend_songs["${song.id}"] = BackendSpecificSong(
        name: song.title,
        suggestedMusicbrainzUuid: null,
        lengthS: song.durationMs ~/ 1000,
        album: BackendSpecificSongAlbumLink(
          albumId: "$selectedAlbumId",
          disc: song.discNumber,
          track: song.trackNumber,
        ),
        artistIds: [
          "${song.mainArtistId}",
        ],
      );
    }

    return [
      BackendSetOfSongsToImport(
        backendId: androidMediaStoreBackendId,
        userFacingName: selectedAlbum.title,
        artists: backend_artists,
        albums: backend_albums,
        songs: backend_songs,
      ),
    ];
  }
}

class AndroidMediaStoreSelectorEvent {}

class AndroidMediaStoreStartLoadingAlbums extends AndroidMediaStoreSelectorEvent {}

class AndroidMediaStoreSelectAlbumEvent extends AndroidMediaStoreSelectorEvent {
  final int selectedAlbumId;

  AndroidMediaStoreSelectAlbumEvent({required this.selectedAlbumId});
}

class AndroidMediaStoreSelectorBloc extends Bloc<AndroidMediaStoreSelectorEvent, AndroidMediaStoreSelectorState> {
  AndroidMediaStoreSelectorBloc()
      : super(
          AndroidMediaStoreSelectorState(
            albums: null,
            selectedAlbumId: null,
            songsInAlbum: null,
          ),
        ) {
    on<AndroidMediaStoreStartLoadingAlbums>((event, emit) async {
      List<amsdata.AlbumSummary>? albums;
      while (albums == null) {
        // TODO sorting albums
        albums = await AndroidMusicStore().listAllAlbums();
      }
      albums.sort((a, b) => a.title.compareTo(b.title));
      // TODO exclude album IDs already logged in the backend?
      //  - ah, but the album may only be partially loaded? so we should mark the albums as either
      //    1. not imported 2. partially imported 3. fully imported
      emit(AndroidMediaStoreSelectorState(
        albums: albums,
        selectedAlbumId: null,
        songsInAlbum: null,
      ));
    });
    on<AndroidMediaStoreSelectAlbumEvent>(
      (event, emit) async {
        final songs = await AndroidMusicStore().listSongsInAlbum(event.selectedAlbumId);
        emit(
          AndroidMediaStoreSelectorState(
            albums: state.albums,
            selectedAlbumId: event.selectedAlbumId,
            songsInAlbum: songs,
          ),
        );
      },
      transformer: sequential(),
    );
  }
  // context.read<LibraryImportBloc>().add(
  //               LibrarySelectSongsToImportEvent(
  //                 songGroupToImport: value,
  //               ),
  //             );
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
  int get dbVersion => 1;

  @override
  Future<void> upgradeDb(DatabaseExecutor db, int oldVersion) async {
    if (oldVersion < 1) {
      // no database for version 1.
    }
  }

  Widget? _makeGridView(List<amsdata.AlbumSummary>? albums, int? selectedAlbumId) {
    if (albums == null) {
      return null;
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: (albums[index].id == selectedAlbumId) ? 5.0 : 1.0,
          child: InkWell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(albums[index].title),
                Text(albums[index].mainArtist),
              ],
            ),
            onTap: () {
              context.read<AndroidMediaStoreSelectorBloc>().add(
                    AndroidMediaStoreSelectAlbumEvent(
                      selectedAlbumId: albums[index].id,
                    ),
                  );
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSelectSongSetsToImportWidget(BuildContext context) {
    return BlocProvider(
      create: (context) => AndroidMediaStoreSelectorBloc()..add(AndroidMediaStoreStartLoadingAlbums()),
      child: BlocBuilder<AndroidMediaStoreSelectorBloc, AndroidMediaStoreSelectorState>(
        builder: (context, state) {
          final songsToImport = state.getSongsToImport();
          context.read<LibraryImportBloc>().add(
                LibrarySelectSongsToImportEvent(
                  songSetsToImport: songsToImport,
                ),
              );
          return _makeGridView(state.albums, state.selectedAlbumId) ?? Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
