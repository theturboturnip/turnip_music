import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_music/library/importing.dart';

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

abstract class ImportSessionEvent {}

class RenameUnderlyingItemEvent extends ImportSessionEvent {
  final String newName;
  final AlbumRef? asAlbumRef;
  final ArtistRef? asArtistRef;
  final TagRef? asTagRef;
  final SongRef? asSongRef;

  RenameUnderlyingItemEvent.album(this.newName, this.asAlbumRef)
      : asArtistRef = null,
        asTagRef = null,
        asSongRef = null;
  RenameUnderlyingItemEvent.artist(this.newName, this.asArtistRef)
      : asAlbumRef = null,
        asTagRef = null,
        asSongRef = null;
  RenameUnderlyingItemEvent.tag(this.newName, this.asTagRef)
      : asArtistRef = null,
        asAlbumRef = null,
        asSongRef = null;
  RenameUnderlyingItemEvent.song(this.newName, this.asSongRef)
      : asArtistRef = null,
        asTagRef = null,
        asAlbumRef = null;

  // RenameUnderlyingItemEvent(
  //   this.newName, {
  //   this.asAlbumRef,
  //   this.asArtistRef,
  //   this.asTagRef,
  //   this.asSongRef,
  // }) {
  //   int nNotEmpty = (asAlbumRef == null ? 0 : 1) + (asArtistRef == null ? 0 : 1) + (asTagRef == null ? 0 : 1) + (asSongRef == null ? 0 : 1);
  //   if (nNotEmpty != 1) {
  //     throw "Created RenameUnderlyingItemEvent with more than one parameter"
  //   }
  // }
}

class ImportSessionBloc extends Bloc<ImportSessionEvent, ImportSession> {
  ImportSessionBloc(super.initialState) {
    on<ImportSessionEvent>(
      (event, emit) async {
        switch (event) {
          case RenameUnderlyingItemEvent e:
            if (e.asAlbumRef != null) {
              emit(state.)
            }
          default:
            throw "Unknown event $event";
        }
      },
      transformer: sequential(),
    );
  }
}

abstract class EditDialog {
  void edit(BuildContext context, ImportSession session);
}

class RenameEditDialog extends EditDialog {
  final String backendName;
  final String normalName;

  RenameEditDialog({required this.backendName, required this.normalName});

  @override
  void edit(BuildContext context, ImportSession session) {
    showGeneralDialog(
        context: context,
        pageBuilder: (context, _, __) {
          return SimpleDialog(
            title: Text("Rename '$backendName'"),
            children: [
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: normalName,
                ),
              ),
              TextButton(onPressed: null, child: const Text("Rename")),
            ],
          );
        });
    // TODO: implement edit
  }
}

class ImportFinalizeActionWidget extends StatelessWidget {
  final ImportSession session;
  final IconData icon;
  final String text;
  final bool indented;
  final EditDialog? editAction;

  const ImportFinalizeActionWidget({
    super.key,
    required this.session,
    required this.icon,
    required this.text,
    required this.indented,
    required this.editAction,
  });
  const ImportFinalizeActionWidget.newTag(this.session, String tagName, {super.key})
      : icon = Icons.tag,
        text = "Create/import tag '$tagName'",
        indented = false,
        editAction = null;
  const ImportFinalizeActionWidget.importArtist(this.session, this.text, {super.key})
      : icon = Icons.person,
        indented = false,
        editAction = null;
  const ImportFinalizeActionWidget.linkOtherToArtist(this.session, String artistName, {super.key})
      : icon = Icons.person,
        text = "By '$artistName'",
        indented = true,
        editAction = null;
  const ImportFinalizeActionWidget.importAlbum(this.session, this.text, {super.key})
      : icon = Icons.album,
        indented = false,
        editAction = null;
  const ImportFinalizeActionWidget.linkSongToAlbum(this.session, String albumName, int disc, int track, {super.key})
      : icon = Icons.album,
        text = "Track $disc:$track of '$albumName'",
        indented = true,
        editAction = null;
  const ImportFinalizeActionWidget.linkSongToTag(this.session, {super.key})
      : icon = Icons.tag,
        text = "Linked to #TODO",
        indented = true,
        editAction = null;
  const ImportFinalizeActionWidget.importSong(this.session, this.text, {super.key})
      : icon = Icons.music_note,
        indented = false,
        editAction = null;

  @override
  Widget build(BuildContext context) {
    Widget leading = Icon(icon);
    if (indented) {
      leading = Padding(
        padding: EdgeInsets.only(left: 32.0),
        child: leading,
      );
    }
    return ListTile(
      leading: leading,
      title: Text(text),
      trailing: (editAction != null)
          ? IconButton(
              onPressed: () => editAction!.edit(context, session),
              icon: Icon(Icons.edit_note),
            )
          : null,
    );
  }
}

final class LibraryImportTweakSessionPage extends StatelessWidget {
  const LibraryImportTweakSessionPage(this.initialSession, {super.key});

