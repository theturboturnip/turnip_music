import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/repos/db/db_repo.dart';
import 'package:turnip_music/repos/plugin_repo.dart';
import 'package:turnip_music/util/empty_page.dart';
import 'package:turnip_music/util/widgets.dart';

typedef ImportSessionGenerator = Future<ImportSession> Function(DbRepo);

typedef ViewMode = IconData;

abstract class PluginSuppliedImportable {
  final String dataBackendId;

  PluginSuppliedImportable({required this.dataBackendId});
}

class PluginSuppliedImportableAlbum extends PluginSuppliedImportable {
  final String unstableId;
  final String name;
  final String artists;
  final Object? data;

  PluginSuppliedImportableAlbum({
    required super.dataBackendId,
    required this.unstableId,
    required this.name,
    required this.artists,
    required this.data,
  });
}

abstract class PluginSuppliedLibrarySearchEvent {}

class UpdatePluginSuppliedLibrarySearchQuery extends PluginSuppliedLibrarySearchEvent {
  final String newFilter;

  UpdatePluginSuppliedLibrarySearchQuery({required this.newFilter});
}

abstract class PluginSuppliedLibrarySearchState {
  final bool loading;
  final List<PluginSuppliedImportableAlbum> albums;

  PluginSuppliedLibrarySearchState({required this.loading, required this.albums});

  Image? imageFor(PluginSuppliedImportable item);
}

abstract class PluginSuppliedLibrarySearchBloc<T extends PluginSuppliedLibrarySearchState> extends Bloc<PluginSuppliedLibrarySearchEvent, T> {
  PluginSuppliedLibrarySearchBloc(super.initialState);
}

class PluginSuppliedLibrarySearchView extends StatefulWidget {
  const PluginSuppliedLibrarySearchView({super.key, required this.plugin, required this.selected});

  final LibraryPlugin plugin;
  final (String, String)? selected;

  @override
  State<StatefulWidget> createState() => PluginSuppliedLibrarySearchViewState();
}

class PluginSuppliedLibrarySearchViewState extends State<PluginSuppliedLibrarySearchView> {
  late PluginSuppliedLibrarySearchBloc bloc;
  ViewMode viewMode = Icons.grid_view;
  (String, String)? selected;

  @override
  void initState() {
    super.initState();
    bloc = widget.plugin.makeSearchBloc();
  }

  @override
  void didUpdateWidget(covariant PluginSuppliedLibrarySearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plugin != widget.plugin) {
      setState(() {
        bloc = widget.plugin.makeSearchBloc();
      });
    }
    if (oldWidget.selected != widget.selected) {
      setState(() {
        selected = widget.selected;
      });
    }
  }

  Widget _makeGridView(PluginSuppliedLibrarySearchState state) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.66,
      ),
      itemCount: state.albums.length,
      itemBuilder: (context, index) {
        final album = state.albums[index];
        return /*Card(
          elevation: (album.id == selectedAlbumId) ? 5.0 : 1.0,
          child: */
            InkWell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AspectRatio(aspectRatio: 1, child: state.imageFor(album)),
                  if (album.dataBackendId == selected?.$1 && album.unstableId == selected?.$2)
                    Padding(
                      padding: padding(right: 4.0, bottom: 4.0),
                      child: Icon(
                        Icons.circle,
                        color: Colors.white,
                      ),
                    ),
                  if (album.dataBackendId == selected?.$1 && album.unstableId == selected?.$2)
                    Padding(
                      padding: padding(right: 4.0, bottom: 4.0),
                      child: Icon(
                        Icons.check_circle_rounded,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 4, right: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            album.artists,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            context.read<LibraryImportBloc>().add(LibrarySelectSongsToImportEvent(selected: album));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PluginSuppliedLibrarySearchBloc, PluginSuppliedLibrarySearchState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: padding(left: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      // onEditingComplete: (value) => bloc.add(UpdatePluginSuppliedLibrarySearchQuery(newFilter: value)),
                      onSubmitted: (value) => bloc.add(UpdatePluginSuppliedLibrarySearchQuery(newFilter: value)),
                      onChanged: (value) => bloc.add(UpdatePluginSuppliedLibrarySearchQuery(newFilter: value)),
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.search),
                        labelText: "Filter",
                        border: UnderlineInputBorder(),
                        hintText: 'Enter a search term',
                      ),
                    ),
                  ),
                  SegmentedButton(
                    segments: [
                      ButtonSegment(
                        value: Icons.grid_view,
                        icon: Icon(Icons.grid_view),
                      ),
                      ButtonSegment(
                        value: Icons.list_alt,
                        icon: Icon(Icons.list_alt),
                      ),
                    ],
                    selected: {viewMode},
                    multiSelectionEnabled: false,
                    emptySelectionAllowed: false,
                    onSelectionChanged: (selection) {
                      assert(selection.length == 1);
                      setState(() {
                        viewMode = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (state.loading) LinearProgressIndicator(value: null),
            if (state.albums.isEmpty) Expanded(child: EmptyPage()),
            if (state.albums.isNotEmpty && viewMode == Icons.grid_view) Expanded(child: _makeGridView(state)),
            // TODO list view
          ],
        );
      },
      bloc: bloc,
    );
  }
}

