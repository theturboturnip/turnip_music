import 'package:android_music_store/album_art_store.dart';
import 'package:android_music_store/data_models.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:android_music_store/android_music_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<AlbumSummary> _albums = [];
  AlbumArtStore? _albumArts;
  final _androidMusicStorePlugin = AndroidMusicStore();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    print("initPlatformState");
    List<AlbumSummary> albums;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      albums = await _androidMusicStorePlugin.listAllAlbums() ?? [];
    } on PlatformException {
      print("failed to get albums");
      return;
    }

    _androidMusicStorePlugin.registerNewAlbumArtNotifier(
      (newArt) => setState(
        () {
          _albumArts = newArt;
        },
      ),
    );
    _androidMusicStorePlugin.requestArtsForAlbums(
      250,
      albums.map(
        (e) => e.id,
      ),
    );

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      print("unmounted");
      return;
    }

    setState(() {
      print("new albums");

      _albums = albums;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Albums'),
        ),
        body: SafeArea(
          child: ListView.builder(
            itemCount: _albums.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text("No Album"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongView(
                          albumId: null,
                        ),
                      ),
                    );
                  },
                );
              }
              final album = _albums[index - 1];
              return ListTile(
                title: Text(album.title),
                subtitle: Text("${album.mainArtist}, ${album.numberOfSongs} tracks"),
                leading: _albumArts?.getImage("${album.id}", width: 70, height: 70),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongView(
                        albumId: album.id,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class SongView extends StatefulWidget {
  const SongView({super.key, this.albumId});

  final int? albumId;

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  List<Song> _songs = [];
  final _androidMusicStorePlugin = AndroidMusicStore();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    print("_SongViewSTate init");
    List<Song> songs;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      songs = await _androidMusicStorePlugin.listSongsInAlbum(widget.albumId) ?? [];
    } on PlatformException {
      print("failed to load songs");
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      print("unmounted in songviwestate");
      return;
    }

    setState(() {
      _songs = songs;
      print("songs $songs");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Songs for Album ${widget.albumId}'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              return ListTile(
                title: Text(song.title),
                subtitle: Text(song.mainArtist),
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text("${song.discNumber}:${song.trackNumber}"),
                  ),
                ),
                trailing: Text("${song.durationMs ~/ (60 * 1000)}:${(song.durationMs ~/ 1000) % 60}"),
              );
            },
          ),
        ),
      ),
    );
  }
}
