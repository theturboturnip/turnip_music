import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_music/library/importing.dart';
import 'package:turnip_music/library/library_plugin.dart';
import 'package:turnip_music/repos/plugin_repo.dart';
import 'package:turnip_music/util/empty_page.dart';

abstract class LibraryImportState extends Equatable {
  const LibraryImportState({required this.availablePlugins});

  final List<LibraryPlugin> availablePlugins;

  LibraryPlugin? get importer;
  List<BackendSetOfSongsToImport> get songSetsToImport;
}

class InitialLibraryImportState extends LibraryImportState {
  const InitialLibraryImportState({
    required super.availablePlugins,
  });

  @override
  LibraryPlugin? get importer => null;

  @override
  List<BackendSetOfSongsToImport> get songSetsToImport => [];

  @override
  List<Object?> get props => [availablePlugins];
}

class LibraryImportStateFromImporter extends LibraryImportState {
  final LibraryPlugin _importer;
  final List<BackendSetOfSongsToImport> _songSetsToImport;

  const LibraryImportStateFromImporter({
    required super.availablePlugins,
    required LibraryPlugin importer,
    required List<BackendSetOfSongsToImport> songSetsToImport,
  })  : _importer = importer,
        _songSetsToImport = songSetsToImport;

  @override
  LibraryPlugin? get importer => _importer;

  @override
  List<BackendSetOfSongsToImport> get songSetsToImport => _songSetsToImport;

  @override
  List<Object?> get props => [availablePlugins, _importer, _songSetsToImport];
}

class LibraryImportEvent {}

class LibrarySelectImporterEvent extends LibraryImportEvent {
  final LibraryPlugin importer;

  LibrarySelectImporterEvent({required this.importer});
}

class LibrarySelectSongsToImportEvent extends LibraryImportEvent {
  final List<BackendSetOfSongsToImport> songSetsToImport;

  LibrarySelectSongsToImportEvent({required this.songSetsToImport});
}

class LibraryImportBloc extends Bloc<LibraryImportEvent, LibraryImportState> {
  LibraryImportBloc(PluginRepo plugins) : super(InitialLibraryImportState(availablePlugins: plugins.libraryPlugins.toList())) {
    on<LibrarySelectImporterEvent>((event, emit) {
      if (state.importer != event.importer) {
        emit(LibraryImportStateFromImporter(
          availablePlugins: plugins.libraryPlugins.toList(),
          importer: event.importer,
          songSetsToImport: [],
        ));
      }
    });
    on<LibrarySelectSongsToImportEvent>((event, emit) {
      if (event.songSetsToImport.isEmpty) {
        if (state.importer != null) {
          emit(LibraryImportStateFromImporter(
            availablePlugins: plugins.libraryPlugins.toList(),
            importer: state.importer!,
            songSetsToImport: [],
          ));
        }
      } else if (event.songSetsToImport.any((songSet) => songSet.backendId == state.importer?.dataBackendId)) {
        emit(LibraryImportStateFromImporter(
          availablePlugins: plugins.libraryPlugins.toList(),
          importer: state.importer!,
          songSetsToImport: event.songSetsToImport,
        ));
      }
    });
  }
}

class LibraryImportPage extends StatelessWidget {
  const LibraryImportPage({super.key});

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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: BlocBuilder<LibraryImportBloc, LibraryImportState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildImporterSelector(context, state),
                  Expanded(child: state.importer?.buildSelectSongSetsToImportWidget(context) ?? EmptyPage()),
                  FilledButton(
                    onPressed: state.songSetsToImport.isEmpty
                        ? null
                        : () {
                            context.go("/library/import/finalize", extra: state.songSetsToImport);
                          },
                    child: const Text("Select Songs"),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