  final ImportSession initialSession;

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
    return BlocProvider(
      create: (context) => ImportSessionBloc(initialSession),
      child: BlocBuilder<ImportSessionBloc, ImportSession>(
        builder: (context, session) {
          final actions = session.allActions.toList();
          final listItems = actions.map((action) {
            final widgets = <ImportFinalizeActionWidget>[];
            switch (action) {
              case ImportTagAction tag:
                widgets.add(ImportFinalizeActionWidget.newTag(
                  session,
                  tag.tagName,
                ));
              case CreateNewArtist artist:
                late String title;
                final backendName = artist.importedData.name;
                final logicalName = artist.newName;
                if (backendName != logicalName) {
                  title = "Create artist '$backendName' as '$logicalName'";
                } else {
                  title = "Create artist '$backendName'";
                }
                widgets.add(ImportFinalizeActionWidget.importArtist(
                  session,
                  title,
                ));
              case CreateNewAlbum album:
                late String title;
                final backendName = album.importedData.name;
                final logicalName = album.newName;
                if (backendName != logicalName) {
                  title = "Create album '$backendName' as '$logicalName'";
                } else {
                  title = "Create album '$backendName'";
                }
                widgets.add(ImportFinalizeActionWidget.importAlbum(
                  session,
                  title,
                ));
                for (final linkedArtist in album.linkedArtists) {
                  final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                  widgets.add(ImportFinalizeActionWidget.linkOtherToArtist(
                    session,
                    artistName,
                  ));
                }
              case CreateNewSong song:
                late String title;

                final backendName = song.importedData.name;
                final logicalName = song.newName;
                if (backendName != logicalName) {
                  title = "Create song '$backendName' as '$logicalName'";
                } else {
                  title = "Create song '$backendName'";
                }
                widgets.add(ImportFinalizeActionWidget.importSong(
                  session,
                  title,
                ));

                for (final linkedArtist in song.newLinkedArtists) {
                  final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                  widgets.add(ImportFinalizeActionWidget.linkOtherToArtist(
                    session,
                    artistName,
                  ));
                }
                if (song.newLinkedAlbum != null) {
                  final (albumRef, disc, track) = song.newLinkedAlbum!;
                  final albumName = session.resolveAlbumRefLogicalName(albumRef);
                  widgets.add(ImportFinalizeActionWidget.linkSongToAlbum(
                    session,
                    albumName,
                    disc,
                    track,
                  ));
                }
                if (song.linkToTag != null) {
                  widgets.add(ImportFinalizeActionWidget.linkSongToTag(session));
                }

              case ForcedLinkToExistingArtist artist:
                final backendName = artist.importedData.name;
                final logicalName = session.resolveArtistRefLogicalName(artist.existingArtist);
                late String title;
                if (backendName != logicalName) {
                  title = "Link artist '$backendName' to '$logicalName'";
                } else {
                  title = "Link artist '$backendName'";
                }
                widgets.add(ImportFinalizeActionWidget.importArtist(
                  session,
                  title,
                ));
              case ForcedLinkToExistingAlbum album:
                final backendName = album.importedData.name;
                final logicalName = session.resolveAlbumRefLogicalName(album.existingAlbum);
                late String title;
                if (backendName != logicalName) {
                  title = "Link album '$backendName' to '$logicalName'";
                } else {
                  title = "Link album '$backendName'";
                }
                widgets.add(ImportFinalizeActionWidget.importAlbum(
                  session,
                  title,
                ));
                for (final linkedArtist in album.linkedArtists) {
                  final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                  widgets.add(ImportFinalizeActionWidget.linkOtherToArtist(
                    session,
                    artistName,
                  ));
                }
              case ForcedLinkToExistingSong song:
                final backendName = song.importedData.name;
                final logicalName = session.resolveSongRefLogicalName(song.existingSong);
                late String title;
                if (backendName != logicalName) {
                  title = "Link song '$backendName' to '$logicalName'";
                } else {
                  title = "Link song '$backendName'";
                }
                widgets.add(ImportFinalizeActionWidget.importSong(
                  session,
                  title,
                ));
                for (final linkedArtist in song.newLinkedArtists) {
                  final artistName = session.resolveArtistRefLogicalName(linkedArtist);
                  widgets.add(ImportFinalizeActionWidget.linkOtherToArtist(
                    session,
                    artistName,
                  ));
                }
                if (song.newLinkedAlbum != null) {
                  final (albumRef, disc, track) = song.newLinkedAlbum!;
                  final albumName = session.resolveAlbumRefLogicalName(albumRef);
                  widgets.add(ImportFinalizeActionWidget.linkSongToAlbum(
                    session,
                    albumName,
                    disc,
                    track,
                  ));
                }
                if (song.linkToTag != null) {
                  widgets.add(ImportFinalizeActionWidget.linkSongToTag(session));
                }
              default:
                widgets.add(ImportFinalizeActionWidget(
                  session: session,
                  icon: Icons.question_mark,
                  text: "Unknown Action",
                  indented: false,
                  editAction: null,
                ));
            }
            return widgets;
          }).flattenedToList;

          return Scaffold(
            appBar: AppBar(
              title: Text("Importing ${session.songActions.length} songs"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: ListView.builder(
              itemCount: listItems.length,
              itemBuilder: (context, idx) {
                return listItems[idx];
              },
            ),
          );
        },
      ),
    );
  }
}
