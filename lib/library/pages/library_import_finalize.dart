import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/repos/musicbrainz/data.dart';
import 'package:turnip_music/repos/musicbrainz/musicbrainz_repo.dart';
import 'package:turnip_music/util/custom_expansion_tile.dart';

/*
final class LibraryImportFinalizeSet extends StatefulWidget {
  const LibraryImportFinalizeSet({super.key, required this.toImport});

  final ImportPlanBackendSongSet toImport;

  @override
  State<StatefulWidget> createState() => LibraryImportFinalizeSetState();
}

final class LibraryImportFinalizeSetState extends State<LibraryImportFinalizeSet> {
  late final TextEditingController nameControl;
  late ImportPlanBackendSongSet toImport;
  bool searching = false;
  MusizbrainzReleaseSearchResults? releaseSearch;
  String? releaseSearchErrorMessage;

  @override
  void initState() {
    super.initState();
    toImport = widget.toImport;
    nameControl = TextEditingController(text: widget.toImport.finalName);
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> widgets;
    switch (toImport) {
      case ImportPlanBackendSongSetAsAlbum album:
        widgets = [
          FilledButton(
            onPressed: () {
              setState(() {
                searching = true;
                releaseSearch = null;
                releaseSearchErrorMessage = null;
              });
              final search = MusicbrainzReleaseSearch(
                nameParts: album.finalName.split(" "),
                nTracks: null, //album.songs.length, // TODO need to clean up albums with dupe tracks
              );
              print("doing a search ${search.toUri()}");
              context
                  .read<MusicbrainzRepo>()
                  .searchReleases(
                    search,
                  )
                  .then(
                    (search) => setState(
                      () {
                        searching = false;
                        releaseSearch = search;
                        releaseSearchErrorMessage = null;
                      },
                    ),
                    onError: (error, stack) => setState(
                      () {
                        print(error);
                        print(stack);
                        searching = false;
                        releaseSearch = null;
                        releaseSearchErrorMessage = "$error";
                      },
                    ),
                  );
            },
            child: const Text("Search MusicBrainz"),
          ),
          if (searching) LinearProgressIndicator(),
          if (releaseSearch != null && releaseSearch!.releases.isNotEmpty != true) const Text("No search results!"),
          if (releaseSearch != null)
            ...releaseSearch!.releases.map(
              (release) {
                // Use the cover-art-archive https://musicbrainz.org/doc/Cover_Art_Archive/API to get the image.
                // This does not have any rate limiting currently https://musicbrainz.org/doc/Cover_Art_Archive/API#Rate_limiting_rules
                Widget leading = Image.network(
                  "https://coverartarchive.org/release/${release.id}/front",
                  // otherwise empty box TODO icon?
                  errorBuilder: (context, error, stack) => SizedBox.square(
                    dimension: 10,
                  ),
                );
                String subtitle = "";
                if (release.country == "XW") {
                  subtitle = "Worldwide";
                } else if (release.country != null) {
                  List<int> countryAsAlphabet = release.country!.toLowerCase().codeUnits.map((unit) => unit - 0x61).toList();
                  if (countryAsAlphabet.length == 2 && !countryAsAlphabet.any((unit) => (unit < 0) || (unit >= 26))) {
                    // Encode the country code as an emoji by encoding as pair of REGIONAL INDICATOR SYMBOL.
                    // The base for this is 0x1F1E6, add the character index in the alphabet to get the emoji
                    // See https://apps.timwhitlock.info/unicode/inspect?s=%F0%9F%87%A6%F0%9F%87%A9ADad
                    // See https://stackoverflow.com/a/42235254
                    subtitle = String.fromCharCodes([0x1F1E6 + countryAsAlphabet[0], 0x1F1E6 + countryAsAlphabet[1], 0x20]);
                  }
                  subtitle += release.country!;
                }
                if (release.disambiguation != null) {
                  subtitle += "${subtitle.isEmpty ? "" : ", "}${release.disambiguation}";
                }
                if (subtitle.isNotEmpty) {
                  subtitle += "\n";
                }
                if (release.media.isNotEmpty && !release.media.any((m) => m.format != release.media.first.format)) {
                  subtitle += "${release.media.length}x ${release.media.first.format ?? '??'}";
                } else {
                  subtitle += release.media.map((m) => m.format ?? '??').join("+");
                }
                subtitle += ", ${release.trackCount} total tracks";
                return ListTile(
                  leading: leading,
                  title: Text(release.title),
                  subtitle: Text(subtitle),
                );
              },
            ),
          if (releaseSearchErrorMessage != null) Text(releaseSearchErrorMessage!),
        ];
      case ImportPlanBackendSongSetAsTag tag:
        widgets = [];
      default:
        widgets = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Importing ${toImport.finalName}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, toImport),
        ),
      ),
      body: ListView(
        children: [
          // Button which moves from Album -> Tag but can't go back (not maintaining enough state :/)
          SegmentedButton(
            segments: [
              ButtonSegment(
                value: ImportPlanBackendSongSetAsTag,
                icon: const Icon(Icons.sell),
                label: const Text("as Tag"),
              ), // tag
              ButtonSegment(
                value: ImportPlanBackendSongSetAsAlbum,
                icon: const Icon(Icons.library_music),
                label: const Text("as Album"),
                enabled: toImport is! ImportPlanBackendSongSetAsTag,
              ), // album
            ],
            selected: {toImport.runtimeType},
            onSelectionChanged: (newTypeSet) {
              final newType = newTypeSet.first;
              switch (toImport) {
                case ImportPlanBackendSongSetAsAlbum album:
                  if (newType == ImportPlanBackendSongSetAsTag) {
                    setState(() {
                      toImport = ImportPlanBackendSongSetAsTag(
                        backendName: album.backendName,
                        tagName: album.newName,
                        songs: album.songs
                            .map(
                              (albumSong) => ImportPlanBackendSong(
                                backendId: albumSong.backendId,
                                backendName: albumSong.backendName,
                                preexistingSong: albumSong.preexistingSong,
                                newName: albumSong.newName,
                              ),
                            )
                            .toList(),
                      );
                    });
                  }
                case ImportPlanBackendSongSetAsTag tag:
                  if (newType == ImportPlanBackendSongSetAsAlbum) {
                    print("nope, can't do that");
                  }
              }
            },
          ),
          TextField(
            controller: nameControl,
            onChanged: (newName) => setState(() {
              toImport = toImport.withNewName(newName);
            }),
          ),
          ...widgets,
        ],
      ),
    );
  }
}
*/