// class PluginSuppliedImportableArtist extends PluginSuppliedImportable {
//   final BackendArtist album;
//   final Image? art;

//   PluginSuppliedImportableAlbum({
//     required this.album,
//     required this.art,
//   });
// }

// class PluginSuppliedImportablePlaylist extends PluginSuppliedImportable {}

abstract class LibraryImportState {
  const LibraryImportState({
    required this.availablePlugins,
  });

  final List<LibraryPlugin> availablePlugins;

  LibraryPlugin? get importer;
  PluginSuppliedImportableAlbum? get selected;
}

class InitialLibraryImportState extends LibraryImportState {
  const InitialLibraryImportState({
    required super.availablePlugins,
  });

  @override
  LibraryPlugin? get importer => null;
  @override
  PluginSuppliedImportableAlbum? get selected => null;
}

class LibraryImportStateFromImporter extends LibraryImportState {
  @override
  final LibraryPlugin importer;
  @override
  final PluginSuppliedImportableAlbum? selected;

  const LibraryImportStateFromImporter({
    required super.availablePlugins,
    required this.importer,
    required this.selected,
  });
}

class LibraryImportEvent {}

class LibrarySelectImporterEvent extends LibraryImportEvent {
  final LibraryPlugin importer;

  LibrarySelectImporterEvent({required this.importer});
}

class LibrarySelectSongsToImportEvent extends LibraryImportEvent {
  final PluginSuppliedImportableAlbum? selected;

  LibrarySelectSongsToImportEvent({required this.selected});
}

class LibraryImportBloc extends Bloc<LibraryImportEvent, LibraryImportState> {
  LibraryImportBloc(PluginRepo plugins) : super(InitialLibraryImportState(availablePlugins: plugins.libraryPlugins.toList())) {
    on<LibrarySelectImporterEvent>((event, emit) {
      if (state.importer != event.importer) {
        emit(LibraryImportStateFromImporter(
          availablePlugins: plugins.libraryPlugins.toList(),
          importer: event.importer,
          selected: null,
        ));
      }
    });
    on<LibrarySelectSongsToImportEvent>((event, emit) {
      emit(LibraryImportStateFromImporter(
        availablePlugins: plugins.libraryPlugins.toList(),
        importer: state.importer!,
        selected: event.selected,
      ));
    });
  }
}

class LibraryImportBuildSessionPage extends StatelessWidget {
  const LibraryImportBuildSessionPage({super.key});

  Widget _buildImporterSelector(BuildContext context, LibraryImportState state) {
    // return ExpansionTile(
    //   leading: state.importer?.icon,
    //   title: Text(state.importer?.userVisibleName ?? "Select Importer"),
    //   initiallyExpanded: state.importer == null,
    //   children: state.availablePlugins.map(toElement),
    // );
    return DropdownMenu<LibraryPlugin>(
      leadingIcon: state.importer?.icon,
      initialSelection: null,
      label: const Text("Select Importer Plugin"),
      onSelected: (value) {
        if (value != null) {
          context.read<LibraryImportBloc>().add(
                LibrarySelectImporterEvent(
                  importer: value,
                ),
              );
        }
      },
      dropdownMenuEntries: state.availablePlugins
          .map(
            (plugin) => DropdownMenuEntry(
              value: plugin,
              label: plugin.userVisibleName,
              leadingIcon: plugin.icon,
            ),
          )
          .toList(),
      expandedInsets: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import from..."),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocProvider(
        create: (context) => LibraryImportBloc(context.read<PluginRepo>()),
        child: BlocBuilder<LibraryImportBloc, LibraryImportState>(
          builder: (context, state) {
            (String, String)? selected;
            if (state.selected != null) {
              selected = (state.selected!.dataBackendId, state.selected!.unstableId);
            }
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildImporterSelector(context, state),
                ),
                Expanded(
                    child: state.importer == null
                        ? EmptyPage()
                        : PluginSuppliedLibrarySearchView(
                            plugin: state.importer!,
                            selected: selected,
                          )),
                FilledButton(
                  onPressed: state.selected == null
                      ? null
                      : () async {
                          final session = ImportSession(db: context.read<DbRepo>());
                          final selectedImporter = state.availablePlugins.where((p) => p.dataBackendId == state.selected!.dataBackendId).first;
                          await selectedImporter.addImportablesToSession([state.selected!], session);
                          if (context.mounted) {
                            context.go("/library/import/finalize", extra: session);
                          }
                        },
                  child: const Text("Select Songs"),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
