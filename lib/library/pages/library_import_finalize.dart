import 'package:flutter/material.dart';
import 'package:turnip_music/library/importing.dart';

final class LibraryImportFinalizePage extends StatelessWidget {
  const LibraryImportFinalizePage(this._toImport, {super.key});

  final List<BackendSetOfSongsToImport> _toImport;

  // Widget _buildNoAlbumFinalizer() {}

  Widget _buildImportSetPlan(ImportPlanBackendSongSet importSet) {
    String title;
    switch (importSet) {
      case ImportPlanBackendSongSetAsTag importAsTag:
        title = "Import '${importAsTag.setName}' as tag '${importAsTag.tagName}'";
      case ImportPlanBackendSongSetAsAlbum importAsAlbum:
        if (importAsAlbum.preexistingAlbumId == null) {
          title = "Import album '${importAsAlbum.setName}'";
          if (importAsAlbum.name != importAsAlbum.setName) {
            title += " as '${importAsAlbum.name}'";
          }
        } else {
          title = "Link '${importAsAlbum.setName}' to album '${importAsAlbum.name}'";
        }
        if (importAsAlbum.linkedFromMusicbrainzId != null) {
          title += " with MusicBrainz metadata";
        }
      default:
        throw "Invalid ImportPlanBackendSongSet type $importSet";
    }
    return ExpansionTile(
      title: Text(title),
      children: importSet.songs.map((song) {
        Widget? leading;
        if (song is ImportPlanBackendSongLinkedToAlbum) {
          leading = Text(
            "${song.discNumber}:${song.trackNumber}",
          );
        }

        String title;
        if (song.preexistingSongId == null) {
          title = "Import '${song.backendName}'";
          if (song.name != song.backendName) {
            title += " as '${song.name}'";
          }
        } else {
          title = "Link '${song.backendName}' to '${song.name}'";
        }
        if (song.linkedFromMusicbrainzId != null) {
          title += " with MusicBrainz metadata";
        }

        return ListTile(
          leading: leading,
          title: Text(title),
        );
      }).toList(),
    );
  }

  Widget _buildFinalizer(List<BackendSetOfSongsToImport> toImport) {
    final plan = generateImportPlan(toImport);

    // final albums = toImport.albums.entries.whereType<MapEntry<String?, BackendSpecificAlbum>>().toList();
    // if (toImport.songs.values.any((song) => song.album == null)) {
    //   albums.add(
    //     MapEntry(
    //       null,
    //       BackendSpecificAlbum(
    //         name: "No Album",
    //         suggestedMusicbrainzUuid: null,
    //       ),
    //     ),
    //   );
    // }
    return ListView.builder(
      itemCount: plan.importSets.length,
      itemBuilder: (context, index) {
        final importSet = plan.importSets[index];
        return _buildImportSetPlan(importSet);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Importing ${_toImport.length} groups"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildFinalizer(_toImport),
      // BlocProvider(
      //   create: (context) => LibraryImportBloc(context.read<PluginRepo>()),
      //   child: Padding(
      //     padding: EdgeInsets.all(16),
      //     child: BlocBuilder<LibraryImportBloc, LibraryImportState>(
      //       builder: (context, state) {
      //         return Column(
      //           mainAxisSize: MainAxisSize.max,
      //           children: [
      //             _buildImporterSelector(context, state),
      //           ],
      //         );
      //       },
      //     ),
      //   ),
      // ),
    );
  }
}