final class LibraryImportFinalizePage extends StatelessWidget {
  const LibraryImportFinalizePage(this.session, {super.key});

  final ImportSession session;

  /*
  Widget _buildImportSetPlan(BuildContext context) {
    final importSet = plan.importSets[importSetIndex];

    String title;
    switch (importSet) {
      case ImportPlanBackendSongSetAsTag importAsTag:
        title = "Import '${importAsTag.backendName}' as tag '${importAsTag.tagName}'";
      case ImportPlanBackendSongSetAsAlbum importAsAlbum:
        if (importAsAlbum.preexistingAlbum == null) {
          title = "Import album '${importAsAlbum.backendName}'";
          if (importAsAlbum.newName != importAsAlbum.backendName) {
            title += " as '${importAsAlbum.newName}'";
          }
        } else {
          title = "Link '${importAsAlbum.backendName}' to album '${importAsAlbum.preexistingAlbum!.$2.name}'";
        }
      default:
        throw "Invalid ImportPlanBackendSongSet type $importSet";
    }
    return CustomExpansionTile(
      title: Text(title),
      // onTap: () async {
      //   final newSet = await Navigator.of(context).push(
      //     MaterialPageRoute<ImportPlanBackendSongSet>(
      //       builder: (BuildContext context) => LibraryImportFinalizeSet(toImport: importSet),
      //       fullscreenDialog: true,
      //     ),
      //   );
      //   if (newSet != null) {
      //     plan.importSets[importSetIndex] = newSet;
      //   }
      // },
      children: importSet.songs.map((song) {
        Widget? leading;
        String title;
        List<String> subtitleInfo = [];
        if (song.preexistingSong == null) {
          title = "Import '${song.backendName}'";
          if (song.newName != null && song.newName != song.backendName) {
            title += " as '${song.newName}'";
          }
        } else {
          title = "Link '${song.backendName}' to '${song.preexistingSong!.$2.name}'";
          if (song.newName != null && song.newName != song.preexistingSong!.$2.name) {
            title += " as '${song.newName}'";
          }
        }
        if (song is ImportPlanBackendSongLinkedToAlbum) {
          leading = Text(
            "${song.finalDiscNumber}:${song.finalTrackNumber}",
          );
          if (song.preexistingSongToPreexistingAlbum != null) {
            if ((song.finalDiscNumber, song.finalTrackNumber) != (song.preexistingSongToPreexistingAlbum!.disc, song.preexistingSongToPreexistingAlbum!.track)) {
              subtitleInfo.add("previously ${song.preexistingSongToPreexistingAlbum!.disc}:${song.preexistingSongToPreexistingAlbum!.track} in database");
            }
          }
          if ((song.finalDiscNumber, song.finalTrackNumber) != (song.backendDiscNumber, song.backendTrackNumber)) {
            subtitleInfo.add("held as ${song.backendDiscNumber}:${song.backendTrackNumber} in backend");
          }
        }

        return ListTile(
          leading: leading,
          title: Text(title),
          subtitle: Text(subtitleInfo.join(", ")),
        );
      }).toList(),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final actions = session.allActions.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("Importing ${session.songActions.length} songs"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: actions.length,
        itemBuilder: (context, idx) {
          final action = actions[idx];
          late String title;
          late IconData mainIcon;
          final notes = <(IconData, String)>[];
          switch (action) {
            case ImportTagAction tag:
              title = "Create/import tag '${tag.tagName}'";
              mainIcon = Icons.tag;
            case CreateNewArtist artist:
              final backendName = artist.importedData.name;
              final logicalName = artist.newName;
              if (backendName != logicalName) {
                title = "Create artist '$backendName' as '$logicalName'";
              } else {
                title = "Create artist '$backendName'";
              }
              mainIcon = Icons.person;
            case CreateNewAlbum album:
              final backendName = album.importedData.name;
              final logicalName = album.newName;
              if (backendName != logicalName) {
                title = "Create album '$backendName' as '$logicalName'";
              } else {
                title = "Create album '$backendName'";
              }
              for (final linkedArtist in album.linkedArtists) {
                final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                notes.add((Icons.person, "By '$artistName'"));
              }
              mainIcon = Icons.album;
            case CreateNewSong song:
              final backendName = song.importedData.name;
              final logicalName = song.newName;
              for (final linkedArtist in song.newLinkedArtists) {
                final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                notes.add((Icons.person, "By '$artistName'"));
              }
              if (song.newLinkedAlbum != null) {
                final (albumRef, disc, track) = song.newLinkedAlbum!;
                final albumName = session.resolveAlbumRefLogicalName(albumRef);
                notes.add((Icons.album, "Track $disc:$track of '$albumName'"));
              }
              if (song.linkToTag != null) {
                notes.add((Icons.tag, "Linked to #TODO"));
              }
              if (backendName != logicalName) {
                title = "Create song '$backendName' as '$logicalName'";
              } else {
                title = "Create song '$backendName'";
              }
              mainIcon = Icons.music_note;
            case ForcedLinkToExistingArtist artist:
              final backendName = artist.importedData.name;
              final logicalName = session.resolveArtistRefLogicalName(artist.existingArtist);
              if (backendName != logicalName) {
                title = "Link artist '$backendName' to '$logicalName'";
              } else {
                title = "Link artist '$backendName'";
              }
              mainIcon = Icons.person;
            case ForcedLinkToExistingAlbum album:
              final backendName = album.importedData.name;
              final logicalName = session.resolveAlbumRefLogicalName(album.existingAlbum);
              if (backendName != logicalName) {
                title = "Link album '$backendName' to '$logicalName'";
              } else {
                title = "Link album '$backendName'";
              }
              for (final linkedArtist in album.linkedArtists) {
                final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                notes.add((Icons.person, "By '$artistName'"));
              }
              mainIcon = Icons.album;
            case ForcedLinkToExistingSong song:
              final backendName = song.importedData.name;
              final logicalName = session.resolveSongRefLogicalName(song.existingSong);
              // TODO attach info about logical album and logical tag
              for (final linkedArtist in song.newLinkedArtists) {
                final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                notes.add((Icons.person, "Linked to Artist '$artistName'"));
              }
              if (song.newLinkedAlbum != null) {
                final (albumRef, disc, track) = song.newLinkedAlbum!;
                final albumName = session.resolveAlbumRefLogicalName(albumRef);
                notes.add((Icons.album, "Track $disc:$track of '$albumName'"));
              }
              if (song.linkToTag != null) {
                notes.add((Icons.tag, "Linked to #TODO"));
              }
              if (backendName != logicalName) {
                title = "Link song '$backendName' to '$logicalName'";
              } else {
                title = "Link song '$backendName'";
              }
              mainIcon = Icons.music_note;
            default:
              title = "Unknown Action";
              mainIcon = Icons.question_mark;
          }
          return CustomExpansionTile(
            leading: Icon(mainIcon),
            title: Text(title),
            trailing: Icon(Icons.edit_note),
            children: notes.map((data) {
              final (icon, text) = data;
              return ListTile(
                leading: Icon(icon),
                title: Text(text),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
